--- Installs a specific version of a tool
--- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendinstall
--- @param ctx {tool: string, version: string, install_path: string, download_path: string} Context
--- @return table Empty table on success
function PLUGIN:BackendInstall(ctx)
    local cmd = require("cmd")
    local file = require("file")
    local logger = require("src.logger")
    local util = require("src.util")
    local config = require("src.config")
    local download = require("src.download")
    local build_core = require("src.build.core")
    local build_tool = require("src.build.tool")
    local prebuild = require("src.prebuild")

    local tool = ctx.tool
    local version = ctx.version
    local install_path = ctx.install_path
    local download_path = ctx.download_path

    if not tool or tool == "" then
        error("Tool name cannot be empty")
    end
    if not version or version == "" then
        error("Version cannot be empty")
    end

    logger.milestone("Installing " .. tool .. " " .. version .. " ...")

    local tool_config = config.validate_tool(tool)

    prebuild.check_all_requirements(tool, tool_config)

    local core_name = "core"
    local core_install_path = install_path:gsub(util.escape_magic(tool), core_name)
    local core_download_path = download_path:gsub(util.escape_magic(tool), core_name)

    cmd.exec("mkdir -p " .. core_download_path)
    cmd.exec("mkdir -p " .. core_install_path)

    local tarball_path = download.download_source_tarball(version, core_download_path)
    local core_source_dir = download.extract_source(tarball_path, core_download_path, version)
    local tool_source_dir = file.join_path(core_source_dir, tool)

    local cores = util.get_parallel_cores()

    build_core.build_if_missing(core_install_path, core_source_dir, cores)

    build_tool.build(tool, version, install_path, download_path, tool_source_dir, core_install_path, tool_config, cores)

    return {}
end
