{
  busybox = (builtins.storePath /nix/store/k1shvg0ng6s4fypx2fsv425dhycmwddz-stdenv-bootstrap-tools-aarch64-unknown-linux-musl) + "/on-server/busybox";
  bootstrapTools = (builtins.storePath /nix/store/k1shvg0ng6s4fypx2fsv425dhycmwddz-stdenv-bootstrap-tools-aarch64-unknown-linux-musl) + "/on-server/bootstrap-tools.tar.xz";
}
