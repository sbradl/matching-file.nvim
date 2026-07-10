---@meta

---A strategy resolves the target ("matching") path for a given file.
---Return `nil` when no target can be determined.
---@alias matching-file.Strategy fun(file: string, matcher: matching-file.Matcher): string?

---A single matching rule. The first matcher whose `from` pattern matches the
---filename (`:t`, not the full path) wins.
---@class matching-file.Matcher
---@field name string Name used to enable/disable the matcher via `setup`. Several matchers may share a name to be toggled together.
---@field from string Lua pattern matched against the filename.
---@field strategy matching-file.Strategy|"same_directory"|"project" Strategy function, or the name of a built-in one in `M.strategies`.
---
--- Fields for the `same_directory` strategy:
---@field to? string Replacement applied to `from` via `gsub` (e.g. `foo.ts` -> `foo.spec.ts`).
---
--- Fields for the `project` strategy:
---@field projectfilepattern? string Lua pattern identifying the project-root marker file (e.g. `".*%.csproj$"`).
---@field projectsuffix1? string One project-directory suffix (e.g. `".Test"`).
---@field projectsuffix2? string The counterpart project-directory suffix (e.g. `""`).
---@field suffix1? string Filename suffix paired with `projectsuffix1` (e.g. `"Test.cs"`).
---@field suffix2? string Filename suffix paired with `projectsuffix2` (e.g. `".cs"`).

---Options accepted by `require("matching-file").setup`.
---@class matching-file.Opts
---@field matchers? matching-file.Matcher[] Added to the built-in matcher list when provided.
---@field disable? string[] Names of matchers to disable. All matchers are enabled by default.