--- Version parsing and sorting utilities
--- @see https://mise.jdx.dev/cache-behavior.html for how mise caches remote versions
local M = {}

function M.parse_semver(v)
    local major, minor, patch = v:match("(%d+)%.(%d+)%.(%d+)")
    return tonumber(major), tonumber(minor), tonumber(patch)
end

function M.compare_versions(a, b)
    local ma, na, pa = M.parse_semver(a)
    local mb, nb, pb = M.parse_semver(b)
    if ma ~= mb then
        return ma < mb
    end
    if na ~= nb then
        return na < nb
    end
    return pa < pb
end

--- Fetch all versions from GitHub Tags API with pagination
--- Uses per_page=100 to minimize API calls, handles pagination automatically
--- @return string[] versions List of available versions
function M.fetch_versions()
    local cmd = require("cmd")

    local command = "git ls-remote --tags https://github.com/llvm/llvm-project.git"
    local result = cmd.exec(command)

    if not result then
        error("Failed to fetch versions")
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

    table.sort(versions, M.compare_versions)

    if #versions == 0 then
        error("No versions extracted from github tags")
    end

    return versions
end

return M
