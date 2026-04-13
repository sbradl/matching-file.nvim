# matching-file.nvim

This plugin lets you quickly go to a matching file. A matching file can be the corresponding test file.
Patterns to find a matching file are configurable.

If the matching file does not exist you will be asked if it should be created.

## Usage

### lazy.nvim

```lua
 {
    dir = "sbradl/matching-file.nvim",
    config = function()
      require("matching-file").setup()
    end,
  },
```

