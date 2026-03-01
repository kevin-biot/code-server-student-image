# Tool pack: python (Python 3, pip, venv)
# Copies Python runtime into shared volume with wrapper scripts
FROM python:3.12-slim AS builder

RUN mkdir -p /tools/bin /tools/python && \
    cp -a /usr/local/bin/python3 /tools/python/ && \
    cp -a /usr/local/lib/python3.12 /tools/python/lib && \
    cp -a /usr/local/bin/pip3 /tools/python/ && \
    \
    # Create wrapper scripts
    printf '#!/bin/sh\nexport PYTHONHOME=/opt/tool-packs/python\nexec /opt/tool-packs/python/python3 "$@"\n' > /tools/bin/python3 && \
    printf '#!/bin/sh\nexec /opt/tool-packs/bin/python3 -m pip "$@"\n' > /tools/bin/pip3 && \
    printf '#!/bin/sh\nexec /opt/tool-packs/bin/python3 -m pip "$@"\n' > /tools/bin/pip && \
    printf '#!/bin/sh\nexec /opt/tool-packs/bin/python3 "$@"\n' > /tools/bin/python && \
    chmod +x /tools/bin/*

COPY copy-tools.sh /tools/copy-tools.sh
RUN chmod +x /tools/copy-tools.sh

FROM busybox:stable
COPY --from=builder /tools /tools
ENTRYPOINT ["/tools/copy-tools.sh"]
