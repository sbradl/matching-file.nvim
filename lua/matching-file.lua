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
	vim.cmd("write")
end

M.matching_file_pairs = {
	{ from = "%.spec%.ts$", to = ".ts" },
	{ from = "%.ts$", to = ".spec.ts" },
}

M.goto_matching_file = function()
	local file = vim.api.nvim_buf_get_name(0)
	local target

	for _, pair in ipairs(M.matching_file_pairs) do
		if file:match(pair.from) then
			target = file:gsub(pair.from, pair.to)
			break
		end
	end

	if not target then
		print("No matching file pair rule")
		return
	end

	if vim.fn.filereadable(target) == 1 then
		open_in_split(target)
	else
		local choice = vim.fn.confirm("Create corresponding file?\n" .. target, "&Yes\nNo", 2)

		if choice == 1 then
			open_in_split(target)
		else
			print("Aborted")
		end
	end
end

vim.keymap.set("n", "gm", M.goto_matching_file, { desc = "Go to matching file" })
return M
