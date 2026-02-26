--- Lists available versions for a tool in this backend
--- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendlistversions
--- @param ctx {tool: string} Context (tool = the tool name requested)
--- @return {versions: string[]} Table containing list of available versions
function PLUGIN:BackendListVersions(ctx)
    local tool = ctx.tool

    if not tool or tool == "" then
        error("Tool name cannot be empty")
    end

    local cmd = require("cmd")
    local versions = require("src.versions")

    local command = "git ls-remote --tags https://github.com/llvm/llvm-project.git"
    local result = cmd.exec(command)

    if not result then
        error("Failed to fetch versions for " .. tool)
    end

    local version_list = versions.parse_git_remote_tags(result)

    if #version_list == 0 then
        error("No versions found for " .. tool)
    end

    return { versions = version_list }
end
