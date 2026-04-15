local determine_target_file = require("matching-file")._determine_target_file

local function assert_matching_file(expected_target, file)
	assert.are.same(
		vim.fs.abspath("testdata/" .. expected_target),
		determine_target_file(vim.fs.abspath("testdata/" .. file))
	)
end

describe("matching-file.determine_target_file", function()
	describe("typescript", function()
		describe("given spec file", function()
			it("should return matching ts file", function()
				assert_matching_file("ts/test.ts", "ts/test.spec.ts")
			end)
		end)

		describe("given ts file", function()
			it("should return matching spec file", function()
				assert_matching_file("ts/test.spec.ts", "ts/test.ts")
			end)
		end)
	end)

	describe("c#", function()
		describe("given test file", function()
			it("should return matching cs file", function()
				assert_matching_file("cs/Project/Class.cs", "cs/Project.Test/ClassTest.cs")
				assert_matching_file("cs/Project/Namespace/Class2.cs", "cs/Project.Test/Namespace/Class2Test.cs")
			end)
		end)

		describe("given cs file", function()
			it("should return matching test file", function()
				assert_matching_file("cs/Project.Test/ClassTest.cs", "cs/Project/Class.cs")
				assert_matching_file("cs/Project.Test/Namespace/Class2Test.cs", "cs/Project/Namespace/Class2.cs")
			end)
		end)
	end)
end)
