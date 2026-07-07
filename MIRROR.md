# ⚠️ MIRRORED UPSTREAM IMAGE (not yet source-hardened)

The published `ghcr.io/cwayne18/hardened-cilium-cilium` image is currently a
**manifest-preserving mirror of the upstream image**, produced by
[`.github/workflows/mirror.yml`](./.github/workflows/mirror.yml):

| | |
|---|---|
| **Source** | `quay.io/cilium/cilium:v1.19.4` |
| **Target** | `ghcr.io/cwayne18/hardened-cilium-cilium:v1.19.4` |
| **Method** | `docker buildx imagetools create` (preserves the full multi-arch manifest: `linux/amd64` + `linux/arm64`) |

## Why this is a mirror, not a from-source hardened build

The Cilium agent's eBPF datapath needs the full clang/llvm/bpftool toolchain and a
`cilium-runtime` base, and its release image **copies artifacts from the cilium-envoy image**
— so it is transitively blocked on the (Bazel, non-CI-buildable) cilium-envoy build
(see [BLOCKER.md](./BLOCKER.md)). Per maintainer decision, the image is mirrored from
upstream so the `rke2-cilium` PRIME chart can resolve it under `ghcr.io/cwayne18`, pending a
real source-hardened build.

## What this means

- The bits are **identical to upstream** `quay.io/cilium/cilium` — no additional
  hardening, minimization, or FIPS/BoringCrypto rebuild has been applied yet.
- The `Dockerfile`, `Makefile`, and `release.yml` in this repo describe the eventual
  **from-source** hardened build; they are not what currently publishes the image.
- Nothing here pushes to Docker Hub — GHCR only.

To re-run the mirror: **Actions → Mirror upstream image → Run workflow**.
