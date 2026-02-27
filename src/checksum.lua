--- Checksum verification module for downloaded tarballs
local M = {}

local cmd = require("cmd")
local file = require("file")

function M.compute_sha256(tarball_path)
    local result = cmd.exec("sha256sum " .. tarball_path)
    if not result then
        error("Failed to compute SHA256 for " .. tarball_path)
    end
    local sha256 = result:match("^([a-fA-F0-9]+)")
    if not sha256 then
        error("Failed to parse SHA256 from output: " .. result)
    end
    return sha256
end

function M.get_checksum_path(tarball_path)
    return tarball_path .. ".sha256"
end

function M.get_cached_checksum(tarball_path)
    local checksum_path = M.get_checksum_path(tarball_path)
    if file.exists(checksum_path) then
        local f = io.open(checksum_path, "r")
        if f then
            local sha256 = f:read("*a"):match("^([a-fA-F0-9]+)")
            f:close()
            return sha256
        end
    end
    return nil
end

function M.save_checksum(tarball_path, sha256)
    local checksum_path = M.get_checksum_path(tarball_path)
    local f = io.open(checksum_path, "w")
    if not f then
        error("Failed to write checksum file: " .. checksum_path)
    end
    f:write(sha256)
    f:close()
end

function M.verify_checksum(tarball_path)
    local cached = M.get_cached_checksum(tarball_path)
    if not cached then
        return false, "no cached checksum"
    end
    local computed = M.compute_sha256(tarball_path)
    if computed ~= cached then
        return false, "checksum mismatch (cached: " .. cached .. ", computed: " .. computed .. ")"
    end
    return true, nil
end

return M
