#!/bin/sh
# Init container: copy cloud-native tool binaries to shared volume
echo "[tool-pack:cloud-native] Copying kubectl, oc, helm, argocd, tkn..."
cp /tools/bin/* /opt/tool-packs/bin/
echo "[tool-pack:cloud-native] Done."
