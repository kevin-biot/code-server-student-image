#!/bin/bash
# generate-student-handouts.sh - Create individual credential cards for students

set -e

CREDS_FILE="${1:-student-credentials.txt}"

if [[ ! -f "$CREDS_FILE" ]]; then
    echo "Error: Credentials file not found: $CREDS_FILE"
    echo "Usage: $0 [credentials-file]"
    exit 1
fi

HANDOUTS_DIR="student-handouts"
mkdir -p "$HANDOUTS_DIR"

echo "🎓 Generating individual student handout cards..."

# Skip header lines and process each student
tail -n +6 "$CREDS_FILE" | while IFS='|' read -r student code_url code_pass console_url console_pass; do
    # Trim whitespace
    student=$(echo "$student" | xargs)
    code_url=$(echo "$code_url" | xargs)
    code_pass=$(echo "$code_pass" | xargs)
    console_url=$(echo "$console_url" | xargs)
    console_pass=$(echo "$console_pass" | xargs)
    
    if [[ -n "$student" ]]; then
        cat > "$HANDOUTS_DIR/${student}-credentials.txt" << EOF
┌─────────────────────────────────────────────────────┐
│                 DevOps Workshop                     │
│              Student Credentials                    │
└─────────────────────────────────────────────────────┘

Student: $student

🖥️  Development Environment (Code-Server)
   URL:      $code_url
   Password: $code_pass

$(if [[ -n "$console_url" && "$console_url" != "https://console-openshift-console." ]]; then
cat << EOL
🔧 OpenShift Console & Tekton Dashboard
   Username: $student
   Password: $console_pass
   
   🌐 Console:  $console_url
   📊 Pipelines: ${console_url/console-openshift-console/tekton-dashboard}

EOL
fi)

📚 Workshop Structure:
   Day 1: Infrastructure as Code (Pulumi)
   Day 2: CI/CD Pipelines (Tekton)  
   Day 3: GitOps (ArgoCD)

🚀 Getting Started:
   1. Open your development environment URL
   2. Enter your Code-Server password
   3. Read STUDENT-QUICK-START.md
   4. Start with Day 1 labs in labs/day1-pulumi/

💡 Tips:
   - Use Terminal → New Terminal for command line
   - All tools pre-installed (oc, kubectl, pulumi, etc.)
   - Your work is persistent across sessions
   - Ask for help anytime!

──────────────────────────────────────────────────────
Generated: $(date)
EOF
        echo "✅ Created handout: $HANDOUTS_DIR/${student}-credentials.txt"
    fi
done

# Create instructor summary
cat > "$HANDOUTS_DIR/instructor-summary.txt" << EOF
# DevOps Workshop - Instructor Summary
Generated: $(date)

## Quick Commands
\`\`\`bash
# Monitor all students
./monitor-students.sh

# Test specific student
./test-deployment.sh <student-name>

# Check build status
oc get buildruns -n devops

# Student pod status
oc get pods -A -l app=code-server
\`\`\`

## Student URLs Pattern
- Code-Server: https://<student>-code-server.apps-crc.testing
- Console: https://console-openshift-console.apps-crc.testing

## Troubleshooting
- Pods not starting: Check \`oc get events -n <student>\`
- Route not accessible: Check /etc/hosts for CRC entries
- Build failures: Check \`oc logs -f buildrun/<name> -n devops\`

## Files Generated
$(ls -la "$HANDOUTS_DIR"/*.txt | wc -l) credential cards created in $HANDOUTS_DIR/
EOF

echo ""
echo "🎉 Handouts generated in $HANDOUTS_DIR/"
echo "📝 Individual cards: $(ls "$HANDOUTS_DIR"/*-credentials.txt 2>/dev/null | wc -l)"
echo "📋 Instructor summary: $HANDOUTS_DIR/instructor-summary.txt"
echo ""
echo "💡 You can print these cards or email them to students!"
