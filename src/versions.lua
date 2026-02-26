--- Version parsing and sorting utilities
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

function M.parse_git_remote_tags(result)
    local versions = {}
    local seen = {}

    for line in result:gmatch("[^\n]+") do
        local tag = line:match("\trefs/tags/(.+)")
        if tag then
            tag = tag:gsub("%^{}$", "")
            local version = tag:gsub("llvmorg%-", "")
            if not seen[version] and tag:match("^llvmorg%-%d+%.%d+%.%d+$") then
                seen[version] = true
                table.insert(versions, version)
            end
        end
    end

    table.sort(versions, M.compare_versions)
    return versions
end

return M
