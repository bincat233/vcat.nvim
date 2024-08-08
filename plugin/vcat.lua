local vcat = require("vcat")
vim.api.nvim_create_user_command("VCatObjDump", function(opts)
	if opts.args == "" then
		print("Error: No object provided.")
		return
	end
	local code = "vcat.obj_dump(" .. table.concat(opts.fargs, ",") .. ")"
	load(code)()
	local args = vim.split(opts.args, " ")
end, { nargs = "*" })
