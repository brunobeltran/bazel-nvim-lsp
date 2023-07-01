local M = {}

M.sep = (function()
    if (vim.loop.os_uname().sysname:find("Windows") ~= nil) then
        return "\\"
    else
        return "/"
    end
end)()

function M.concat(parts)
    return table.concat(parts, M.sep)
end

function M.parent(path, sep)
    sep = sep or M.sep
    if sep == "\\" and path:match("%u:\\") or sep == "/" and path == "/" then
        return path
    else
        return path:match("(.*" .. sep .. ")")
    end
end

return M
