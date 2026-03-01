# Tool pack: nodejs (Node.js 20, npm)
# Copies Node.js runtime into shared volume with wrapper scripts
FROM node:20-slim AS builder

RUN mkdir -p /tools/bin /tools/nodejs && \
    cp -a /usr/local/bin/node /tools/nodejs/ && \
    cp -a /usr/local/lib/node_modules /tools/nodejs/ && \
    cp -a /usr/local/include/node /tools/nodejs/include 2>/dev/null || true && \
    \
    # Create wrapper scripts
    printf '#!/bin/sh\nexec /opt/tool-packs/nodejs/node "$@"\n' > /tools/bin/node && \
    printf '#!/bin/sh\nexec /opt/tool-packs/nodejs/node /opt/tool-packs/nodejs/node_modules/npm/bin/npm-cli.js "$@"\n' > /tools/bin/npm && \
    printf '#!/bin/sh\nexec /opt/tool-packs/nodejs/node /opt/tool-packs/nodejs/node_modules/npm/bin/npx-cli.js "$@"\n' > /tools/bin/npx && \
    chmod +x /tools/bin/*

COPY copy-tools.sh /tools/copy-tools.sh
RUN chmod +x /tools/copy-tools.sh

FROM busybox:stable
COPY --from=builder /tools /tools
ENTRYPOINT ["/tools/copy-tools.sh"]
