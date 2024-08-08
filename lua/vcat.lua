---@class VCat
local M = {}

---@class Config
---@field opt string config option
local config = {
	opt = "",
}

---@type Config
M.config = config

---@param args Config?
-- you can define your setup function here. Usually configurations can be merged, accepting outside params and
-- you can also put some validation here for those.
M.setup = function(args)
	M.config = vim.tbl_deep_extend("force", M.config, args or {})
end

-- Function to source vimscript files
function M.source_viml(file)
	vim.cmd("source " .. vim.fn.stdpath("config") .. "/" .. file)
end

-- @param func The function to get source code from
-- @return string The source code of the function
function M.func_source(func)
	local info = debug.getinfo(func, "S")
	if info.source:sub(1, 1) == "@" then
		local file_path = info.source:sub(2)
		local file = io.open(file_path, "r")
		if file then
			local lines = {}
			for line in file:lines() do
				table.insert(lines, line)
			end
			file:close()
			local start_line = info.linedefined
			local end_line = info.lastlinedefined
			local source = {}
			for i = start_line, end_line do
				table.insert(source, lines[i])
			end
			return table.concat(source, "\n")
		end
	end
end

-- @param obj The object to inspect
-- @return string The string representation of the object
function M.obj_inspect(obj)
	if type(obj) == "function" then
		local info = debug.getinfo(obj, "S")
		local fun_str = string.format("<%s:%d>", info.short_src, info.linedefined)
		fun_str = fun_str
			.. "\n┌┄┄┄┄┄SOURCE CODE BEGIN┄┄┄┄┄\n┊"
			.. M.func_source(obj):gsub("\n", "\n┊")
			.. "\n└┄┄┄┄┄┄SOURCE CODE END┄┄┄┄┄┄"
		return fun_str
	elseif type(obj) == "table" then
		local result = {}
		for k, v in pairs(obj) do
			if type(k) == "number" then
				-- If key is number, add [ ] to it
				k = "[" .. k .. "]"
			elseif type(k) == "string" and k:find("[^%w]") then
				-- If key contains special characters, add [" "] to it
				k = string.format('["%s"]', k)
			end
			local str_v = M.obj_inspect(v)
			-- replace \n with \n\t
			str_v = str_v:gsub("\n", "\n\t")
			table.insert(result, string.format("\t%s = %s", k, str_v))
		end
		local content = table.concat(result, ",\n")
		if content == "" then
			return "{}"
		end
		return "{\n" .. content .. "\n}"
	else
		return vim.inspect(obj)
	end
end

-- A function to print lua tables. It's useful for debugging
-- @param ... The objects to print
-- @return ... The objects
function M.obj_dump(...)
	local objects = {}
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		table.insert(objects, M.obj_inspect(v))
	end
	local res = table.concat(objects, "\n")
	vim.notify(res, vim.log.levels.INFO)
	return ...
end

function M.sl()
	vim.api.nvim_command("write")
	local config_dir = vim.fn.stdpath("config")
	dofile(config_dir .. "/init.lua")
end

function M.safe_require(module_name)
	local status, module = pcall(require, module_name)
	if not status then
		vim.notify(module_name .. " not found!")
		return nil
	end
	return module
end

-- 获取高亮组颜色的辅助函数
function M.get_highlight_rgb(group)
	local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
	if hl.fg == nil then
		return { 0, 0, 0 }
	end
	local rgb = {
		bit.rshift(bit.band(hl.fg, 0xFF0000), 16),
		bit.rshift(bit.band(hl.fg, 0x00FF00), 8),
		bit.band(hl.fg, 0x0000FF),
	}
	return rgb
end

-- 计算混合颜色的辅助函数
function M.mix_colors(color1, color2)
	return {
		math.floor((color1[1] + color2[1]) / 2),
		math.floor((color1[2] + color2[2]) / 2),
		math.floor((color1[3] + color2[3]) / 2),
	}
end

-- 将 RGB 颜色转换为十六进制字符串
function M.rgb_to_hex(color)
	return string.format("#%02x%02x%02x", color[1], color[2], color[3])
end

_G.vcat = M

return M
