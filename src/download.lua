--- Download logic with atomic lock handling
local M = {}

function M.download_source_tarball(version, download_path)
    local cmd = require("cmd")
    local file = require("file")
    local lock = require("src.lock")
    local logger = require("src.logger")

    local tarball_name = "llvm-project-" .. version .. ".src.tar.xz"
    local tarball_path = file.join_path(download_path, tarball_name)
    local lock_path = file.join_path(download_path, ".lock")

    lock.acquire(lock_path, { timeout = 300000 })
    if file.exists(tarball_path) then
        logger.skip("Source tarball already downloaded")
        return tarball_path
    else
        logger.step("Downloading LLVM " .. version .. " source...")
        local url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-" .. version .. "/" .. tarball_name
        cmd.exec("curl -L --fail -o " .. tarball_path .. " " .. url)
    end
    lock.release(lock_path)

    logger.success("Downloaded " .. tarball_name)

    return tarball_path
end

function M.extract_source(tarball_path, builds_path, version)
    local cmd = require("cmd")
    local file = require("file")
    local lock = require("src.lock")
    local logger = require("src.logger")

    local source_dir = file.join_path(builds_path, "llvm-project-" .. version .. ".src")
    local lock_path = file.join_path(builds_path, ".lock")

    lock.acquire(lock_path, { timeout = 300000 })
    if not file.exists(source_dir) then
        logger.step("Extracting source...")
        cmd.exec("tar -xJf " .. tarball_path .. " -C " .. builds_path)
        logger.success("Extracted source")
    else
        logger.skip("Source already extracted")
    end
    lock.release(lock_path)

    return source_dir
end

return M
