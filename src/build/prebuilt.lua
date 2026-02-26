--- Prebuilt binary download logic (infrastructure for future use)
local M = {}

function M.is_available(tool, version)
    return false
end

function M.get_download_url(tool, version, os_type, arch)
    local url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-" .. version .. "/"
    return url
end

function M.install(tool, version, install_path)
    error("Prebuilt binaries not yet implemented")
end

return M
