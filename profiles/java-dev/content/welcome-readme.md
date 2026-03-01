# Java Development Environment

Welcome to your Java development workspace! This environment includes everything you need for Java application development on Kubernetes.

## Pre-installed Tools

### Languages & Runtimes
- Java 17 (OpenJDK) with Maven and Gradle
- Build tools for all major patterns

### Cloud Native
- OpenShift CLI (`oc`) - Platform management
- Kubernetes CLI (`kubectl`) - Container orchestration
- Helm - Package management
- Tekton CLI (`tkn`) - Pipeline operations
- ArgoCD CLI - GitOps workflows

### Development Tools
- VS Code with Java extensions
- Git with completion
- JSON/YAML processors (jq, yq)

## Directory Structure

```
workspace/
├── projects/              # Your application code
├── labs/                  # Lab exercises
└── examples/
    ├── java/              # Java code samples
    └── kubernetes/        # K8s manifest examples
```

## Quick Start

```bash
# Verify Java
java -version
mvn -version

# Create a new Spring Boot project
cd ~/workspace/projects
mvn archetype:generate -DgroupId=com.example -DartifactId=myapp \
    -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false

# Build and run
cd myapp
mvn package
java -jar target/myapp-1.0-SNAPSHOT.jar
```

## Need Help?

- Use `Terminal > New Terminal` for command line access
- All CLI tools support `--help`
- Check `examples/` for reference code
