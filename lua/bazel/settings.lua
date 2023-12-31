local M = {}
local DEFAULT_SETTINGS = {
    allowed_rule_names = { "py_binary", "py_test", },
}

M._DEFAULT_SETTINGS = DEFAULT_SETTINGS

M.current = M._DEFAULT_SETTINGS

function M.set(opts)
    M.current = vim.tbl_deep_extend("force", vim.deepcopy(M.current), opts)
end

return M
