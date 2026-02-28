--- Atomic lock module with command-line based waiting and inter-process health checking
local M = {}

local DEFAULT_TIMEOUT = 300
local DEFAULT_CHECK_INTERVAL = 2

local function sleep(seconds)
    local cmd = require("cmd")
    if RUNTIME.osType == "windows" then
        pcall(cmd.exec, "timeout /t " .. seconds .. " /nobreak >nul")
    else
        pcall(cmd.exec, "sleep " .. seconds)
    end
end

local function read_lock_info(lock_dir)
    local cmd = require("cmd")
    local file = require("file")
    local info_path = file.join_path(lock_dir, "info")
    if not file.exists(info_path) then
        return nil
    end
    local handle = io.open(info_path, "r")
    if not handle then
        return nil
    end
    local content = handle:read("*a")
    handle:close()
    local json = require("json")
    local success, data = pcall(json.decode, content)
    if success and data then
        return data
    end
    return nil
end

local function write_lock_info(lock_dir, info)
    local file = require("file")
    local json = require("json")
    local info_path = file.join_path(lock_dir, "info")
    local handle = io.open(info_path, "w")
    if handle then
        handle:write(json.encode(info))
        handle:close()
        return true
    end
    return false
end

local function is_process_alive(pid)
    local cmd = require("cmd")
    if not pid then
        return false
    end
    local success, result = pcall(cmd.exec, "kill -0 " .. pid .. " 2>/dev/null")
    return success and result and not result.exit_code or false
end

local function cleanup_stale_lock(lock_dir)
    local cmd = require("cmd")
    pcall(cmd.exec, "rm -rf '" .. lock_dir .. "'")
end

function M.acquire(lock_path, opts)
    opts = opts or {}
    local timeout = opts.timeout or DEFAULT_TIMEOUT
    local check_interval = opts.check_interval or DEFAULT_CHECK_INTERVAL

    local cmd = require("cmd")
    local logger = require("src.logger")
    local lock_dir = lock_path
    local start_time = os.time()
    local logged_wait = false

    while os.time() - start_time < timeout do
        local success_mkdir, mkdir_result = pcall(cmd.exec, "mkdir '" .. lock_dir .. "' 2>/dev/null")
        if success_mkdir and mkdir_result and not mkdir_result.exit_code then
            if logged_wait then
                logger.success("Lock acquired")
            end
            local success_pid, pid_result = pcall(cmd.exec, "echo $PPID")
            local success_host, host_result = pcall(cmd.exec, "hostname")
            local info = {
                pid = success_pid and pid_result and tonumber(pid_result:match("%d+")) or 0,
                timestamp = os.time(),
                hostname = success_host and host_result and host_result:gsub("%s+", "") or "",
            }
            if write_lock_info(lock_dir, info) then
                return true
            else
                pcall(cmd.exec, "rmdir '" .. lock_dir .. "'")
            end
        end

        if not logged_wait then
            logger.step("Waiting for lock...")
            logged_wait = true
        end

        local info = read_lock_info(lock_dir)
        local is_stale = false

        if not info then
            -- If we can't get info, wait a bit and try again
            logger.debug("Couldn't get lock info, retrying...")
            sleep(DEFAULT_CHECK_INTERVAL)
            info = read_lock_info(lock_dir)
            if not info then
                logger.debug("Still couldn't get lock info, assuming stale")
                is_stale = true
            end
        end

        if not is_stale then
            is_stale = (is_process_alive((info and info.pid)) == false)
            if is_stale then
                logger.debug("Lock owner is dead, PID: " .. (info and info.pid))
            else
                logger.debug("Lock owner is still alive, PID: " .. (info and info.pid))
            end
        end

        if is_stale then
            logger.debug("Cleaning stale lock: " .. lock_dir)
            cleanup_stale_lock(lock_dir)
            local success_mkdir2, mkdir_result2 = pcall(cmd.exec, "mkdir '" .. lock_dir .. "' 2>/dev/null")
            if success_mkdir2 and mkdir_result2 and not mkdir_result2.exit_code then
                logger.success("Stale lock cleaned up, acquired new lock")
                local success_pid2, pid_result2 = pcall(cmd.exec, "echo $PPID")
                local success_host2, host_result2 = pcall(cmd.exec, "hostname")
                local new_info = {
                    pid = success_pid2 and pid_result2 and tonumber(pid_result2:match("%d+")) or 0,
                    timestamp = os.time(),
                    hostname = success_host2 and host_result2 and host_result2:gsub("%s+", "") or "",
                }
                if write_lock_info(lock_dir, new_info) then
                    return true
                else
                    pcall(cmd.exec, "rmdir '" .. lock_dir .. "'")
                end
            else
                logger.warn("Failed to acquire new lock, retrying")
            end
        end

        sleep(check_interval)
    end

    error("Failed to acquire lock after " .. timeout .. " seconds: " .. lock_path)
end

function M.release(lock_path)
    local cmd = require("cmd")
    local file = require("file")
    local lock_dir = lock_path

    if not file.exists(lock_dir) then
        return true
    end

    local info = read_lock_info(lock_dir)
    local success_pid, pid_result = pcall(cmd.exec, "echo $PPID")
    local current_pid = success_pid and pid_result and tonumber(pid_result:match("%d+")) or 0

    if info and info.pid ~= current_pid then
        return false
    end

    pcall(cmd.exec, "rm -rf '" .. lock_dir .. "'")
    return true
end

function M.is_locked(lock_path)
    local file = require("file")
    return file.exists(lock_path)
end

function M.get_lock_info(lock_path)
    return read_lock_info(lock_path)
end

return M
