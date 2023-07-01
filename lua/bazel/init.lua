local settings = require "bazel.settings"

local M = {}

function M.setup(config)
    settings.set(config)
    require("bazel.api")
end

return M
