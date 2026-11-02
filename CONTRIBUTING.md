# Contributing

Setup and routine for working on BuyEmAll Continued. Current work is tracked on GitHub: the description of the open [milestone](https://github.com/Tharavol/BuyEmAllContinued/milestones) gives the order, and each issue holds its own details.

## Setup

- **LuaJIT** runs the tests. It matches the client's Lua 5.1 behavior, and the tests refuse to run under a newer Lua.
- **luacheck** lints the code.
- Commits are attributed to the project handle, set per clone:

```
git config user.name Tharavol
git config user.email 307232816+Tharavol@users.noreply.github.com
```

On Windows, `core.autocrlf` is `true`, so working-tree files use CRLF. Keep them that way after editing.

## Checks

Run both from the repository root. CI runs the same two, plus a packager dry run, on every push and pull request.

```
luacheck .
luajit tests/run_tests.lua
```

`tests/testkit.lua` is the stand-in client and `tests/run_tests.lua` holds the cases. To run the cases against another copy of the addon, pass its folder: `luajit tests/run_tests.lua path/to/copy`.

A `NOTE` line in the output records behavior that is known but not yet settled, and doesn't fail the run. Each one belongs to an open issue, and becomes a check once that issue is fixed.

To confirm a new check can fail, export the addon to a temporary folder with `git archive HEAD BuyEmAll.lua init.lua localisation`, break the line it covers, and run the cases against that folder.

## Checking in the game

The tests can't show on-screen layout, or what the client and server really do. Changes that touch either also get an in-game check before they're committed:

1. Copy the changed files to `World of Warcraft/_retail_/Interface/AddOns/BuyEmAll`. Leave the installed TOC alone, since the repository's has an unfilled version placeholder.
2. Run `/reload`.
3. Note in the commit message what was checked in the game and what wasn't.

Some paths have only been checked with the stand-in APIs. The list is under "Known gaps" in [CHANGELOG.md](CHANGELOG.md).

- **Non-English clients and profession bags** aren't available for testing, and aren't planned to be. These paths stay on the known-gaps list.
- **Vendor items:** [#26](https://github.com/Tharavol/BuyEmAllContinued/issues/26), [#27](https://github.com/Tharavol/BuyEmAllContinued/issues/27) and [#29](https://github.com/Tharavol/BuyEmAllContinued/issues/29) wait on a suitable item. Each issue says what to look for, and they can move to a later milestone if none turns up. An item priced in exactly two alternate currencies, or a currency item sold in bundles, would also close gaps from 4.1.6.

## Commits and issues

- Work one issue at a time, and end the commit message with `Fixes #N`.
- For several issues in one commit, repeat the keyword: `Fixes #1, Fixes #2`. The form `Fixes #1, #2` closes only the first.
- Add user-facing changes to `[Unreleased]` in [CHANGELOG.md](CHANGELOG.md), linking the issue.
- Check that nothing public carries a real name, a personal email or a local path such as `C:\Users\<account>`.

## Releasing

1. In [CHANGELOG.md](CHANGELOG.md), rename `[Unreleased]` to the version and date, and list anything not checked in the game under "Known gaps".
2. Commit as `Release x.y.z`, then push a `vx.y.z` tag. `release.yml` builds and publishes the zip with the BigWigs packager.
3. When the workflow is green, close the issues that shipped and the milestone. Milestones don't close on their own.
