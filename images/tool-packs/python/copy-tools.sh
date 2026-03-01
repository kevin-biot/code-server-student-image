#!/bin/sh
# Init container: copy Python runtime to shared volume
echo "[tool-pack:python] Copying Python 3.12, pip..."
cp -a /tools/python /opt/tool-packs/python
cp /tools/bin/* /opt/tool-packs/bin/
echo "[tool-pack:python] Done."
