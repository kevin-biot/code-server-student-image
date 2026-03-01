# Tool pack: cloud-native (kubectl, oc, helm, argocd, tkn)
# Used as an init container — copies binaries into shared /opt/tool-packs/bin
FROM debian:bookworm-slim AS builder

ARG TKN_VERSION=0.42.0
ARG ARGOCD_VERSION=2.13.3

RUN apt-get update && apt-get install -y curl wget tar && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN ARCH=$(uname -m) && \
    case "${ARCH}" in x86_64) ARCH=amd64 ;; aarch64) ARCH=arm64 ;; esac && \
    mkdir -p /tools/bin && \
    \
    # kubectl
    curl -fsSL -o /tools/bin/kubectl \
      "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl" && \
    chmod +x /tools/bin/kubectl && \
    \
    # oc (OpenShift CLI)
    mkdir -p /tmp/oc-install && cd /tmp/oc-install && \
    wget -O oc.tar.gz "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz" && \
    tar -xzf oc.tar.gz && cp oc /tools/bin/oc && chmod +x /tools/bin/oc && \
    cd / && rm -rf /tmp/oc-install && \
    \
    # helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | HELM_INSTALL_DIR=/tools/bin bash && \
    \
    # argocd
    curl -fsSL -o /tools/bin/argocd \
      "https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-linux-${ARCH}" && \
    chmod +x /tools/bin/argocd && \
    \
    # tkn (Tekton CLI)
    TKN_ARCH=$(if [ "${ARCH}" = "arm64" ]; then echo "ARM64"; else echo "64bit"; fi) && \
    curl -fsSL -o /tmp/tkn.tar.gz \
      "https://github.com/tektoncd/cli/releases/download/v${TKN_VERSION}/tkn_${TKN_VERSION}_Linux_${TKN_ARCH}.tar.gz" && \
    tar -xzf /tmp/tkn.tar.gz -C /tools/bin tkn && \
    chmod +x /tools/bin/tkn && rm /tmp/tkn.tar.gz

COPY copy-tools.sh /tools/copy-tools.sh
RUN chmod +x /tools/copy-tools.sh

FROM busybox:stable
COPY --from=builder /tools /tools
ENTRYPOINT ["/tools/copy-tools.sh"]
