--- Download logic with atomic lock handling
local M = {}

function M.download_source_tarball(version, download_path)
    local cmd = require("cmd")
    local file = require("file")
    local lock = require("src.lock")

    local tarball_name = "llvm-project-" .. version .. ".src.tar.xz"
    local tarball_path = file.join_path(download_path, tarball_name)
    local lock_path = file.join_path(download_path, ".lock")

    if not file.exists(tarball_path) then
        lock.acquire(lock_path, { timeout = 1200 })
        if not file.exists(tarball_path) then
            local url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-"
                .. version
                .. "/"
                .. tarball_name
            cmd.exec("curl -L --fail -o " .. tarball_path .. " " .. url)
        end
        lock.release(lock_path)
    end

    return tarball_path
end

function M.extract_source(tarball_path, download_path, version)
    local cmd = require("cmd")
    local file = require("file")

    local source_dir = file.join_path(download_path, "llvm-project-" .. version .. ".src")
    if not file.exists(source_dir) then
        cmd.exec("tar -xJf " .. tarball_path .. " -C " .. download_path)
    end

    return source_dir
end

return M
