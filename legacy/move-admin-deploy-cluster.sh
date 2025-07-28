#!/bin/bash
# move-admin-deploy-cluster.sh - Safely move admin deployment scripts and fix path dependencies

set -e

echo "🚀 Moving Admin Deployment Cluster"
echo "=================================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're in the right directory
if [[ ! -f "complete-student-setup-simple.sh" ]] || [[ ! -d "admin" ]]; then
    print_error "Please run this script from the code-server-student-image directory"
    print_error "Expected: complete-student-setup-simple.sh and admin/ directory"
    exit 1
fi

print_step "Step 1: Backup original files"
mkdir -p .backup-$(date +%Y%m%d-%H%M%S)
cp complete-student-setup-simple.sh .backup-*/
cp deploy-bulk-students.sh .backup-*/
cp deploy-students.sh .backup-*/
cp configure-argocd-rbac.sh .backup-*/
cp student-template.yaml .backup-*/
cp simple-git-push.sh .backup-*/
print_success "Backup created in .backup-* directory"

print_step "Step 2: Create path-fixed versions of scripts"

# Fix complete-student-setup-simple.sh paths
print_step "Fixing paths in complete-student-setup-simple.sh"
sed 's|./deploy-bulk-students.sh|./admin/deploy/deploy-bulk-students.sh|g' complete-student-setup-simple.sh | \
sed 's|./configure-argocd-rbac.sh|./admin/deploy/configure-argocd-rbac.sh|g' > complete-student-setup-simple.sh.tmp

# Show the changes being made
echo "📝 Path changes in complete-student-setup-simple.sh:"
echo "   ./deploy-bulk-students.sh → ./admin/deploy/deploy-bulk-students.sh"
echo "   ./configure-argocd-rbac.sh → ./admin/deploy/configure-argocd-rbac.sh"

# Fix deploy-bulk-students.sh template path
print_step "Fixing paths in deploy-bulk-students.sh"
sed 's|student-template.yaml|../student-template.yaml|g' deploy-bulk-students.sh > deploy-bulk-students.sh.tmp

echo "📝 Path changes in deploy-bulk-students.sh:"
echo "   student-template.yaml → ../student-template.yaml"

# Fix deploy-students.sh template path (if it references the template)
print_step "Checking deploy-students.sh for template references"
if grep -q "student-template.yaml" deploy-students.sh; then
    sed 's|student-template.yaml|../student-template.yaml|g' deploy-students.sh > deploy-students.sh.tmp
    echo "📝 Path changes in deploy-students.sh:"
    echo "   student-template.yaml → ../student-template.yaml"
else
    cp deploy-students.sh deploy-students.sh.tmp
    echo "📝 No template path changes needed in deploy-students.sh"
fi

# No path changes needed for configure-argocd-rbac.sh (doesn't reference files)
cp configure-argocd-rbac.sh configure-argocd-rbac.sh.tmp
echo "📝 No path changes needed in configure-argocd-rbac.sh"

print_step "Step 3: Move files to admin/deploy/ directory"

# Move the fixed scripts
mv complete-student-setup-simple.sh.tmp admin/deploy/complete-student-setup-simple.sh
mv deploy-bulk-students.sh.tmp admin/deploy/deploy-bulk-students.sh  
mv deploy-students.sh.tmp admin/deploy/deploy-students.sh
mv configure-argocd-rbac.sh.tmp admin/deploy/configure-argocd-rbac.sh

# Copy student-template.yaml to admin/ (shared by deploy scripts)
cp student-template.yaml admin/
print_success "Moved student-template.yaml to admin/ (shared resource)"

# Set executable permissions
chmod +x admin/deploy/*.sh
print_success "Set executable permissions on moved scripts"

print_step "Step 4: Archive one-off scripts to legacy/"
mv simple-git-push.sh legacy/simple-git-push-oneoff.sh
print_success "Archived simple-git-push.sh to legacy/ (one-off optimization script)"

print_step "Step 5: Create workflow entry point in root"
cat > admin-deploy.sh << 'EOF'
#!/bin/bash
# admin-deploy.sh - Entry point for admin deployment workflow

echo "🚀 Admin Deployment Workflow"
echo "==========================="
echo ""

case "${1:-help}" in
    "setup")
        if [[ -n "$2" ]] && [[ -n "$3" ]]; then
            echo "📋 Running complete student setup for students $2 to $3"
            ./admin/deploy/complete-student-setup-simple.sh "$2" "$3"
        else
            echo "Usage: $0 setup <start_num> <end_num>"
            echo "Example: $0 setup 1 25"
        fi
        ;;
    "bulk")
        if [[ -n "$2" ]] && [[ -n "$3" ]]; then
            echo "📋 Running bulk deployment for students $2 to $3"
            ./admin/deploy/deploy-bulk-students.sh "$2" "$3"
        else
            echo "Usage: $0 bulk <start_num> <end_num>"
            echo "Example: $0 bulk 1 5"
        fi
        ;;
    "deploy")
        if [[ -n "$2" ]] && [[ -n "$3" ]]; then
            echo "📋 Running individual deployment for students $2 to $3"
            ./admin/deploy/deploy-students.sh "$2" "$3"
        else
            echo "Usage: $0 deploy <start_num> <end_num>"
            echo "Example: $0 deploy 1 10"
        fi
        ;;
    "rbac")
        if [[ -n "$2" ]] && [[ -n "$3" ]]; then
            echo "📋 Configuring ArgoCD RBAC for students $2 to $3"
            ./admin/deploy/configure-argocd-rbac.sh "$2" "$3"
        else
            echo "Usage: $0 rbac <start_num> <end_num>"
            echo "Example: $0 rbac 1 37"
        fi
        ;;
    "help"|*)
        echo "Admin Deployment Commands:"
        echo ""
        echo "  setup <start> <end>   Complete student setup (main deployment)"
        echo "  bulk <start> <end>    Bulk deployment only"
        echo "  deploy <start> <end>  Individual deployment"
        echo "  rbac <start> <end>    Configure ArgoCD RBAC"
        echo ""
        echo "Most common usage:"
        echo "  $0 setup 1 25         # Full bootcamp setup"
        echo "  $0 setup 1 5          # Test environment"
        echo ""
        echo "Scripts location: ./admin/deploy/"
        echo "Template location: ./admin/student-template.yaml"
        ;;
esac
EOF

chmod +x admin-deploy.sh
print_success "Created admin-deploy.sh entry point in root directory"

print_step "Step 6: Clean up root directory"
# Remove original files that have been moved
rm -f complete-student-setup-simple.sh deploy-bulk-students.sh deploy-students.sh configure-argocd-rbac.sh
print_success "Removed original files from root (now in admin/deploy/)"

print_step "Step 7: Validation"
echo ""
echo "📂 New structure:"
echo "   admin/"
echo "   ├── student-template.yaml      (shared template)"
echo "   └── deploy/"
echo "       ├── complete-student-setup-simple.sh"
echo "       ├── deploy-bulk-students.sh"
echo "       ├── deploy-students.sh"
echo "       └── configure-argocd-rbac.sh"
echo ""
echo "   legacy/"
echo "   └── simple-git-push-oneoff.sh   (archived one-off script)"
echo ""
echo "   Root entry point:"
echo "   └── admin-deploy.sh             (workflow entry point)"

echo ""
print_step "Step 8: Testing path fixes"
echo "🔍 Checking that path references are correct..."

# Check the fixed paths
if grep -q "./admin/deploy/deploy-bulk-students.sh" admin/deploy/complete-student-setup-simple.sh; then
    print_success "✅ complete-student-setup-simple.sh paths updated correctly"
else
    print_error "❌ Path fix failed in complete-student-setup-simple.sh"
fi

if grep -q "../student-template.yaml" admin/deploy/deploy-bulk-students.sh; then
    print_success "✅ deploy-bulk-students.sh template path updated correctly"
else
    print_error "❌ Template path fix failed in deploy-bulk-students.sh"
fi

echo ""
print_success "🎉 Admin deployment cluster successfully moved and organized!"
echo ""
echo "📋 Next steps:"
echo "1. Test the new structure:"
echo "   ./admin-deploy.sh help"
echo "   ./admin-deploy.sh setup 1 3    # Test with 3 students"
echo ""
echo "2. Verify scripts work:"
echo "   cd admin/deploy"
echo "   ls -la"
echo "   head -5 complete-student-setup-simple.sh"
echo ""
echo "3. If everything works, we can move the next batch!"
echo ""
echo "💾 Backup available in: .backup-* directory"
echo "🔄 To rollback: copy files from .backup-* back to root"
