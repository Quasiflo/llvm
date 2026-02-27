--- Core LLVM build logic
local M = {}

function M.build_if_missing(core_install_path, core_source_dir, cores)
    local cmd = require("cmd")
    local file = require("file")
    local cmake = require("src.cmake")
    local lock = require("src.lock")
    local logger = require("src.logger")

    local lockfile = file.join_path(core_install_path, ".lock")
    lock.acquire(lockfile, { timeout = 300000 })

    if file.exists(file.join_path(core_install_path, "bin")) then
        lock.release(lockfile)
        logger.skip("Core LLVM already built, skipping...")
        return
    end

    logger.section("Building Core LLVM")
    logger.step("Building core LLVM libraries (shared across all tools)...")
    logger.debug("This may take a while on first build...")

    local build_dir = file.join_path(core_source_dir, "build")
    cmd.exec("mkdir -p " .. build_dir)

    local cmake_cmd = cmake.build_core_cmake_command(core_source_dir, core_install_path)
    logger.debug_cmd(cmake_cmd)

    logger.step("Configuring core LLVM...")
    cmd.exec("cd " .. build_dir .. " && " .. cmake_cmd)

    logger.step("Compiling core LLVM (using " .. cores .. " parallel cores)...")
    cmd.exec("cd " .. build_dir .. " && " .. cmake.build_compile_command(cores))

    logger.step("Installing core LLVM...")
    cmd.exec("cd " .. build_dir .. " && " .. cmake.build_install_command())

    logger.success("Core LLVM build complete")

    lock.release(lockfile)
end

return M
