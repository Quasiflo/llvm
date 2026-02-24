--- Lists available versions for a tool in this backend
--- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendlistversions
--- @param ctx {tool: string} Context (tool = the tool name requested)
--- @return {versions: string[]} Table containing list of available versions
function PLUGIN:BackendListVersions(ctx)
    local tool = ctx.tool

    -- Validate tool name
    if not tool or tool == "" then
        error("Tool name cannot be empty")
    end

    local cmd = require("cmd")

    local command = "git ls-remote --tags https://github.com/llvm/llvm-project.git"
    local result = cmd.exec(command)

    if not result then
        error("Failed to fetch versions for " .. tool)
    end

    local versions = {}
    local seen = {} -- To track unique versions

    for line in result:gmatch("[^\n]+") do
        local tag = line:match("\trefs/tags/(.+)")
        if tag then
            tag = tag:gsub("%^{}$", "") -- Strip peeled suffix
            local version = tag:gsub("llvmorg%-", "")
            if not seen[version] and tag:match("^llvmorg%-%d+%.%d+%.%d+$") then
                seen[version] = true
                table.insert(versions, version)
            end
        end
    end

    -- Sort versions by semver in ascending order
    table.sort(versions, function(a, b)
        local function parse_semver(v)
            local major, minor, patch = v:match("(%d+)%.(%d+)%.(%d+)")
            return tonumber(major), tonumber(minor), tonumber(patch)
        end
        local ma, na, pa = parse_semver(a)
        local mb, nb, pb = parse_semver(b)
        if ma ~= mb then
            return ma < mb
        end
        if na ~= nb then
            return na < nb
        end
        return pa < pb
    end)

    if #versions == 0 then
        error("No versions found for " .. tool)
    end

    return { versions = versions }
end
