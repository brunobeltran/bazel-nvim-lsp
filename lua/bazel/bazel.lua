local pathlib = require("bazel.path")
local settings = require("bazel.settings")
local scandir = require("plenary.scandir")

local M = {}

M._CURRENT_WORKSPACE = ""
M._CURRENT_TARGET = ""
M._POSSIBLE_TARGETS = {}

function M._BazelWorkspace(path)
    -- TODO: make target run completely asynchronously. We want the ui to
    -- display "we are sorry, there is no workspace loaded yet" while this is
    -- still running (but only if it takes longer than some fixed time to run,
    -- as it is likely to do on first invocation). We can, for example, maintain
    -- a global "is in progress" state that we can update and use a callback
    -- instead of directly calling the *blocking* `vim.fn.system` here.
    path = path or pathlib.parent(vim.api.nvim_buf_get_name(0))
    M._CURRENT_WORKSPACE = vim.fn.system({ "bazel", "info", "workspace" }):gsub("%s+", "")
    return M._CURRENT_WORKSPACE
end

function M.BazelSetTarget(target)
    target = target or M.BazelListTargets()[1]
    M._CURRENT_TARGET = target
    local runfiles = M._BazelRunfilesFromTarget(target)
    -- TODO: upgrade to using scan_dir_async and keep the list separate (apply
    -- it on_exit of the scan_dir_async call).
    local site_packages = scandir.scan_dir(
        runfiles,
        {
            only_dirs = true,
            depth = 1,
            search_pattern = "pip_.*",
            silent = true,
        })
    for i, _ in pairs(site_packages) do
        site_packages[i] = pathlib.concat({ site_packages[i], "site-packages" })
    end
    table.insert(site_packages, runfiles)
    local config = { python = { analysis = { extraPaths = site_packages } } }
    local clients = vim.lsp.get_active_clients({
        bufnr = vim.api.nvim_get_current_buf(),
        name = "pyright",
    })
    for _, client in ipairs(clients) do
        client.config.settings = vim.tbl_deep_extend("force", client.config.settings, config)
        client.notify('workspace/didChangeConfiguration', { settings = nil })
    end
end

function M._BazelTargetFromFile(file)
    local package = pathlib.parent(file)
    local file_name = file:sub(#package + 1)
    if (package:sub(1, #M._CURRENT_WORKSPACE) ~= M._CURRENT_WORKSPACE) then
        error("Requested file " ..
            file .. " not in current Bazel workspace " .. M._CURRENT_WORKSPACE)
    end
    package = package:sub(#M._CURRENT_WORKSPACE + 1, -2)
    if pathlib.sep == "\\" then
        package = package:gsub("\\", "/")
    end
    -- The workspace does not have a trailing slash, so to get the starting
    -- "//", we just need to add a single slash.
    return "/" .. package .. ":" .. file_name
end

function M._BazelRunfiles()
    if M._CURRENT_TARGET == "" then
        return nil, "No target currently set."
    end
    return M._BazelRunfilesFromTarget(M._CURRENT_TARGET)
end

function M._BazelRunfilesFromTarget(target_name)
    local package, target = target_name:match("//(.*):(.*)")
    return pathlib.concat({ M._CURRENT_WORKSPACE, "bazel-bin", package, target .. ".runfiles" })
end

local function _update_targets(_, data, _)
    if data and data[1] ~= "" then
        M._POSSIBLE_TARGETS = {}
    end
    for _, v in pairs(data) do
        if v == "" then
            break
        end
        table.insert(M._POSSIBLE_TARGETS, v)
    end
end

function M.BazelListTargets(file, allowed_rule_names)
    if M._CURRENT_WORKSPACE == "" then
        local workspace_job = M._BazelWorkspace()
        vim.fn.jobwait({ workspace_job })
    end
    file = file or vim.api.nvim_buf_get_name(0)
    allowed_rule_names = allowed_rule_names or settings.current.allowed_rule_names
    local query = "kind(" .. '"' .. table.concat(allowed_rule_names, "|") ..
        '"' .. ", rdeps(//..., " .. M._BazelTargetFromFile(file) .. "))"
    vim.print(query)
    local job_id = vim.fn.jobstart(
        { "bazel", "query", query },
        {
            cwd = M._CURRENT_WORKSPACE,
            on_stdout = _update_targets,
        }
    )
    vim.fn.jobwait({ job_id })
    return M._POSSIBLE_TARGETS
end

return M
