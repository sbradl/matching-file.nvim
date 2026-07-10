local M = {}

local function open_in_split(target)
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		local name = vim.api.nvim_buf_get_name(buf)
		if name == target then
			vim.api.nvim_set_current_win(win)
			return
		end
	end

	vim.cmd("vsplit " .. target)
end

local function create_matching_file(file)
	open_in_split(file)
	vim.cmd("write")
end

---@type table<string, matching-file.Strategy>
M.strategies = {}

---@type matching-file.Strategy
function M.strategies.same_directory(file, matcher)
	return (file:gsub(matcher.from, matcher.to))
end

local function ends_with(string, suffix)
	return string:sub(-#suffix) == suffix
end

---@type matching-file.Strategy
function M.strategies.project(file, matcher)
	local projectdir = vim.fs.root(file, function(name)
		return name:match(matcher.projectfilepattern)
	end)

	if not projectdir then
		return
	end

	local directorystructure = vim.fs.relpath(projectdir, file)
	local projectsuffix = ""
	local newprojectsuffix = ""
	local filesuffix = ""
	local newfilesuffix = ""

	if ends_with(projectdir, matcher.projectsuffix1) then
		projectsuffix = matcher.projectsuffix1
		newprojectsuffix = matcher.projectsuffix2
		filesuffix = matcher.suffix1
		newfilesuffix = matcher.suffix2
	else
		projectsuffix = matcher.projectsuffix2
		newprojectsuffix = matcher.projectsuffix1
		filesuffix = matcher.suffix2
		newfilesuffix = matcher.suffix1
	end

	local matchingprojectdir = projectdir:sub(1, #projectdir - #projectsuffix) .. newprojectsuffix
	local targetfile = vim.fs.joinpath(matchingprojectdir, directorystructure)

	return targetfile:sub(1, #targetfile - #filesuffix) .. newfilesuffix
end

---@type matching-file.Matcher[]
local default_matchers = {
	{ name = "typescript", from = "%.spec%.ts$", to = ".ts", strategy = "same_directory" },
	{ name = "typescript", from = "%.ts$", to = ".spec.ts", strategy = "same_directory" },
	{
		name = "csharp",
		from = "%.cs$",
		strategy = "project",
		projectfilepattern = ".*%.csproj$",
		projectsuffix1 = ".Test",
		projectsuffix2 = "",
		suffix1 = "Test.cs",
		suffix2 = ".cs",
	},
}

---@type matching-file.Matcher[]
M.matchers = default_matchers

---Resolve a matcher's strategy, which may be a named built-in or a function.
---@param strategy matching-file.Strategy|string
---@return matching-file.Strategy?
local function resolve_strategy(strategy)
	if type(strategy) == "string" then
		return M.strategies[strategy]
	end

	return strategy
end

M._determine_target_file = function(file)
	local filename = vim.fn.fnamemodify(file, ":t")
	local target

	for _, matcher in ipairs(M.matchers) do
		if filename:match(matcher.from) then
			local strategy = resolve_strategy(matcher.strategy)

			if strategy then
				target = strategy(file, matcher)
			end

			break
		end
	end

	return target
end

---Resolve the user-supplied opts against the built-in defaults into the final,
---effective opts. Pure: does not mutate globals or its input. User `matchers`
---are appended to the built-ins; matchers whose `name` is listed in `disable`
---are removed.
---@param opts? matching-file.Opts
---@return matching-file.Opts
M._resolve_opts = function(opts)
	opts = opts or {}

	local matchers = vim.list_extend({}, default_matchers)

	if opts.matchers then
		vim.list_extend(matchers, opts.matchers)
	end

	if opts.disable then
		local known = {}
		for _, matcher in ipairs(matchers) do
			known[matcher.name] = true
		end

		local disabled = {}
		for _, name in ipairs(opts.disable) do
			if not known[name] then
				error(string.format("matching-file: cannot disable unknown matcher %q", name), 0)
			end

			disabled[name] = true
		end

		matchers = vim.tbl_filter(function(matcher)
			return not disabled[matcher.name]
		end, matchers)
	end

	return { matchers = matchers }
end

---Configure the plugin. All matchers are enabled by default; pass `matchers` to
---add to the built-in list, or `disable` with matcher names to turn off.
---@param opts? matching-file.Opts
M.setup = function(opts)
	M.matchers = M._resolve_opts(opts).matchers
end

M.goto_matching_file = function()
	local file = vim.api.nvim_buf_get_name(0)
	local target = M._determine_target_file(file)

	if not target then
		print("No matcher found")
		return
	end

	if vim.fn.filereadable(target) == 1 then
		open_in_split(target)
	else
		local choice = vim.fn.confirm("Create matching file?\n" .. target, "&Yes\nNo", 2)

		if choice == 1 then
			create_matching_file(target)
		else
			print("Aborted")
		end
	end
end

return M
