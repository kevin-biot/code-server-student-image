# Tool pack: java (OpenJDK 17, Maven, Gradle)
# Copies JDK and build tools into shared volume with symlinked binaries
FROM eclipse-temurin:17-jdk-jammy AS builder

RUN apt-get update && apt-get install -y maven gradle && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /tools/bin /tools/java && \
    cp -a /opt/java/openjdk /tools/java/jdk && \
    cp -a /usr/share/maven /tools/java/maven && \
    cp -a /usr/share/gradle /tools/java/gradle && \
    \
    # Create wrapper scripts that set JAVA_HOME
    printf '#!/bin/sh\nexport JAVA_HOME=/opt/tool-packs/java/jdk\nexec /opt/tool-packs/java/jdk/bin/java "$@"\n' > /tools/bin/java && \
    printf '#!/bin/sh\nexport JAVA_HOME=/opt/tool-packs/java/jdk\nexec /opt/tool-packs/java/jdk/bin/javac "$@"\n' > /tools/bin/javac && \
    printf '#!/bin/sh\nexport JAVA_HOME=/opt/tool-packs/java/jdk\nexport M2_HOME=/opt/tool-packs/java/maven\nexec /opt/tool-packs/java/maven/bin/mvn "$@"\n' > /tools/bin/mvn && \
    printf '#!/bin/sh\nexport JAVA_HOME=/opt/tool-packs/java/jdk\nexport GRADLE_HOME=/opt/tool-packs/java/gradle\nexec /opt/tool-packs/java/gradle/bin/gradle "$@"\n' > /tools/bin/gradle && \
    chmod +x /tools/bin/*

COPY copy-tools.sh /tools/copy-tools.sh
RUN chmod +x /tools/copy-tools.sh

FROM busybox:stable
COPY --from=builder /tools /tools
ENTRYPOINT ["/tools/copy-tools.sh"]
