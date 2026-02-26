--- Atomic lock module with command-line based waiting and inter-process health checking
local M = {}

local DEFAULT_TIMEOUT = 300
local DEFAULT_CHECK_INTERVAL = 2
local has_logged_wait = false

local function sleep(seconds)
    local cmd = require("cmd")
    if RUNTIME.osType == "windows" then
        pcall(cmd.exec, "timeout /t " .. seconds .. " /nobreak >nul")
    else
        pcall(cmd.exec, "sleep " .. seconds)
    end
end

local function escape_path(path)
    return path:gsub("'", "'\\''")
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
    return success and result and not result.exit_code
end

local function cleanup_stale_lock(lock_dir)
    local cmd = require("cmd")
    pcall(cmd.exec, "rm -rf '" .. escape_path(lock_dir) .. "'")
end

function M.acquire(lock_path, opts)
    opts = opts or {}
    local timeout = opts.timeout or DEFAULT_TIMEOUT
    local check_interval = opts.check_interval or DEFAULT_CHECK_INTERVAL

    local file = require("file")
    local cmd = require("cmd")
    local logger = require("src.logger")
    local lock_dir = lock_path
    local start_time = os.time()
    local logged_wait = false

    while os.time() - start_time < timeout do
        local success_mkdir, mkdir_result = pcall(cmd.exec, "mkdir '" .. escape_path(lock_dir) .. "' 2>/dev/null")
        if success_mkdir and mkdir_result and not mkdir_result.exit_code then
            if logged_wait then
                logger.success("Lock acquired")
            end
            has_logged_wait = false
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
                pcall(cmd.exec, "rmdir '" .. escape_path(lock_dir) .. "'")
            end
        end

        if not logged_wait then
            logger.step("Waiting for lock...")
            logged_wait = true
        end

        local info = read_lock_info(lock_dir)
        -- TODO if can't read info, assume stale
        if info then
            local owner_alive = is_process_alive(info.pid)
            logger.debug("Lock owner is still alive")

            if not owner_alive then
                cleanup_stale_lock(lock_dir)
                local success_mkdir2, mkdir_result2 =
                    pcall(cmd.exec, "mkdir '" .. escape_path(lock_dir) .. "' 2>/dev/null")
                if success_mkdir2 and mkdir_result2 and mkdir_result2.exit_code == 0 then
                    logger.success("Stale lock cleaned up, acquired new lock")
                    has_logged_wait = false
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
                        pcall(cmd.exec, "rmdir '" .. escape_path(lock_dir) .. "'")
                    end
                end
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

    pcall(cmd.exec, "rm -rf '" .. escape_path(lock_dir) .. "'")
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
