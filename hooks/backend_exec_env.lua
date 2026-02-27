--- Sets up environment variables for a tool
--- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendexecenv
--- @param ctx {install_path: string, tool: string, version: string} Context
--- @return {env_vars: table[]} Table containing list of environment variable definitions
function PLUGIN:BackendExecEnv(ctx)
    local prefs = require("src.prefs")

    prefs.init(ctx)

    local install_path = ctx.install_path

    local file = require("file")
    local bin_path = file.join_path(install_path, "bin")
    local env_vars

    if file.exists(bin_path) then
        env_vars = { --   Add tool's bin directory to PATH
            {
                key = "PATH",
                value = bin_path,
            },
        }
    else
        env_vars = {}
    end

    return {
        env_vars = env_vars,
    }
end
