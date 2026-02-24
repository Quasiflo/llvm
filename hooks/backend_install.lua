--- Installs a specific version of a tool
--- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendinstall
--- @param ctx {tool: string, version: string, install_path: string, download_path: string} Context
--- @return table Empty table on success
-- TODO allow generic extra flag passing to cmake for builds of tools?
-- TODO add logging so tools are telling what they're doing and what point in the process they're at
function PLUGIN:BackendInstall(ctx)
    local cmd = require("cmd")
    local file = require("file")

    local function escape_magic(s)
        return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1"))
    end

    local function wait(seconds)
        local start = os.time()
        repeat
        until os.time() > start + seconds
    end

    local tool = ctx.tool
    local version = ctx.version
    local install_path = ctx.install_path
    local download_path = ctx.download_path

    local core_name = "core"
    local core_install_path = install_path:gsub(escape_magic(tool), core_name)
    local core_download_path = download_path:gsub(escape_magic(tool), core_name)
    local core_source_dir = file.join_path(core_download_path, "llvm-project-" .. version .. ".src")
    local download_lockfile = file.join_path(core_download_path, ".lockdownload")
    local build_lockfile = file.join_path(core_install_path, ".lockbuild")

    if not tool or tool == "" then
        error("Tool name cannot be empty")
    end
    if not version or version == "" then
        error("Version cannot be empty")
    end

    -- Lookup table for tool-specific config
    -- TODO update bin to toolcheck system
    local tool_config = {
        ["bolt"] = {
            project = "bolt",
            bin = "llvm-bolt",
            extra_flags = "",
        },
        ["clang"] = {
            project = "clang",
            bin = "clang",
            extra_flags = "-DLLVM_EXTERNAL_CLANG_TOOLS_EXTRA_SOURCE_DIR="
                .. file.join_path(core_source_dir, "clang-tools-extra"), -- TODO make variable to ignore clang extra tools
        },
        ["compiler-rt"] = {
            project = "compiler-rt",
            bin = "",
            extra_flags = "",
        },
        -- ["flang"] = { -- TODO error with MLIR_TABLEGEN not getting found properly for out of tree builds
        --     project = "flang",
        --     bin = "flang",
        --     extra_flags = "-DClang_DIR=" ..
        --         file.join_path(install_path:gsub(escape_magic(tool), "clang"), "lib", "cmake", "clang") ..
        --         " -DMLIR_DIR=" .. file.join_path(install_path:gsub(escape_magic(tool), "mlir"), "lib", "cmake", "mlir") ..
        --         " -DLLVM_DIR=" .. file.join_path(install_path:gsub(escape_magic(tool), "llvm"), "lib", "cmake", "llvm")
        -- },
        ["libc"] = {
            project = "libc",
            bin = "libc",
            extra_flags = '-DLLVM_ENABLE_RUNTIMES="libc"',
            runtime = true,
        },
        -- ["libclc"] = { -- TODO
        --     project = "libclc",
        --     bin = "libclc",
        --     extra_flags = "-DLLVM_ENABLE_RUNTIMES=\"libclc\"" .. "-DClang_DIR=" ..
        --         file.join_path(install_path:gsub(escape_magic(tool), "clang"), "lib", "cmake", "clang"),
        --     runtime = true
        -- },
        ["libcxx"] = { -- NOTE - this builds with libcxxabi and libunwind
            project = "libcxx",
            bin = "libcxx",
            extra_flags = '-DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind"',
            runtime = true,
        },
        ["libunwind"] = {
            project = "libunwind",
            bin = "libunwind",
            extra_flags = '-DLLVM_ENABLE_RUNTIMES="libunwind"',
            runtime = true,
        },
        ["lld"] = {
            project = "lld",
            bin = "lld",
            extra_flags = "",
        },
        -- ["lldb"] = { -- TODO requires python to generate particular files at compile time (search SBLanguages.h)
        --     project = "lldb",
        --     bin = "lldb",
        --     extra_flags = "-DLLDB_INCLUDE_TESTS=OFF -DLLDB_ENABLE_PYTHON=OFF" .. " -DClang_DIR=" ..
        --         file.join_path(install_path:gsub(escape_magic(tool), "clang"), "lib", "cmake", "clang")
        -- },
        ["mlir"] = {
            project = "mlir",
            bin = "mlir",
            extra_flags = "",
        },
        -- ["offload"] = { -- TODO test on linux (not available for other OSes)
        --     project = "offload",
        --     bin = "offload",
        --     extra_flags = ""
        -- },
        ["openmp"] = {
            project = "openmp",
            bin = "openmp",
            extra_flags = "",
        },
        ["polly"] = { -- TODO
            project = "polly",
            bin = "polly",
            extra_flags = "-DCMAKE_CXX_STANDARD=17",
        },
    }

    local toolConfig = tool_config[tool]
    if not toolConfig then
        local available = {}
        for k in pairs(tool_config) do
            table.insert(available, k)
        end
        table.sort(available)
        error("Unsupported tool: " .. tool .. ". Available tools: " .. table.concat(available, ", "))
    end

    cmd.exec("mkdir -p " .. core_download_path)
    cmd.exec("mkdir -p " .. core_install_path)

    -- Download source tarball if missing
    local tarball_name = "llvm-project-" .. version .. ".src.tar.xz"
    local tarball_path = file.join_path(core_download_path, tarball_name)
    while file.exists(download_lockfile) do
        wait(5)
    end
    if not file.exists(tarball_path) then
        cmd.exec("touch " .. download_lockfile)
        local url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-" .. version .. "/" .. tarball_name
        cmd.exec("curl -L --fail -o " .. tarball_path .. " " .. url)
        cmd.exec("rm " .. download_lockfile)
    end

    -- Extract source if missing
    if not file.exists(core_source_dir) then
        cmd.exec("tar -xJf " .. tarball_path .. " -C " .. core_download_path)
    end

    -- Determine cores for parallel build
    local cores_cmd = RUNTIME.osType == "Linux" and "nproc" or "sysctl -n hw.ncpu"
    local cores_output = cmd.exec(cores_cmd)
    local cores = cores_output:gsub("%s+", "")

    -- Build core library if missing
    local disableTestsFlags =
        "-DLLVM_INCLUDE_EXAMPLES=OFF -DLLVM_BUILD_EXAMPLES=OFF -DLLVM_INCLUDE_TESTS=OFF -DLLVM_BUILD_TESTS=OFF"

    while file.exists(build_lockfile) do
        wait(5)
    end
    if not file.exists(file.join_path(core_install_path, "bin")) then
        cmd.exec("touch " .. build_lockfile)
        local core_build_dir = file.join_path(core_source_dir, "build")
        cmd.exec("mkdir -p " .. core_build_dir)
        local cmake_core = "cmake -S "
            .. file.join_path(core_source_dir, "llvm")
            .. " -B . -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="
            .. core_install_path
            .. " -DLLVM_INSTALL_UTILS=ON -DLLVM_ENABLE_PROJECTS='' -DLLVM_INCLUDE_TOOLS=OFF -DLLVM_BUILD_TOOLS=OFF "
            .. disableTestsFlags
            .. ""
        cmd.exec("cd " .. core_build_dir .. " && " .. cmake_core)
        cmd.exec("cd " .. core_build_dir .. " && cmake --build . --parallel " .. cores)
        cmd.exec("cd " .. core_build_dir .. " && cmake --install .")
        cmd.exec("rm " .. build_lockfile)
    end

    -- Skip tool build if already available
    local tool_bin_path = file.join_path(install_path, "bin", toolConfig.bin)
    if file.exists(tool_bin_path) then
        return {}
    end

    -- Build and install tool linked to core
    cmd.exec("mkdir -p " .. install_path)
    local tool_build_dir = file.join_path(download_path, "build")
    cmd.exec("mkdir -p " .. tool_build_dir)
    -- local llvm_cmake_dir = file.join_path(core_install_path, "lib", "cmake", "llvm")
    local cmake_tool = "cmake -S "
        .. file.join_path(core_source_dir, toolConfig.runtime and "runtimes" or toolConfig.project)
        .. " -B . -DCMAKE_BUILD_TYPE=Release "
        .. disableTestsFlags
        .. " -DCMAKE_INSTALL_PREFIX="
        .. install_path
        .. " -DLLVM_ROOT="
        .. core_install_path
        .. " "
        .. toolConfig.extra_flags
    cmd.exec("cd " .. tool_build_dir .. " && " .. cmake_tool)
    if tool == "compiler-rt" then -- TODO variable to enable this fix
        cmd.exec("cd " .. tool_build_dir .. " && cmake --build . --parallel 1")
    else
        cmd.exec("cd " .. tool_build_dir .. " && cmake --build . --parallel " .. cores)
    end
    cmd.exec("cd " .. tool_build_dir .. " && cmake --install .")

    return {}
end
