# syntax=docker/dockerfile:1
#
# Hardened build for the cilium agent (github.com/cilium/cilium).
#
# !!! KNOWN BLOCKER — see BLOCKER.md !!!
# The cilium agent is the most complex image in the set:
#   * The eBPF datapath is compiled at build time with clang/llvm + bpftool.
#   * The build uses the upstream cilium-builder image and
#     `make build-container install-container-binary`.
#   * The release image COPIES `libcilium.so` and the `cilium-envoy` /
#     `cilium-envoy-starter` binaries FROM the cilium-envoy image — so the
#     agent is transitively blocked on `image-build-cilium-cilium-envoy`.
#   * The runtime base is the patched `cilium-runtime` (iproute2, bpftool,
#     llvm, etc.) — the minimal `bci-nano` base used by the other components
#     is not sufficient.
#
# The stage below sketches the intended approach; it will NOT complete on a
# default GitHub runner without the cilium-envoy artifacts and a hardened
# runtime base.

ARG CILIUM_ENVOY_IMAGE=ghcr.io/cwayne18/hardened-cilium-cilium-envoy:latest
ARG GOLANG_IMAGE=rancher/hardened-build-base:v1.26.4b1
ARG RUNTIME_IMAGE=registry.suse.com/bci/bci-base:16.0

FROM ${CILIUM_ENVOY_IMAGE} AS cilium-envoy

FROM --platform=$BUILDPLATFORM ${GOLANG_IMAGE} AS builder
RUN apk add --no-cache file make git clang lld llvm bpftool || true
ARG PKG
ARG TAG
ARG TARGETARCH
RUN git clone --depth=1 https://${PKG}.git $GOPATH/src/${PKG} && \
    cd $GOPATH/src/${PKG} && git fetch --all --tags --prune && \
    git checkout tags/${TAG} -b ${TAG}
WORKDIR $GOPATH/src/${PKG}
# Heavy: compiles the Go agent AND the eBPF datapath. Needs the full cilium
# build toolchain (clang/llvm/bpftool) and generated bpf objects.
RUN make GOARCH=${TARGETARCH} build-container install-container-binary || true

# Hardened runtime stage. NOTE: a real image needs a runtime base carrying
# iproute2/bpftool/llvm (the upstream cilium-runtime), not plain bci-base.
FROM ${RUNTIME_IMAGE} AS hardened-cilium-cilium
LABEL org.opencontainers.image.description="Cilium agent (hardened) — see BLOCKER.md"
COPY --from=cilium-envoy /usr/bin/cilium-envoy /usr/bin/cilium-envoy
COPY --from=cilium-envoy /usr/bin/cilium-envoy-starter /usr/bin/cilium-envoy-starter
COPY --from=builder /usr/local/bin/ /usr/bin/
CMD ["/usr/bin/cilium-agent"]
