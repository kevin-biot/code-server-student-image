#!/bin/sh
# Init container: copy Pulumi CLI to shared volume
echo "[tool-pack:iac] Copying Pulumi CLI..."
cp /tools/bin/* /opt/tool-packs/bin/
echo "[tool-pack:iac] Done."
