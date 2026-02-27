--- Configuration loader for tool options from mise.toml
--- Options are passed via MISE_TOOL_OPTS__<NAME> environment variables
local M = {}

M.opts = nil
M.initialized = false

function M.init(ctx)
    if M.initialized then
        return
    end

    M.opts = ctx.options
    M.initialized = true
end

return M
