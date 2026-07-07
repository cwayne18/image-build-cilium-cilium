# BLOCKER: cilium (agent) needs the full datapath toolchain + cilium-envoy

The cilium agent (upstream: [github.com/cilium/cilium](https://github.com/cilium/cilium),
`v1.19.4`) is the most involved image rke2 mirrors.

## Why it's blocked

1. **eBPF datapath build** — the agent compiles its BPF datapath at build time
   with `clang`/`llvm`/`bpftool`. The upstream build runs inside the
   `cilium-builder` image via `make build-container install-container-binary`.
2. **Depends on cilium-envoy** — the release image copies `libcilium.so`,
   `cilium-envoy` and `cilium-envoy-starter` **from the cilium-envoy image**.
   Since `image-build-cilium-cilium-envoy` is itself blocked (Bazel C++ build,
   see that repo's `BLOCKER.md`), the agent is transitively blocked.
3. **Runtime base** — the agent needs a runtime base carrying `iproute2`
   (cilium-patched), `bpftool`, `llvm` runtime, etc. (the upstream
   `cilium-runtime`). The minimal `bci-nano` base used by the other hardened
   components is not sufficient; a hardened equivalent of `cilium-runtime`
   must be produced first.

## Options to unblock (need a decision)

1. Build a hardened `cilium-builder` + `cilium-runtime` pair (largest effort;
   mirrors what the archived `rancher/image-build-cilium` did via hardening
   patches), then wire the agent build to them.
2. Unblock `cilium-envoy` first (see its BLOCKER.md), then build the agent on a
   large runner with the datapath toolchain.
3. Repackage/mirror the upstream `quay.io/cilium/cilium:v1.19.4` image under
   `ghcr.io/cwayne18` as an interim (not a from-source hardened rebuild).

`build.yml` is `workflow_dispatch`-only so it does not auto-fail on push.
Releases target `ghcr.io/cwayne18` only — never Docker Hub.
