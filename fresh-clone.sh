#!/bin/bash
# fresh-clone.sh - Clean setup for IaC workshop

set -e

echo "🧹 Setting up fresh IaC repository clone..."

# Save current student namespace if it exists
if [[ -n "$STUDENT_NAMESPACE" ]]; then
    echo "💾 Preserving STUDENT_NAMESPACE: $STUDENT_NAMESPACE"
    SAVED_STUDENT_NS="$STUDENT_NAMESPACE"
else
    echo "🔍 Detecting student namespace from environment..."
    SAVED_STUDENT_NS=$(echo $HOSTNAME | sed 's/code-server.*//' | sed 's/.*-//' | head -c 10)
    if [[ -z "$SAVED_STUDENT_NS" ]]; then
        SAVED_STUDENT_NS="student01"
    fi
    echo "🎯 Using detected namespace: $SAVED_STUDENT_NS"
fi

# Move to labs directory
cd ~/workspace/labs

# Remove existing day1-pulumi directory if it exists
if [[ -d "day1-pulumi" ]]; then
    echo "🗑️  Removing existing day1-pulumi directory..."
    rm -rf day1-pulumi
fi

# Fresh clone
echo "📥 Cloning fresh copy from GitHub..."
git clone https://github.com/kevin-biot/IaC.git day1-pulumi

# Move into the directory
cd day1-pulumi

echo "📋 Repository contents:"
ls -la

# Install Node.js dependencies (including Pulumi SDK)
echo "📦 Installing Node.js dependencies..."
npm install

# Restore Pulumi configuration
echo "⚙️  Setting up Pulumi configuration..."

# Initialize Pulumi if needed
if [[ ! -f "Pulumi.dev.yaml" ]]; then
    echo "🔧 Initializing Pulumi..."
    pulumi login --local
    pulumi stack init dev || pulumi stack select dev
fi

# Set configuration
echo "🎛️  Configuring Pulumi..."
pulumi config set studentNamespace "$SAVED_STUDENT_NS"
pulumi config set --secret dbPassword "MySecurePassword123"

# Export student namespace for current session
export STUDENT_NAMESPACE="$SAVED_STUDENT_NS"
echo "export STUDENT_NAMESPACE=$SAVED_STUDENT_NS" >> ~/.bashrc

echo "📊 Current Pulumi configuration:"
pulumi config

# Test that everything works
echo "🧪 Testing Pulumi preview..."
if pulumi preview; then
    echo "✅ Pulumi preview successful!"
    echo ""
    echo "🎯 Ready for deployment!"
    echo "📋 Next steps:"
    echo "   1. Run: pulumi up"
    echo "   2. Monitor: oc get buildruns -n $SAVED_STUDENT_NS -w"
    echo "   3. Check route: oc get route -n $SAVED_STUDENT_NS"
else
    echo "❌ Pulumi preview failed. Check the errors above."
    exit 1
fi

echo ""
echo "🏁 Fresh setup complete!"
echo "🎓 Student namespace: $SAVED_STUDENT_NS"
echo "📂 Working directory: $(pwd)"
