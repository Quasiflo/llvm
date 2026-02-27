Bonus tools using variable to disable

Make scripts windows compatible ie core count for make, paths etc
Add mise tool option to download prebuilt binaries (off by default, useful for ci/cd)
<!-- [tools]
llvm = { version = '21', prebuilt = true } -->

5. Security Considerations
- Downloads tarballs over HTTPS (good)
- No checksum verification after download
Recommendation: Add SHA256 verification against LLVM's release signatures.

7. Platform Incomplete
- Windows support is acknowledged as broken (TODO mentions this)
- Linux/macOS only, but platform detection could be more explicit

Future Improvements
1. Add prebuilt opt out binary option (as in TODO):
-- In tool config
["clang"] = {
    prebuilt = true,  -- Download from releases instead of building
    project = "clang",
    bin = "clang"
}

3. Add parallel build config: Let users control parallelism:
[tools]
llvm = { version = "21", build_cores = 4 }
- No memory limits specified (LLVM builds require 8-16GB RAM for parallel builds)

4. Improve exec_env: Set more than just PATH (e.g., LLVM_DIR, CLANG_PATH)

5. Add spdx license detection: For compiler-rt libraries that have different licenses

6. Consider incremental builds: Currently full rebuilds every time; could check if source changed

better docs & settings & complete TODOs

Fix bazel bug where settings get auto added even if local mise isn't using bazel (but global is?)