--- Build module loader
local M = {
    core = require("src.build.core"),
    tool = require("src.build.tool"),
    prebuilt = require("src.build.prebuilt"),
}

return M
