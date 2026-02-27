--- Configuration loader for tool options from mise.toml
--- Options are passed via MISE_TOOL_OPTS__<NAME> environment variables
local M = {}

M.opts = nil

function M.init(ctx)
    local logger = require("src.logger")

    if not M.opts == nil then
        return
    end

    if ctx.options == nil then
        logger.warn("Mise version too old - Config options aren't supported!")
        M.opts = {}
    else
        logger.info("Config options loaded successfully")
        M.opts = ctx.options
    end
end

return M
