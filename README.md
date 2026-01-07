# Indicorp

An Indico distribution template.

An Indico distribution is an opinionated project structure with tooling for launching highly customized Indico setups in development environments. These setups include Indico itself, plugins and organization-specific customizations. This template showcases the setup of a fictional organization called Indicorp.

Read this README.md file to know more about:
- [Features](#features)
- [Setting the environment](#setting-the-environment)
- [Running an Indico instance](#running-an-indico-instance)
- [Updating the environment](#updating-the-environment)
- [Building the distribution](#building-the-distribution)
- [Troubleshooting](#troubleshooting)

## Features

Indico can be highly customized to fit the needs of different organizations. Achieving this often involves making contributions to the [Indico](https://github.com/indico/indico) open source project, enabling [Indico plugins](https://github.com/indico/indico-plugins) and even [patching Indico](https://github.com/unconventionaldotdev/indico-patcher) code at runtime. Launching and contributing to different open source projects requires a complex development environment that may not be trivial to setup. This template aims to standardize the setup of such environments and provides a number of utilities to make development easier.

This repository is optimized for the following use cases:
- Set up and run a local Indico instance.
- Make code contributions to Indico and plugin repositories.
- Develop organization-specific customizations as a "distribution plugin".

This repository contains editable code of:
- Indico as a Git submodule in [`indico/`](./indico/)
- A few Indico plugins as Git submodules in [`plugins/`](./plugins/)
- Customizations for this "distribution plugin" in [`src/indicorp/`](./src/indicorp/)

This repository includes other development tools such as:
- [`Makefile`](./Makefile) with scripts for common development tasks
- Linter and testing settings in line with the Indico code style (*coming soon*)
- CI workflows for testing and building the distribution (*coming soon*)
- Issue and pull request templates (*coming soon*)

> [!IMPORTANT]
> This repository is primarily intended for development purposes. For production environments, build the Indico distribution as a Python package and install it the same virtual environment as Indico.

## Setting the environment

This section is a step-by-step guide for setting up a development environment for this Indico distribution. For troubleshooting and more details about installing Indico and plugins refer to the official [development installation](https://docs.getindico.io/en/latest/installation/development/) and [plugin installation](https://docs.getindico.io/en/latest/installation/plugins/) guides.

This guide expects the following tools installed and available in your system PATH:
- [`git`](https://git-scm.com/) (available in most systems)
- [`make`](https://www.gnu.org/software/make/) (available in most systems)
- [`uv`](https://docs.astral.sh/uv/) ([installation guide](https://docs.astral.sh/uv/getting-started/installation/))
- [`nvm`](https://github.com/nvm-sh/nvm) ([installation guide](https://github.com/nvm-sh/nvm#installing-and-updating))

Additionally, you will need the following programs installed and running in your system:
- [PostgreSQL](https://www.postgresql.org/) (>=13) ([installation guide](https://www.postgresql.org/download/))
- [Redis](https://redis.io/) ([installation guide](https://redis.io/docs/install/install-redis/))

Optionally, for a better development experience, you can install the following tools:
- [`direnv`](https://direnv.net/) | [`tmux`](https://github.com/tmux/tmux/wiki) | [`tmuxp`](https://tmuxp.git-pull.com/)

### Clone the repository

Clone the repository and its submodules with:

```shell
git clone --recursive https://github.com/unconventionaldotdev/indicorp.git
cd indicorp
```

If you didn't clone the repository recursively, clone and initialize submodules at any time with:

```shell
git submodule update --init --progress
```

### Install Python and NodeJS versions

Make sure to have the right versions of `python` and `node` installed:

```sh
uv python install  # reads from .python-version
nvm install        # reads from .nvmrc
```

### Install Python and JavaScript dependencies

Install Indico, the distribution plugin and all Python and JavaScript dependencies with:

```shell
make deps
```

Additionally, for each plugin in the `plugins/` directory, install its dependencies with:

```shell
make deps-plugin plugin=<plugin-path>
```

### Configure the Indico instance

First, create the directory that Indico will use as its root path with:

```shell
export INDICO_APP_PATH=/usr/local/opt/indicorp  # Use this in the setup wizard
mkdir -p "${INDICO_APP_PATH}"
```

Launch the setup wizard to configure the Indico instance:

```shell
indico setup wizard --dev
```

The wizard will keep your settings in a `indico/indico/indico.conf` file. Plugins, however, need to be enabled manually in the `PLUGINS` entry of the configuration file. To enable the distribution plugin, make sure the following entry is present:

```python
PLUGINS = {'indicorp', ...}
```

> [!NOTE]
> You can quickly edit the `indico.conf` file with `make config`.

> [!IMPORTANT]
> You can configure your `INDICO_APP_PATH` variable in the [`.envrc`](.envrc) file to avoid having to set it every time you open a new terminal. For this to work you will need to install [`direnv`](https://direnv.net/) and allow it to load the `.envrc` file.

### Compile translation catalogs

Compile the translation catalogs for Indico, plugins and the distribution plugin with:

```shell
indico i18n compile indico
indico i18n compile all-plugins ../plugins
indico i18n compile plugin ../src
```

### Prepare the database

Make sure that the `postgres` server is running locally ([guide](https://www.postgresql.org/docs/current/server-start.html)) and then create a database template:

```shell
createdb indico_template
psql indico_template -c "CREATE EXTENSION unaccent; CREATE EXTENSION pg_trgm;"
```

Create the `indicorp` database by copying the `indico_template` database:

```shell
createdb indicorp -T indico_template
```

Once the `indicorp` database exists, prepare the database schemas required by Indico and all enabled plugins with:

```shell
indico db prepare
```

### Build the static assets

Indico uses [Webpack](https://webpack.js.org/) to compile static assets such as JavaScript and CSS files from `.jsx` or `.scss` files. Compile the static assets for Indico, plugins and the distribution plugin with:

```shell
make assets
```

Additionally, build the static assets for a each plugin in the `plugins/` directory with:

```shell
make assets-plugin plugin=<plugin-path>
```

> [!NOTE]
> The `make assets` command needs to be run every time you make changes to the sources of Indico, plugins or the distribution plugin. For convenience, you can run `make asset-*-watch` commands to automatically re-compile the static assets on changes.

## Running an Indico instance

Now that you have a development environment set up, you can launch an instance of Indico. In this section, you will find instructions for launching the web server, rebuilding the static assets on changes and monitoring the logs.

> [!NOTE]
> You can run all the commands in this section at the same time in different terminals with [`tmux`](https://github.com/tmux/tmux/wiki), [`tmuxp`](https://tmuxp.git-pull.com/) and the [`tmuxp.yaml`](./tmuxp.yaml) file included in this repository.

### Launch Indico

Running Indico in development mode launches a web server that serves the application and handles all the requests from the users. Run the following command to launch the web server in debug mode and restarting on code changes:

```shell
make run
```

### Rebuild the static assets on changes

While developing you will often need to make changes in JavaScript and SCSS files and see the results in the browser. To re-compile the static assets on code changes, keep two terminals open with:

```shell
make assets-core-watch
```

```shell
make assets-distro-watch
```

### Monitor the logs

Indico prints the application logs to an `indico.log` file within the `INDICO_APP_PATH` directory. These logs are useful to gain context about application errors or behavior while debugging. Keep a terminal open to monitor the logs with:

```shell
export INDICO_APP_PATH=/usr/local/opt/indicorp  # As set in the setup wizard
make log-app
```

Indico also logs the database queries in real-time. These SQL logs are useful to debug performance issues and trace them to SQLAlchemy queries. Keep this real-time log open in another terminal with:

```shell
make log-db
```

### Set up an SMTP server

Indico expects to have access to a SMTP server for sending emails. One convenient option is installing and running a fake server such as [Maildump](https://pypi.org/project/maildump/). This will allow you to intercept and read all outgoing emails while also preventing them from being sent to real users accidentally.

You can install and run the program with:

```shell
uvx maildump
```

## Updating the environment

Update your local development environment to keep up with the changes introduced in Indico core, plugins and the distribution itself. This typically involve updating the submodules, installing new dependencies or upgrading the database schema.

### Update the Git submodules

Update your submodules whenever any submodule pointer has changed. Do this in one command for all submodules with:

```shell
git fetch --recurse-submodules
git submodule update
```

### Install new dependencies

Install all missing Python and Javascript dependencies introduced.

```shell
make deps
```

> [!NOTE]
> Inspect the [`Makefile`](./Makefile) to find more granular dependency targets. You can run `make deps-core` and `make deps-distro`, for instance, to install dependencies for Indico core and the distribution plugin respectively.

### Upgrade the database schema

Run all the Alembic migration scripts for database schema migrations introduced in the distribution itself or any of the submodules with:

```shell
indico db upgrade
indico db --all-plugins upgrade
```

## Building the distribution

The main output of this repository is a Docker image. This image will contain not only the distribution plugin code but also Indico and all plugins code from the submodules, built as wheels and installed in the image. Additionally, configuration files are copied to the image to make it ready to run. Build the Docker image with:

```shell
make build
```

## Troubleshooting

Things don't always go the expected way. This section contains solutions to some common issues that may arise while setting up the development environment.

### WeasyPrint installation issues on Apple Silicon Macs

The Python interpreters installed via `uv` on Apple Silicon Macs does not find libraries installed via Homebrew in `/opt/homebrew/lib` by default. This causes WeasyPrint to fail at import time. To fix this, create symbolic links to the required libraries in `/usr/local/lib` with the following commands:

```sh
sudo ln -s /opt/homebrew/opt/glib/lib/libgobject-2.0.0.dylib /usr/local/lib/gobject-2.0
sudo ln -s /opt/homebrew/opt/pango/lib/libpango-1.0.dylib /usr/local/lib/pango-1.0
sudo ln -s /opt/homebrew/opt/harfbuzz/lib/libharfbuzz.dylib /usr/local/lib/harfbuzz
sudo ln -s /opt/homebrew/opt/fontconfig/lib/libfontconfig.1.dylib /usr/local/lib/fontconfig-1
sudo ln -s /opt/homebrew/opt/pango/lib/libpangoft2-1.0.dylib /usr/local/lib/pangoft2-1.0
```

References:
- https://github.com/astral-sh/uv/issues/7870
- https://github.com/astral-sh/uv/issues/7764
- https://github.com/astral-sh/uv/issues/6971
- https://github.com/Kozea/WeasyPrint/issues/1448#issuecomment-925549118
