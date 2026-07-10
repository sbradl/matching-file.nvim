local resolve_opts = require("matching-file")._resolve_opts

---Collect the names of the resolved matchers, in order.
local function matcher_names(opts)
	return vim.tbl_map(function(matcher)
		return matcher.name
	end, opts.matchers)
end

describe("matching-file.resolve_opts", function()
	describe("given no opts", function()
		it("should return all built-in matchers", function()
			assert.are.same({ "typescript", "typescript", "csharp" }, matcher_names(resolve_opts()))
		end)

		it("should treat nil and empty opts the same", function()
			assert.are.same(matcher_names(resolve_opts()), matcher_names(resolve_opts({})))
		end)
	end)

	describe("given matchers", function()
		it("should append them to the built-ins", function()
			local opts = resolve_opts({
				matchers = { { name = "python", from = "%.py$", to = "_test.py", strategy = "same_directory" } },
			})

			assert.are.same({ "typescript", "typescript", "csharp", "python" }, matcher_names(opts))
		end)

		it("should not mutate the built-in defaults across calls", function()
			resolve_opts({
				matchers = { { name = "python", from = "%.py$", to = "_test.py", strategy = "same_directory" } },
			})

			assert.are.same({ "typescript", "typescript", "csharp" }, matcher_names(resolve_opts()))
		end)

		it("should not mutate the input matchers list", function()
			local input = { { name = "python", from = "%.py$", to = "_test.py", strategy = "same_directory" } }
			resolve_opts({ matchers = input })

			assert.are.same(1, #input)
		end)
	end)

	describe("given disable", function()
		it("should remove every matcher with a disabled name", function()
			local opts = resolve_opts({ disable = { "typescript" } })

			assert.are.same({ "csharp" }, matcher_names(opts))
		end)

		it("should support disabling multiple names", function()
			local opts = resolve_opts({ disable = { "typescript", "csharp" } })

			assert.are.same({}, matcher_names(opts))
		end)

		it("should ignore duplicate names", function()
			local opts = resolve_opts({ disable = { "csharp", "csharp" } })

			assert.are.same({ "typescript", "typescript" }, matcher_names(opts))
		end)

		it("should error on an unknown name", function()
			assert.has_error(function()
				resolve_opts({ disable = { "does-not-exist" } })
			end, 'matching-file: cannot disable unknown matcher "does-not-exist"')
		end)

		it("should also disable appended matchers by name", function()
			local opts = resolve_opts({
				matchers = { { name = "python", from = "%.py$", to = "_test.py", strategy = "same_directory" } },
				disable = { "python" },
			})

			assert.are.same({ "typescript", "typescript", "csharp" }, matcher_names(opts))
		end)
	end)
end)

