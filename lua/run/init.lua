local p = {}

p.last_cmd = nil
p.ouput_buffer = nil

-- TODO: add more interpreters
p.ft_defaults = {
	python = "python3",
	lua = "lua",
	sh = "sh",
	javascript = "node",
	ruby = "ruby",
}

local function get_default_cmd()
	local ft = vim.bo.filetype
	local ft_cmd = p.ft_defaults[ft]

	if ft_cmd then
		return ft_cmd
	end

	return p.last_cmd
end

local function get_output_buf()
	if p.output_buf and vim.api.nvim_buf_is_valid(p.output_buf) then
		return p.output_buf
	end
	return nil
end

local function find_output_win(buf)
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_buf(win) == buf then
			return win
		end
	end
	return nil
end

local function run(opts)
	local opts = opts or {}
	local mode = opts.mode

	local cmd = opts.cmd
	if cmd == nil or cmd == "" then
		cmd = vim.fn.input("Run command: ", get_default_cmd() or "")
	end

	if cmd == "" then
		return
	end

	p.last_cmd = cmd

	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local input = table.concat(lines, "\n")
	local redirects = ""

	if mode == "err" then
		local null = vim.loop.os_uname().version:match("Windows") and "NUL" or "/dev/null"
		redirects = " 2>&1 > " .. null
	elseif mode == "all" then
		redirects = " 2>&1"
	end

	local result = vim.fn.system(cmd .. redirects, input)
	local current_win = vim.api.nvim_get_current_win()
	local buf = get_output_buf()
	if not buf then
		buf = vim.api.nvim_create_buf(false, true)
		p.output_buf = buf
	end

	local output_win = find_output_win(buf)
	if not output_win then
		vim.cmd("belowright split")
		vim.api.nvim_win_set_buf(0, buf)
	end

	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].filetype = "runoutput"

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(result or "", "\n"))
	vim.api.nvim_set_current_win(current_win)
end

-- For other modules, just in case
function p.run(opts)
	run(opts)
end

function p.setup(opts)
	opts = opts or {}

	if opts.ft_defaults then
		p.ft_defaults = vim.tbl_extend("force", p.ft_defaults, opts.ft_defaults)
	end

	local modes = {
		["Run"] = "std",
		["RunErr"] = "err",
		["RunAll"] = "all",
	}

	for command, mode in pairs(modes) do
		vim.api.nvim_create_user_command(command, function(o)
			run({ cmd = o.args, mode = mode })
		end, {
			nargs = "*",
			complete = "shellcmd",
		})
	end
end

return p
