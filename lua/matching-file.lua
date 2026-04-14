local M = {}

M.setup = function() end

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

local function goto_matching_file_in_same_directory(file, matcher)
	return file:gsub(matcher.from, matcher.to)
end

local function find_project_dir(start, projectfilepattern)
	local dir = start

	while dir do
		local projectfiles = vim.fs.find(function(name, path)
			return name:match(projectfilepattern)
		end, { path = dir, limit = 1, type = "file" })
		if #projectfiles > 0 then
			return dir
		end

		local parent = vim.fs.dirname(dir)
		if parent == dir then
			return nil
		end

		dir = parent
	end
end

local function ends_with(string, suffix)
	return string:sub(-#suffix) == suffix
end

local function goto_matching_file_in_project(file, matcher)
	local projectdir = find_project_dir(vim.fs.dirname(file), matcher.projectfilepattern)

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

M.matchers = {
	{ from = "%.spec%.ts$", to = ".ts", strategy = goto_matching_file_in_same_directory },
	{ from = "%.ts$", to = ".spec.ts", strategy = goto_matching_file_in_same_directory },
	{
		from = "%.cs$",
		strategy = goto_matching_file_in_project,
		projectfilepattern = ".*%.csproj$",
		projectsuffix1 = ".Test",
		projectsuffix2 = "",
		suffix1 = "Test.cs",
		suffix2 = ".cs",
	},
}

M.determine_target_file = function(file)
	local filename = vim.fn.fnamemodify(file, ":t")
	local target

	for _, matcher in ipairs(M.matchers) do
		if filename:match(matcher.from) then
			target = matcher.strategy(file, matcher)
			break
		end
	end

	return target
end

M.goto_matching_file = function()
	local file = vim.api.nvim_buf_get_name(0)
	local target = M.determine_target_file(file)

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

vim.keymap.set("n", "gm", M.goto_matching_file, { desc = "Go to matching file" })
return M
