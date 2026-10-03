# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A Neovim plugin that jumps between "matching" files — most commonly a source file and its test file. Matchers are configured in Lua and drive both navigation and (on confirmation) creation of a missing counterpart.

## Testing

Tests use [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)'s busted-style harness and expect plenary cloned as a sibling directory at `../plenary.nvim` (the `scripts/minimal_init.vim` runtimepath and CI both assume this):

```sh
git clone --depth 1 https://github.com/nvim-lua/plenary.nvim.git ../plenary.nvim
```

Run the full suite:

```sh
nvim --headless --noplugin -u scripts/minimal_init.vim \
  -c "PlenaryBustedDirectory tests/ { minimal_init = './scripts/minimal_init.vim' }"
```

Run a single spec file:

```sh
nvim --headless --noplugin -u scripts/minimal_init.vim \
  -c "PlenaryBustedFile tests/determine_target_file_spec.lua"
```

Tests exercise `_determine_target_file` (pure path logic) against fixtures in `testdata/`, so they don't touch buffers or windows. Adding a new matcher generally means adding a fixture directory under `testdata/` plus a spec case.

## Architecture

Everything lives in `lua/matching-file.lua`, split into three concerns:

- **`M.matchers`** — an ordered list. Each entry has a `from` Lua pattern matched against the *filename* (`:t`, not the full path) and a `strategy` function `(file, matcher) -> target_path`. First matching entry wins. Two strategies exist:
  - `goto_matching_file_in_same_directory` — simple `gsub` from `from` to `to` (e.g. `foo.ts` ↔ `foo.spec.ts`).
  - `goto_matching_file_in_project` — for cases where the counterpart lives in a *sibling project directory* (e.g. C# `Project/` ↔ `Project.Test/`). It walks up via `vim.fs.root` to find the dir containing a file matching `projectfilepattern` (e.g. `*.csproj`), then swaps a project-dir suffix (`projectsuffix1`/`projectsuffix2`, e.g. `.Test`/``) and a filename suffix (`suffix1`/`suffix2`, e.g. `Test.cs`/`.cs`), preserving the relative directory structure between them. The swap is bidirectional depending on which suffix the current project dir ends with.

- **`_determine_target_file(file)`** — pure function, no side effects, the unit under test. Returns the target path or `nil`.

- **`goto_matching_file()`** — the entry point users bind. Resolves the target, opens it in a vsplit (reusing an existing window if the file is already open, via `open_in_split`), and on a missing target prompts to create it.

`M.setup()` is currently a no-op. There is no default keymap (intentionally removed) — users bind `goto_matching_file` themselves.
