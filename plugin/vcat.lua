local vcat = require("vcat")
vim.api.nvim_create_user_command("CatObjDump", function(opts)
	local args = vim.split(opts.args, " ")
	local eval_args = {}
	for _, arg in ipairs(args) do
		table.insert(eval_args, vim.api.nvim_eval(arg))
	end
	vcat.obj_dump(unpack(eval_args))
end, { nargs = "*" })
