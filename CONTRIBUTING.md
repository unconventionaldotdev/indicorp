# Contributing

This guide covers best practices for contributing to this repository and the Indico submodule. Following these guidelines helps maintain code quality and a clean project history.

Read this CONTRIBUTING.md file to know more about:
- [Contributing to this repository](#contributing-to-this-repository)
- [Contributing to the Indico submodule](#contributing-to-the-indico-submodule)
- [Managing translations](#managing-translations)

## Contributing to this repository

All contributions must pass quality assurance checks before merging. These include automated code style checks, regression tests and manual code reviews to ensure alignment with project architecture and long-term maintainability.

### Code style checks

Code style is enforced automatically using linters configured in the repository. Run the style checks with:

```shell
make lint
```

Fix any issues before submitting your pull request.

### Regression tests

Run the test suite to verify your changes don't break existing functionality:

```shell
make test
```

Run tests for specific components:

```shell
make test-py
make test-js
```

### Commit messages

Write atomic and descriptive commit messages to maintain a clear project history.

#### Atomic commits

Group all related changes into a single commit. If you end up with multiple disjointed commits during development, squash them before merging using interactive rebase:

```shell
git rebase --interactive <target-branch>
```

Example rebase workflow:

Initial commits:
```
pick a4d29a59 Fix bug in foobar decorator
pick bc0cb59b Implement new feature
pick a7a4b258 WIP2
pick 95750e7d WIP3
pick d1330ee7 Suggestions from code review
```

Rebase instructions:
```
pick a4d29a59 Fix bug in foobar decorator
fixup a7a4b258 WIP2
fixup d1330ee7 Suggestions from code review
pick bc0cb59b Implement new feature
fixup 95750e7d WIP3
```

Result:
- `a4d29a59 Fix bug in foobar decorator`
- `bc0cb59b Implement new feature`

Keep separate commits when changes are logically distinct and meaningful on their own. This helps when using `git blame` to understand why code changed.

#### Descriptive commits

Write commit messages that explain *why* changes were made, not just *what* changed. Follow these guidelines:

1. Use imperative mood (`Fix bug` not `Fixed bug`)
2. Capitalize the subject line and don't end with a period
3. Limit subject line and body to 72 characters
4. Separate subject from body with a blank line
5. Use the body to explain reasons behind changes

Good examples:
```
Upgrade ruff and fix new errors
Fix import when no data provided
Implement user notification system
```

Bad examples:
```
Upgrade ruff and fix new errors
fixed import when no data provided.
implemented user notification system that allows users to receive notifications.
```

These guidelines are inspired by [Chris Beams' "How to Write a Git Commit Message"](https://chris.beams.io/posts/git-commit/).

### Pull requests

Target one of these branches for your pull requests:
- `master` - stable branch containing also hotfixes
- `devel` - normal development lifecycle
- `release` - last minute fixes before a release (optional)

#### Avoid merge commits

Never create merge commits in your feature branch. Instead of clicking `Update branch` in GitHub's pull request interface, select `Rebase branch`. Alternatively, rebase from the command line:

```shell
git fetch origin
git rebase origin/<target-branch>
git push --force-with-lease
```

Merge commits like `Merge branch 'devel' into <feature-branch>` create messy history and complicate future rebases.

## Contributing to the Indico submodule

The Indico repository lives as a Git submodule in the [`indico/`](./indico/) directory. Changes made here are immediately reflected in your local instance since Indico is installed from this directory.

The `indico` submodule points to the `devel` branch of the [Indico fork](https://github.com/unconventionaldotdev/indico). This branch tracks a stable Indico release (e.g., `v3.1.1`) plus additional commits backported from upstream or temporary patches. The goal is to maintain parity with the latest stable release while managing compatibility with this distribution.

New features and bug fixes are committed to the `master` branch of the [upstream Indico repository](https://github.com/indico/indico). We backport commits when we're behind the latest release or when needed fixes aren't yet released.

### Bumping the submodule

To update the `indico` submodule to a newer upstream version, rebase the `devel` branch onto the latest `upstream/master`. First, configure the `upstream` remote if not already done (one-time setup):

```shell
cd indico
git remote add upstream https://github.com/indico/indico.git
```

Fetch the latest upstream changes and rebase:

```shell
git fetch upstream
git switch devel
git rebase upstream/master
```

Resolve any conflicts that arise during the rebase. After successfully rebasing, force-push to update the fork:

```shell
git push --force-with-lease
```

Update the submodule pointer and dependencies in the main repository:

```shell
cd ..
git add indico
uv lock
git add uv.lock
git commit -m "Bump indico submodule to <version>"
git push
```

> [!WARNING]
> Review commits prefixed with `BACKPORTED` during the rebase. These may conflict with upstream changes or become unnecessary if the functionality was merged upstream.

### Backporting commits from upstream

To backport commits from the upstream Indico repository, first configure the `upstream` remote (one-time setup):

```shell
cd indico
git remote add upstream https://github.com/indico/indico.git
```

Fetch the latest changes and cherry-pick commits into our `devel` branch:

```shell
git fetch upstream
git switch devel
git cherry-pick <commit-reference>
```

If conflicts occur or compatibility changes are needed for our pinned version, prefix commit messages with `BACKPORTED`. This helps identify commits to drop when upgrading to newer Indico versions:

```
BACKPORTED <original-commit-message>
```

> [!NOTE]
> After cherry-picking, record the submodule changes as described in the previous section.

## Managing translations

The repository uses three translation domains: `messages.pot` (Python files), `messages-js.pot` (JavaScript) and `messages-react.pot` (React). Each locale has corresponding `.po` files that must stay current as strings are added or removed.

### Updating plugin translations

Update plugin translations with these steps:

1. Extract the latest strings from the codebase:

```shell
indico i18n extract plugin ..
```

2. Update `.po` files for all active locales:

```shell
indico i18n update plugin ..
```

3. Send `.po` files to translators for translation

4. Compile `.po` files into `.mo` and `.json` files (note: `messages-js.po` doesn't get compiled):

```shell
indico i18n compile plugin ..
```

The plugin currently supports `en_GB` and `fr_FR` locales. Initialize a new locale with:

```shell
indico i18n init plugin .. --locale es_ES
```

All commands accept an optional `--locale` flag to target specific locales:

```shell
indico i18n update plugin .. --locale fr_FR
```

Target specific resources with `--python`, `--react` or `--javascript`:

```shell
indico i18n compile plugin .. --locale fr_FR --python
```

### Updating Indico core translations

The Indico core team maintains their translation files. After pulling a new Indico version, update `.mo` files to run with the latest translations:

```shell
indico i18n compile indico
```

### Managing translations with Transifex

The plugin currently manages translations manually by sending `.po` files to translators. To use Transifex (supported by Indico core):

1. Install the Transifex client and create a `.tx/config` file in the root directory. Copy content from Indico core's `.tx/config`, adjusting paths based on the Transifex setup

2. Push `.po` files to Transifex:

```shell
indico i18n push plugin ..
```

3. Pull updated translations from Transifex:

```shell
indico i18n pull plugin ..
```

Both commands accept a locale parameter:

```shell
indico i18n pull plugin .. es_ES
```
