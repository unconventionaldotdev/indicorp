.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "                           ⛧ INDICO DISTRO SPELLS ⛧"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "⟐ Runtime:"
	@echo "  make run                 - Start Indico in dev mode"
	@echo "  make tmux                - Launch the tmux session"
	@echo "  make config              - Edit indico.conf"
	@echo ""
	@echo "⟐ Environment:"
	@echo "  make deps                - Install all dependencies (Python + JS)"
	@echo "  make deps-core           - Install core-only dependencies"
	@echo "  make deps-distro         - Install distribution-only dependencies"
	@echo "  make deps-plugin         - Install plugin dependencies (plugin=<path>)"
	@echo ""
	@echo "⟐ Assets:"
	@echo "  make assets              - Build all assets"
	@echo "  make assets-core         - Build core assets"
	@echo "  make assets-distro       - Build distro assets"
	@echo "  make assets-plugin       - Build plugin assets (plugin=<path>)"
	@echo "  make assets-core-watch   - Watch core assets in dev mode"
	@echo "  make assets-distro-watch - Watch distro assets in dev mode"
	@echo "  make assets-plugin-watch - Watch plugin assets in dev mode"
	@echo ""
	@echo "⟐ Cleaning:"
	@echo "  make clean               - Remove envs and built assets"
	@echo "  make clean-env           - Remove virtualenv and node_modules"
	@echo "  make clean-assets        - Remove built assets"
	@echo ""
	@echo "⟐ Checks:"
	@echo "  make lint                - Run all linters"
	@echo "  make lint-py             - Lint Python code"
	@echo "  make lint-js             - Lint JavaScript/TypeScript"
	@echo "  make lint-headers        - Check file headers"
	@echo ""
	@echo "⟐ Tests:"
	@echo "  make test                - Run all tests"
	@echo "  make test-py             - Run Python tests"
	@echo "  make test-js             - Run JavaScript tests"
	@echo ""
	@echo "⟐ Builds:"
	@echo "  make docker              - Build Docker image"
	@echo "  make wheels              - Build all wheels"
	@echo "  make wheel-plugin        - Build plugin wheel (plugin=<path>)"
	@echo ""
	@echo "⟐ Debugging:"
	@echo "  make log-app             - Tail application log (INDICO_APP_PATH required)"
	@echo "  make log-db              - Tail DB log"
	@echo ""
	@echo "Note: set plugin=<path> for plugin targets (e.g., plugin=indico-plugins/prometheus)."

## -- runtime ------------------------------------------------------------------

.PHONY: run
run:
	uv run indico run --quiet --enable-evalex

.PHONY: tmux
tmux:
	tmuxp load -d "./tmuxp.yaml" && tmux -CC attach -t "indicorp"

.PHONY: config
config:
	$${EDITOR:-vi} indico/indico/indico.conf

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

.PHONY: clean
clean: clean-env clean-assets

.PHONY: clean-env
clean-env: clean-py clean-js

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

## -- checks -------------------------------------------------------------------

.PHONY: lint
lint: lint-py lint-js lint-headers

.PHONY: lint-py
lint-py:
	uv run ruff check --output-format=concise .

.PHONY: lint-py-ci
lint-py-ci:
	uv run ruff check --output-format=github .

.PHONY: lint-js
lint-js:
	@echo "No JS linter defined yet"

.PHONY: lint-headers
lint-headers:
	uv run unbehead --check

## -- tests --------------------------------------------------------------------

.PHONY: test
test: test-py test-js

.PHONY: test-py
test-py:
	uv run pytest

.PHONY: test-js
test-js:
	@echo "No JS tests defined yet"

# -- builds --------------------------------------------------------------------

.PHONY: docker
docker:
	bin/build.sh

.PHONY: wheels
wheels: wheel-core wheel-distro

.PHONY: wheel-distro
wheel-distro:
	uv run indico/bin/maintenance/build-wheel.py plugin --no-git ..

.PHONY: wheel-core
wheel-core:
	uv run indico/bin/maintenance/build-wheel.py indico --no-git

.PHONY: wheel-plugin
wheel-plugin: _check_plugin
	uv run indico/bin/maintenance/build-wheel.py plugin --no-git ../plugins/$(plugin)

## -- debugging ----------------------------------------------------------------

.PHONY: log-app
log-app: _check_app_path
	tail -f "$${INDICO_APP_PATH}/data/log/indico.log"

.PHONY: log-db
log-db:
	uv run python indico/bin/utils/db_log.py -S

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
