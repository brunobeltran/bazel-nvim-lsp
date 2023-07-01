local bazel = require("bazel.bazel")
local ui = require("bazel.ui")

vim.api.nvim_create_user_command("BazelWorkspace", function(opts)
    bazel.BazelWorkspace(opts.fargs[1])
end, {
    nargs = "*",
    desc = "Set current Bazel workspace to the one containing a given file.",
})

vim.api.nvim_create_user_command("BazelListTargets", function(opts)
    bazel.BazelListTargets(opts.fargs[1], opts.fargs[2])
end, {
    nargs = "*",
    desc = "Print the Bazel targets of a given type that depend on the current file.",
})

vim.api.nvim_create_user_command("BazelSelectTarget", function(opts)
    ui.ui()
end, {
    desc = "Pull up a selector pop-up to choose a target to use the runfiles of."
})
