--- Lists available versions for a tool in this backend
--- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendlistversions
--- @param ctx {tool: string} Context (tool = the tool name requested)
--- @return {versions: string[]} Table containing list of available versions
function PLUGIN:BackendListVersions(ctx)
    local tool = ctx.tool

    if not tool or tool == "" then
        error("Tool name cannot be empty")
    end

    -- Use GitHub Releases API with mise's built-in caching.
    -- See: https://mise.jdx.dev/cache-behavior.html for how mise caches remote versions.
    -- By default, mise caches remote versions and updates daily.
    local versions = require("src.versions")

    local version_list = versions.fetch_versions()

    if #version_list == 0 then
        error("No versions found for " .. tool)
    end

    return { versions = version_list }
end
