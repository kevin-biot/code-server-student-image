#!/bin/sh
# Init container: copy Node.js runtime to shared volume
echo "[tool-pack:nodejs] Copying Node.js 20 and npm..."
cp -a /tools/nodejs /opt/tool-packs/nodejs
cp /tools/bin/* /opt/tool-packs/bin/
echo "[tool-pack:nodejs] Done."
