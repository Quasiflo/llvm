--- Download logic with lockfile handling
local M = {}

local function wait(seconds)
    local start = os.time()
    repeat
    until os.time() > start + seconds
end

function M.download_source_tarball(version, download_path)
    local cmd = require("cmd")
    local file = require("file")

    local tarball_name = "llvm-project-" .. version .. ".src.tar.xz"
    local tarball_path = file.join_path(download_path, tarball_name)
    local lockfile_path = file.join_path(download_path, ".lockdownload")

    while file.exists(lockfile_path) do
        wait(5)
    end

    if not file.exists(tarball_path) then
        cmd.exec("touch " .. lockfile_path)
        local url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-" .. version .. "/" .. tarball_name
        cmd.exec("curl -L --fail -o " .. tarball_path .. " " .. url)
        cmd.exec("rm " .. lockfile_path)
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

function M.wait_for_build_lock(lockfile_path)
    local file = require("file")
    while file.exists(lockfile_path) do
        wait(5)
    end
end

function M.acquire_build_lock(lockfile_path)
    local cmd = require("cmd")
    local file = require("file")
    M.wait_for_build_lock(lockfile_path)
    cmd.exec("touch " .. lockfile_path)
end

function M.release_build_lock(lockfile_path)
    local cmd = require("cmd")
    cmd.exec("rm " .. lockfile_path)
end

return M
