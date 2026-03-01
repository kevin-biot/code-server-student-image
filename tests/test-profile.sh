#!/bin/bash
set -e
# test-profile.sh - Validate a training profile
# Usage: ./tests/test-profile.sh [profile-name]
# If no profile given, validates all profiles.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0
WARN=0

pass() { ((PASS++)); echo "  PASS: $1"; }
fail() { ((FAIL++)); echo "  FAIL: $1"; }
warn() { ((WARN++)); echo "  WARN: $1"; }

validate_profile() {
    local profile="$1"
    local profile_dir="$REPO_ROOT/profiles/$profile"
    local overlay_dir="$REPO_ROOT/deploy/overlays/$profile"

    echo ""
    echo "=== Validating profile: $profile ==="

    # 1. profile.yaml exists and is valid YAML
    if [ -f "$profile_dir/profile.yaml" ]; then
        pass "profile.yaml exists"
        if command -v yq &>/dev/null; then
            if yq e '.' "$profile_dir/profile.yaml" > /dev/null 2>&1; then
                pass "profile.yaml is valid YAML"
            else
                fail "profile.yaml is invalid YAML"
            fi

            # Check required fields
            local name
            name=$(yq e '.metadata.name' "$profile_dir/profile.yaml" 2>/dev/null)
            if [ -n "$name" ] && [ "$name" != "null" ]; then
                pass "metadata.name is set: $name"
            else
                fail "metadata.name is missing"
            fi

            local desc
            desc=$(yq e '.metadata.description' "$profile_dir/profile.yaml" 2>/dev/null)
            if [ -n "$desc" ] && [ "$desc" != "null" ]; then
                pass "metadata.description is set"
            else
                fail "metadata.description is missing"
            fi

            # Check tool packs reference valid directories
            local tool_packs
            tool_packs=$(yq e '.spec.toolPacks[]' "$profile_dir/profile.yaml" 2>/dev/null)
            if [ -n "$tool_packs" ]; then
                while IFS= read -r pack; do
                    if [ -d "$REPO_ROOT/images/tool-packs/$pack" ]; then
                        pass "tool-pack '$pack' has Dockerfile"
                    else
                        fail "tool-pack '$pack' referenced but images/tool-packs/$pack/ missing"
                    fi
                done <<< "$tool_packs"
            else
                warn "no toolPacks defined"
            fi
        else
            warn "yq not installed, skipping YAML field validation"
        fi
    else
        fail "profile.yaml missing at $profile_dir/profile.yaml"
    fi

    # 2. Content files exist
    if [ -d "$profile_dir/content" ]; then
        local content_count
        content_count=$(find "$profile_dir/content" -name "*.md" | wc -l | tr -d ' ')
        if [ "$content_count" -gt 0 ]; then
            pass "content directory has $content_count markdown files"
        else
            warn "content directory exists but has no .md files"
        fi
    else
        fail "content/ directory missing"
    fi

    # 3. Startup scripts exist and are executable
    if [ -d "$profile_dir/startup.d" ]; then
        local script_count=0
        for script in "$profile_dir/startup.d"/*.sh; do
            [ -f "$script" ] || continue
            ((script_count++))
            if [ -x "$script" ]; then
                pass "$(basename "$script") is executable"
            else
                fail "$(basename "$script") is NOT executable"
            fi
            # Syntax check
            if bash -n "$script" 2>/dev/null; then
                pass "$(basename "$script") passes syntax check"
            else
                fail "$(basename "$script") has syntax errors"
            fi
        done
        if [ "$script_count" -eq 0 ]; then
            warn "startup.d/ has no .sh scripts"
        fi
    else
        fail "startup.d/ directory missing"
    fi

    # 4. Kustomize overlay exists and builds
    if [ -d "$overlay_dir" ]; then
        pass "Kustomize overlay exists at deploy/overlays/$profile/"
        if [ -f "$overlay_dir/kustomization.yaml" ]; then
            pass "kustomization.yaml exists"
            if command -v kubectl &>/dev/null; then
                if kubectl kustomize "$overlay_dir" > /dev/null 2>&1; then
                    local resource_count
                    resource_count=$(kubectl kustomize "$overlay_dir" | grep -c "^kind:" || echo 0)
                    pass "kustomize build succeeds ($resource_count resources)"
                else
                    fail "kustomize build FAILS"
                fi
            else
                warn "kubectl not installed, skipping kustomize build test"
            fi
        else
            fail "kustomization.yaml missing in overlay"
        fi
    else
        warn "no Kustomize overlay at deploy/overlays/$profile/"
    fi
}

# Main
echo "Training Profile Validator"
echo "========================="

profiles=()
if [ -n "$1" ]; then
    profiles=("$1")
else
    for d in "$REPO_ROOT"/profiles/*/; do
        [ -f "$d/profile.yaml" ] && profiles+=("$(basename "$d")")
    done
fi

if [ ${#profiles[@]} -eq 0 ]; then
    echo "No profiles found in $REPO_ROOT/profiles/"
    exit 1
fi

for profile in "${profiles[@]}"; do
    validate_profile "$profile"
done

echo ""
echo "=== Results ==="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo "  WARN: $WARN"

if [ "$FAIL" -gt 0 ]; then
    echo ""
    echo "FAILED: $FAIL test(s) failed"
    exit 1
else
    echo ""
    echo "ALL PASSED ($PASS tests, $WARN warnings)"
fi
