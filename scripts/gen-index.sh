#!/usr/bin/env bash
#
# ルート直下の index.html を機械的に生成する。
# 各サブフォルダの index.html を探し、その <title> を抜き出してリンク一覧にする。
# 構成（フォルダやページ）が変わっても、make index を再実行すれば最新化される。
#
set -euo pipefail

# リポジトリのルートへ移動（このスクリプトは scripts/ 配下に置く想定）
cd "$(dirname "$0")/.."

OUT="index.html"
TITLE="openpages ― AI生成まとめ集"

# <title> を抜き出す。無ければパスをそのまま使う。
title_of() {
  local t
  t="$(grep -o -i '<title>[^<]*</title>' "$1" | head -1 | sed -E 's|</?[Tt][Ii][Tt][Ll][Ee]>||g')"
  if [ -z "$t" ]; then
    t="$1"
  fi
  printf '%s' "$t"
}

# トップレベルのフォルダ名に対する表示ラベル。未定義のものはフォルダ名そのまま。
section_label() {
  case "$1" in
    books)  echo "📚 書籍の要点まとめ" ;;
    devops) echo "🔧 DevOps 資料" ;;
    *)      echo "$1" ;;
  esac
}

# HTML特殊文字をエスケープ
esc() {
  sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}

# 対象の index.html を収集する。
#   - ルート直下の index.html（生成物そのもの）は除外
#   - 階層の浅い順 → パスの辞書順 に並べる（セクションの index を先頭に）
collect() {
  # キー: トップレベル名 → 階層の浅い順 → パス辞書順。
  # トップレベルを第一キーにすることで、同じセクションが必ず連続する。
  find . -name index.html -not -path './.git/*' -not -path './index.html' \
    | sed 's|^\./||' \
    | awk -F/ '{print $1" "NF" "$0}' \
    | sort -k1,1 -k2,2n -k3 \
    | cut -d' ' -f3-
}

# --- ヘッダ ---
{
cat <<HTML
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>$(printf '%s' "$TITLE" | esc)</title>
<style>
  :root { --fg:#222; --muted:#667; --line:#e2e2e2; --accent:#2d6cdf; --bg:#fafafa; --card:#fff; }
  * { box-sizing: border-box; }
  body {
    font-family: Arial, "Hiragino Sans", "Yu Gothic", Meiryo, sans-serif;
    margin: 0; padding: 40px 20px; line-height: 1.6;
    color: var(--fg); background: var(--bg);
  }
  .wrap { max-width: 880px; margin: 0 auto; }
  header h1 { margin: 0 0 4px; font-size: 1.7rem; }
  header p.lead { margin: 0 0 8px; color: var(--muted); }
  .note {
    background: #fff8e1; border: 1px solid #f0d98a; border-left: 5px solid #e0a800;
    border-radius: 6px; padding: 10px 14px; margin: 16px 0 28px;
    font-size: 0.9rem; color: #5a4b00;
  }
  section { margin: 28px 0; }
  section > h2 {
    font-size: 1.15rem; margin: 0 0 12px; padding-bottom: 6px;
    border-bottom: 2px solid var(--line);
  }
  ul.links { list-style: none; margin: 0; padding: 0; }
  ul.links li { margin: 0 0 10px; }
  a.card {
    display: block; text-decoration: none; color: inherit;
    background: var(--card); border: 1px solid var(--line); border-radius: 8px;
    padding: 12px 16px; transition: border-color .15s, box-shadow .15s;
  }
  a.card:hover { border-color: var(--accent); box-shadow: 0 2px 8px rgba(45,108,223,.12); }
  a.card .name { font-weight: 600; color: var(--accent); }
  a.card .path { display: block; font-size: 0.8rem; color: var(--muted); margin-top: 2px; }
  footer { margin-top: 40px; padding-top: 16px; border-top: 1px solid var(--line);
    font-size: 0.8rem; color: var(--muted); }
  code { background: #eee; padding: 1px 5px; border-radius: 4px; font-size: 0.85em; }
</style>
</head>
<body>
<div class="wrap">
<header>
  <h1>$(printf '%s' "$TITLE" | esc)</h1>
  <p class="lead">各まとめページへのリンク一覧</p>
</header>
<div class="note">
  ⚠️ このサイトのページは AI によって生成された要約・まとめです。原典と内容が一致しない可能性があります。参考用途に留めてください。
</div>
HTML
} > "$OUT"

# --- 本文（セクションごとにループ） ---
current=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  top="${f%%/*}"

  # セクションが切り替わったら見出しを出す
  if [ "$top" != "$current" ]; then
    if [ -n "$current" ]; then
      printf '</ul>\n</section>\n' >> "$OUT"
    fi
    current="$top"
    label="$(section_label "$top" | esc)"
    printf '<section>\n<h2>%s</h2>\n<ul class="links">\n' "$label" >> "$OUT"
  fi

  name="$(title_of "$f" | esc)"
  href="$(printf '%s' "$f" | esc)"
  printf '<li><a class="card" href="%s"><span class="name">%s</span><span class="path">%s</span></a></li>\n' \
    "$href" "$name" "$href" >> "$OUT"
done < <(collect)

# 最後のセクションを閉じる
if [ -n "$current" ]; then
  printf '</ul>\n</section>\n' >> "$OUT"
fi

# --- フッタ ---
cat <<HTML >> "$OUT"
<footer>
  この index.html は <code>make index</code> により自動生成されています。直接編集しないでください。
</footer>
</div>
</body>
</html>
HTML

echo "generated: $OUT ($(grep -c 'class="card"' "$OUT") links)"
