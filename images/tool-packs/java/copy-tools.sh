#!/bin/sh
# Init container: copy Java runtime and build tools to shared volume
echo "[tool-pack:java] Copying JDK 17, Maven, Gradle..."
cp -a /tools/java /opt/tool-packs/java
cp /tools/bin/* /opt/tool-packs/bin/
echo "[tool-pack:java] Done."
