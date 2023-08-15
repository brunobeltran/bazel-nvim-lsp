local M = {}

M._CURRENT_SPINNER_INDEX = 1
M.SPINNER = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" }

function M.Progress()
    M._CURRENT_SPINNER_INDEX = M._CURRENT_SPINNER_INDEX + 1
    if M._CURRENT_SPINNER_INDEX > #M.SPINNER then
        M._CURRENT_SPINNER_INDEX = 1
    end
    return M.SPINNER[M._CURRENT_SPINNER_INDEX]
end

return M
