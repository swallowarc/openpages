# openpages ― GitHub Pages 用のトップページ生成
#
# 各サブフォルダの index.html を集めて、ルートの index.html（リンク一覧）を生成する。
# 構成を変えたら `make` を実行すれば最新化される。

.DEFAULT_GOAL := index

# サブフォルダの全 index.html（ルート自身は除く）が更新されたら作り直す
SOURCES := $(filter-out ./index.html,$(shell find . -name index.html -not -path './.git/*'))

.PHONY: index
index: index.html ## ルートの index.html を生成（既定ターゲット）

index.html: scripts/gen-index.sh $(SOURCES)
	@bash scripts/gen-index.sh

.PHONY: clean
clean: ## 生成した index.html を削除
	@rm -f index.html && echo "removed index.html"

.PHONY: help
help: ## ターゲット一覧を表示
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'
