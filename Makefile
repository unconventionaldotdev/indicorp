# -- environment ---------------------------------------------------------------

.PHONY: deps-core-py
deps-core-py:
	poetry run -- pip install --requirement indico/requirements.txt
	poetry run -- pip install --requirement indico/requirements.dev.txt
	poetry run -- pip install --editable indico

.PHONY: deps-core-js
deps-core-js:
	cd indico && npm ci

.PHONY: deps-distro-py
deps-distro-py:
	poetry install

.PHONY: deps-distro-js
deps-distro-js:
	npm ci

.PHONY: deps-plugin-py
deps-plugin-py: _check_plugin
	poetry run -- pip install --editable plugins/$(plugin)

.PHONY: deps-plugin-js
deps-plugin-js: _check_plugin
	cd plugins/$(plugin) && npm ci

.PHONY: deps-py
deps-py: deps-core-py deps-distro-py

.PHONY: deps-js
deps-js: deps-core-js deps-distro-js

.PHONY: deps-core
deps-core: deps-core-py deps-core-js

.PHONY: deps-distro
deps-distro: deps-distro-py deps-distro-js

.PHONY: deps-plugin
deps-plugin: _check_plugin deps-plugin-py deps-plugin-js

.PHONY: deps
deps: deps-py deps-js

# -- assets --------------------------------------------------------------------

.PHONY: assets-core
assets-core:
	poetry run -- indico/bin/maintenance/build-assets.py indico --dev

.PHONY: assets-distro
assets-distro:
	poetry run -- indico/bin/maintenance/build-assets.py plugin --dev ../src

.PHONY: assets-plugin
assets-plugin: _check_plugin
	poetry run -- indico/bin/maintenance/build-assets.py plugin --dev ../plugins/$(plugin)

.PHONY: assets-core-watch
assets-core-watch:
	poetry run -- indico/bin/maintenance/build-assets.py indico --dev --watch

.PHONY: assets-distro-watch
assets-distro-watch:
	poetry run -- indico/bin/maintenance/build-assets.py plugin --dev --watch ../src

.PHONY: assets-plugin-watch
assets-plugin-watch:
	poetry run -- indico/bin/maintenance/build-assets.py plugin --dev --watch ../plugins/$(plugin)

.PHONY: assets
assets: assets-core assets-distro

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
	poetry run -- python indico/bin/utils/db_log.py -S

## -- misc ---------------------------------------------------------------------

.PHONY: run
run:
	poetry run -- indico run --quiet --enable-evalex

.PHONY: config
config:
	$${EDITOR:-vi} indico/indico/indico.conf

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
