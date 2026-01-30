# -- environment ---------------------------------------------------------------

#  Full setup of development environment

.PHONY: deps
deps: deps-py deps-js

.PHONY: deps-py
deps-py: deps-distro-py

.PHONY: deps-js
deps-js: deps-core-js deps-distro-js

# Setup of distribution-only environment

.PHONY: deps-distro
deps-distro: deps-distro-py deps-distro-js

.PHONY: deps-distro-py
deps-distro-py:
	uv sync --locked

.PHONY: deps-distro-js
deps-distro-js:
	npm ci

# Setup of core-only environment

.PHONY: deps-core
deps-core: deps-core-py deps-core-js

.PHONY: deps-core-py
deps-core-py:
	uv pip install --requirement indico/requirements.txt
	uv pip install --requirement indico/requirements.dev.txt
	uv pip install --editable indico

.PHONY: deps-core-js
deps-core-js:
	cd indico && npm ci

# Setup of plugin-specific environment

# These targets require the 'plugin' variable to be set, e.g.:
#    make deps-plugin plugin=indico-plugins/prometheus

.PHONY: deps-plugin
deps-plugin: _check_plugin deps-plugin-py deps-plugin-js

.PHONY: deps-plugin-py
deps-plugin-py: _check_plugin
	uv pip install --editable plugins/$(plugin)

.PHONY: deps-plugin-js
deps-plugin-js: _check_plugin
	cd plugins/$(plugin) && npm ci

# -- assets --------------------------------------------------------------------

.PHONY: assets
assets: assets-core assets-distro

.PHONY: assets-core
assets-core:
	uv run indico/bin/maintenance/build-assets.py indico --dev

.PHONY: assets-distro
assets-distro:
	uv run indico/bin/maintenance/build-assets.py plugin --dev ..

.PHONY: assets-plugin
assets-plugin: _check_plugin
	uv run indico/bin/maintenance/build-assets.py plugin --dev ../plugins/$(plugin)

# Assets in watch mode for development

.PHONY: assets-core-watch
assets-core-watch:
	uv run indico/bin/maintenance/build-assets.py indico --dev --watch

.PHONY: assets-distro-watch
assets-distro-watch:
	uv run indico/bin/maintenance/build-assets.py plugin --dev --watch ..

.PHONY: assets-plugin-watch
assets-plugin-watch:
	uv run indico/bin/maintenance/build-assets.py plugin --dev --watch ../plugins/$(plugin)

# -- cleaning ------------------------------------------------------------------

.PHONY: clean-py
clean-py:
	rm -rf .venv

.PHONY: clean-js
clean-js:
	rm -rf node_modules
	rm -rf indico/node_modules

.PHONY: clean-assets
clean-assets:
	rm -rf indicorp/static/dist
	rm -rf indico/indico/web/static/dist
	rm url_map.json
	rm indico/url_map.json

.PHONY: clean-env
clean-env: clean-py clean-js

.PHONY: clean-all
clean-all: clean-env clean-assets

## -- monitoring ---------------------------------------------------------------

.PHONY: log-app
log-app: _check_app_path
	tail -f "$${INDICO_APP_PATH}/data/log/indico.log"

.PHONY: log-db
log-db:
	uv run python indico/bin/utils/db_log.py -S

## -- checks -------------------------------------------------------------------

.PHONY: lint
lint: lint-py lint-js

.PHONY: lint-py
lint-py:
	@git -C indico diff --name-only --diff-filter=ACM HEAD | grep '\.py$$' | xargs -r uv run isort --check-only
	@cd indico && uv run python bin/maintenance/update_backrefs.py --ci
	@cd indico && uv run python bin/maintenance/generate_icons.py --ci
	@cd indico && uv run python bin/maintenance/update_moment_locales.py --ci
	@git -C indico diff --name-only --diff-filter=ACM HEAD | xargs -r uv run unbehead --check
	@git -C indico diff --name-only --diff-filter=ACM HEAD | grep '\.py$$' | xargs -r uv run ruff check --output-format=concise

.PHONY: lint-js
lint-js:
	@git -C indico diff --name-only --diff-filter=ACM HEAD | grep '\.\(js\|jsx\|ts\|tsx\)$$' | xargs -r npx @biomejs/biome ci --files-ignore-unknown=true
	@git -C indico diff --name-only --diff-filter=ACM HEAD | grep '\.\(js\|jsx\|ts\|tsx\)$$' | xargs -r npx eslint
	@cd indico && npx tsc --noEmit
	@git -C indico diff --name-only --diff-filter=ACM HEAD | grep '\.\(scss\|css\)$$' | xargs -r npx stylelint --formatter unix

.PHONY: fix
fix: fix-py fix-js

.PHONY: fix-py
fix-py:
	@git -C indico diff --name-only --diff-filter=ACM HEAD | grep '\.py$$' | xargs -r uv run isort
	@cd indico && uv run python bin/maintenance/update_backrefs.py
	@cd indico && uv run python bin/maintenance/generate_icons.py
	@cd indico && uv run python bin/maintenance/update_moment_locales.py
	@git -C indico diff --name-only --diff-filter=ACM HEAD | xargs -r uv run unbehead
	@git -C indico diff --name-only --diff-filter=ACM HEAD | grep '\.py$$' | xargs -r uv run ruff check --fix

.PHONY: fix-js
fix-js:
	@git -C indico diff --name-only --diff-filter=ACM HEAD | grep '\.\(js\|jsx\|ts\|tsx\)$$' | xargs -r npx @biomejs/biome check --write --files-ignore-unknown=true
	@git -C indico diff --name-only --diff-filter=ACM HEAD | grep '\.\(js\|jsx\|ts\|tsx\)$$' | xargs -r npx eslint --fix
	@git -C indico diff --name-only --diff-filter=ACM HEAD | grep '\.\(scss\|css\)$$' | xargs -r npx stylelint --fix

# -- builds --------------------------------------------------------------------

.PHONY: docker
docker:
	bin/build.sh

.PHONY: wheel
wheel:
	uv run indico/bin/maintenance/build-wheel.py plugin --no-git ..

## -- misc ---------------------------------------------------------------------

.PHONY: run
run:
	uv run indico run --quiet --enable-evalex

.PHONY: config
config:
	$${EDITOR:-vi} indico/indico/indico.conf


.PHONY: tmux
tmux:
	tmuxp load -d "./tmuxp.yaml" && tmux -CC attach -t "indicorp"

## -- utils --------------------------------------------------------------------

.PHONY: _check_app_path
_check_app_path:
ifndef INDICO_APP_PATH
	$(error INDICO_APP_PATH envvar is not set)
endif

.PHONY: _check_plugin
_check_plugin:
	@if [ -z "$(plugin)" ]; then (echo "error: plugin was undefined"; exit 1); fi
	@if [ ! -d "plugins/$(plugin)" ]; then (echo "error: plugin $(plugin) doesn't exist"; exit 1); fi
