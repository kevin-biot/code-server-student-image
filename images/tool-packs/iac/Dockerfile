# Tool pack: iac (Pulumi CLI)
# Copies Pulumi binary into shared volume
FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /tools/bin && \
    curl -fsSL https://get.pulumi.com | sh && \
    cp /root/.pulumi/bin/pulumi /tools/bin/ && \
    chmod +x /tools/bin/pulumi

COPY copy-tools.sh /tools/copy-tools.sh
RUN chmod +x /tools/copy-tools.sh

FROM busybox:stable
COPY --from=builder /tools /tools
ENTRYPOINT ["/tools/copy-tools.sh"]
