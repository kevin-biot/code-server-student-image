#!/bin/bash
set -e
# test-base-image.sh - Verify the base image builds and core tools work
# Usage: ./tests/test-base-image.sh [image-name]
#
# If no image name given, builds from Dockerfile first.
# Tests: build succeeds, container starts, health endpoint responds, core tools present.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IMAGE="${1:-training-platform-base:test}"
CONTAINER_NAME="test-base-image-$$"

PASS=0
FAIL=0

pass() { ((PASS++)); echo "  PASS: $1"; }
fail() { ((FAIL++)); echo "  FAIL: $1"; }

cleanup() {
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
}
trap cleanup EXIT

echo "Base Image Test Suite"
echo "====================="

# Build if no image specified
if [ -z "$1" ]; then
    echo ""
    echo "--- Building base image ---"
    if docker build -t "$IMAGE" "$REPO_ROOT" > /dev/null 2>&1; then
        pass "docker build succeeds"
    else
        fail "docker build FAILED"
        echo "Run manually: docker build -t $IMAGE $REPO_ROOT"
        exit 1
    fi
fi

# Start container
echo ""
echo "--- Starting container ---"
docker run -d --name "$CONTAINER_NAME" \
    -e PASSWORD=testpass \
    -e STUDENT_NAMESPACE=test-student \
    -p 18080:8080 \
    "$IMAGE" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    pass "container starts"
else
    fail "container failed to start"
    exit 1
fi

# Wait for startup
echo "  Waiting for code-server to start..."
sleep 10

# Health check
echo ""
echo "--- Health checks ---"
if curl -sf http://localhost:18080/healthz > /dev/null 2>&1; then
    pass "health endpoint responds"
else
    # Try a few more times
    for i in 1 2 3; do
        sleep 5
        if curl -sf http://localhost:18080/healthz > /dev/null 2>&1; then
            pass "health endpoint responds (attempt $((i+1)))"
            break
        fi
    done
    if ! curl -sf http://localhost:18080/healthz > /dev/null 2>&1; then
        fail "health endpoint not responding after 25s"
    fi
fi

# Core tools check
echo ""
echo "--- Core tools ---"
TOOLS="git vim nano curl wget jq yq tree htop bash"
for tool in $TOOLS; do
    if docker exec "$CONTAINER_NAME" which "$tool" > /dev/null 2>&1; then
        pass "$tool is installed"
    else
        fail "$tool is NOT installed"
    fi
done

# Directory structure
echo ""
echo "--- Directory structure ---"
DIRS="/home/coder/workspace /home/coder/startup.d /opt/tool-packs/bin"
for dir in $DIRS; do
    if docker exec "$CONTAINER_NAME" test -d "$dir" 2>/dev/null; then
        pass "$dir exists"
    else
        fail "$dir missing"
    fi
done

# Startup script
echo ""
echo "--- Startup configuration ---"
if docker exec "$CONTAINER_NAME" test -x /home/coder/startup.sh 2>/dev/null; then
    pass "startup.sh is executable"
else
    fail "startup.sh is not executable"
fi

if docker exec "$CONTAINER_NAME" test -f /home/coder/.gitconfig-template 2>/dev/null; then
    pass "gitconfig-template exists"
else
    fail "gitconfig-template missing"
fi

# PATH includes tool-packs
if docker exec "$CONTAINER_NAME" bash -c 'echo $PATH' 2>/dev/null | grep -q "/opt/tool-packs/bin"; then
    pass "PATH includes /opt/tool-packs/bin"
else
    fail "PATH does not include /opt/tool-packs/bin"
fi

echo ""
echo "=== Results ==="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
    echo ""
    echo "FAILED: $FAIL test(s) failed"
    echo ""
    echo "Container logs:"
    docker logs "$CONTAINER_NAME" 2>&1 | tail -20
    exit 1
else
    echo ""
    echo "ALL PASSED"
fi
