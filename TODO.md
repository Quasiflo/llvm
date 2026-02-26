Make scripts windows compatible ie core count for make, paths etc
Add mise tool option to download prebuilt binaries (off by default, useful for ci/cd)
<!-- [tools]
llvm = { version = '21', prebuilt = true } -->
Fix bazel bug where settings get auto added even if local mise isn't using bazel (but global is?)
Standardise formatter