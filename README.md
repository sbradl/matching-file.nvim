# matching-file.nvim

[![Tests](https://github.com/sbradl/matching-file.nvim/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/sbradl/matching-file.nvim/actions/workflows/ci.yml)

This plugin lets you quickly go to a matching file. A matching file can be the corresponding test file.
Patterns to find a matching file are configurable.

If the matching file does not exist you will be asked if it should be created.

## Usage

### lazy.nvim

```lua
 {
    "sbradl/matching-file.nvim",
    config = function()
      require("matching-file").setup()
    end,
  },
```

## Configuration

`setup` accepts a `matchers` list that replaces the built-in one. Each matcher
has a `from` Lua pattern (matched against the filename, not the full path) and a
`strategy`. The first matching entry wins.

A strategy is either the name of a built-in one or your own function
`(file, matcher) -> target_path`.

```lua
require("matching-file").setup({
  matchers = {
    -- Swap between a file and its counterpart in the same directory.
    { from = "%.spec%.ts$", to = ".ts", strategy = "same_directory" },
    { from = "%.ts$", to = ".spec.ts", strategy = "same_directory" },

    -- Jump to a sibling project directory (e.g. C# Project/ <-> Project.Test/).
    {
      from = "%.cs$",
      strategy = "project",
      projectfilepattern = ".*%.csproj$",
      projectsuffix1 = ".Test",
      projectsuffix2 = "",
      suffix1 = "Test.cs",
      suffix2 = ".cs",
    },
  },
})
```

Built-in strategies:

- `"same_directory"` — replaces `from` with `to` via `gsub`.
- `"project"` — finds the project root (containing a file matching
  `projectfilepattern`), swaps the project-directory suffix
  (`projectsuffix1`/`projectsuffix2`) and the filename suffix
  (`suffix1`/`suffix2`), preserving the relative directory structure.
