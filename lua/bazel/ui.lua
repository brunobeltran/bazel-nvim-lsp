local bazel = require("bazel.bazel")
local original_buf, popup_buf, win

local function center(str)
    local width = vim.api.nvim_win_get_width(0)
    local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
    return string.rep(' ', shift) .. str
end

local function open_window()
    original_buf = vim.api.nvim_buf_get_name(0)
    popup_buf = vim.api.nvim_create_buf(false, true)
    local border_buf = vim.api.nvim_create_buf(false, true)

    vim.api.nvim_buf_set_option(popup_buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(popup_buf, 'filetype', 'bazel_plugin')

    local width = vim.api.nvim_get_option("columns")
    local height = vim.api.nvim_get_option("lines")

    local win_height = math.ceil(height * 0.8 - 4)
    local win_width = math.ceil(width * 0.8)
    local row = math.ceil((height - win_height) / 2 - 1)
    local col = math.ceil((width - win_width) / 2)

    local border_opts = {
        style = "minimal",
        relative = "editor",
        width = win_width + 2,
        height = win_height + 2,
        row = row - 1,
        col = col - 1
    }

    local opts = {
        style = "minimal",
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col
    }

    local border_lines = { '╔' .. string.rep('═', win_width) .. '╗' }
    local middle_line = '║' .. string.rep(' ', win_width) .. '║'
    for i = 1, win_height do
        table.insert(border_lines, middle_line)
    end
    table.insert(border_lines, '╚' .. string.rep('═', win_width) .. '╝')
    vim.api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)

    local border_win = vim.api.nvim_open_win(border_buf, true, border_opts)
    win = vim.api.nvim_open_win(popup_buf, true, opts)
    vim.api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "' .. border_buf)

    -- Highlight the line with the cursor on it.
    vim.api.nvim_win_set_option(win, 'cursorline', true)

    -- we can add title already here, because first line will never change
    vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, { center("Bazel Targets"), "", "" })
    vim.api.nvim_buf_add_highlight(popup_buf, -1, 'BazelPluginHeader', 0, 0, -1)
end

local function update_view()
    vim.api.nvim_buf_set_option(popup_buf, 'modifiable', true)
    local result = bazel.BazelListTargets(original_buf)
    -- Empty line to preserve layout if there are no results.
    if #result == 0 then table.insert(result, '') end
    for k, _ in pairs(result) do
        result[k] = '  ' .. result[k]
    end

    vim.api.nvim_buf_set_lines(popup_buf, 1, 2, false, { center(vim.api.nvim_buf_get_name(0)) })
    vim.api.nvim_buf_set_lines(popup_buf, 3, -1, false, result)

    vim.api.nvim_buf_add_highlight(popup_buf, -1, 'BazelPluginSubHeader', 1, 0, -1)
    vim.api.nvim_buf_set_option(popup_buf, 'modifiable', false)
end

local function close_window()
    vim.api.nvim_win_close(win, true)
end

local function set_target()
    local str = vim.api.nvim_get_current_line()
    close_window()
    bazel.BazelSetTarget(str:gsub("%s+", ""))
end

local function move_cursor(num_lines)
    local new_pos = math.max(4, vim.api.nvim_win_get_cursor(win)[1] + num_lines)
    vim.api.nvim_win_set_cursor(win, { new_pos, 0 })
end

local function set_mappings()
    local mappings = {
        ['<cr>'] = 'set_target()',
        q = 'close_window()',
        k = 'move_cursor(-1)',
        j = 'move_cursor(1)'
    }

    for k, v in pairs(mappings) do
        vim.api.nvim_buf_set_keymap(popup_buf, 'n', k, ':lua require"bazel.ui".' .. v .. '<cr>', {
            nowait = true, noremap = true, silent = true
        })
    end
    local other_chars = {
        'a', 'b', 'c', 'd', 'e', 'f', 'g', 'i', 'n', 'o', 'p', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
    }
    for _, v in ipairs(other_chars) do
        vim.api.nvim_buf_set_keymap(popup_buf, 'n', v, '', { nowait = true, noremap = true, silent = true })
        vim.api.nvim_buf_set_keymap(popup_buf, 'n', v:upper(), '', { nowait = true, noremap = true, silent = true })
        vim.api.nvim_buf_set_keymap(popup_buf, 'n', '<c-' .. v .. '>', '',
            { nowait = true, noremap = true, silent = true })
    end
end

local function ui()
    open_window()
    set_mappings()
    update_view()
    vim.api.nvim_win_set_cursor(win, { 4, 0 })
end

return {
    ui = ui,
    update_view = update_view,
    set_target = set_target,
    move_cursor = move_cursor,
    close_window = close_window,
}
