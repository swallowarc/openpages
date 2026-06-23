# openpages ― GitHub Pages 用のトップページ生成
#
# 各サブフォルダの index.html を集めて、ルートの index.html（リンク一覧）を生成する。
# 構成を変えたら `make` を実行すれば最新化される。

.DEFAULT_GOAL := index

# ルートの index.html を常に再生成する。
# 生成物（index.html）の mtime に依存すると、手動編集や git 操作で
# タイムスタンプが新しくなった際に make が「最新」と誤判定して再生成しない。
# それを避けるため PHONY ターゲットで毎回スクリプトを走らせる。
.PHONY: index
index: ## ルートの index.html を生成（既定ターゲット・常に再生成）
	@bash scripts/gen-index.sh

.PHONY: clean
clean: ## 生成した index.html を削除
	@rm -f index.html && echo "removed index.html"

.PHONY: help
help: ## ターゲット一覧を表示
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'
