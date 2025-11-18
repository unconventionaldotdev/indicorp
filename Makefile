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
	uv sync

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
	uv run indico/bin/maintenance/build-assets.py plugin --dev ../src

.PHONY: assets-plugin
assets-plugin: _check_plugin
	uv run indico/bin/maintenance/build-assets.py plugin --dev ../plugins/$(plugin)

# Assets in watch mode for development

.PHONY: assets-core-watch
assets-core-watch:
	uv run indico/bin/maintenance/build-assets.py indico --dev --watch

.PHONY: assets-distro-watch
assets-distro-watch:
	uv run indico/bin/maintenance/build-assets.py plugin --dev --watch ../src

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
	rm -rf src/indicorp/static/dist
	rm -rf indico/indico/web/static/dist
	rm src/url_map.json
	rm indico/url_map.json

.PHONY: clean-env
clean-env: clean-py clean-js

.PHONY: clean-all
clean-all: clean-env clean-assets

## -- monitoring ---------------------------------------------------------------

.PHONY: log-app
log-app: _check_indicoapp
	tail -f "$${INDICOAPP}/data/log/indico.log"

.PHONY: log-db
log-db:
	uv run python indico/bin/utils/db_log.py -S

## -- misc ---------------------------------------------------------------------

.PHONY: run
run:
	uv run indico run --quiet --enable-evalex

.PHONY: config
config:
	$${EDITOR:-vi} indico/indico/indico.conf

.PHONY: build
build:
	bin/build.sh

## -- util ---------------------------------------------------------------------

.PHONY: _check_indicoapp
_check_indicoapp:
ifndef INDICOAPP
	$(error INDICOAPP envvar is not set)
endif

.PHONY: _check_plugin
_check_plugin:
	@if [ -z "$(plugin)" ]; then (echo "error: plugin was undefined"; exit 1); fi
	@if [ ! -d "plugins/$(plugin)" ]; then (echo "error: plugin $(plugin) doesn't exist"; exit 1); fi
