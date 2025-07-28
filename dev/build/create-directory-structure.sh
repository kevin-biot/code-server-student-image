#!/bin/bash
# create-directory-structure.sh - Create organized directory structure (no file moves)

set -e

echo "🏗️  Creating organized directory structure..."
echo "====================================="
echo ""

# Create the main workflow directories
echo "📁 Creating admin workflow directories..."
mkdir -p admin/deploy
mkdir -p admin/manage  
mkdir -p admin/validate

echo "📁 Creating dev workflow directories..."
mkdir -p dev/build
mkdir -p dev/fix
mkdir -p dev/test

echo "📁 Creating shared resource directories..."
mkdir -p shared/templates
mkdir -p shared/configs
mkdir -p shared/utils

echo "📁 Creating logs directory..."
mkdir -p logs

echo ""
echo "📝 Creating README files with purpose statements..."

# Admin READMEs
cat > admin/README.md << 'EOF'
# Admin Workflow

Administrative operations for DevOps bootcamp student environments.

## Directories

- **deploy/** - Scripts to provision and setup student environments
- **manage/** - Environment management, monitoring, and teardown operations  
- **validate/** - Testing and validation scripts for deployed environments
EOF

cat > admin/deploy/README.md << 'EOF'
# Admin Deploy

Scripts to provision and setup student environments for DevOps bootcamp workshops.
EOF

cat > admin/manage/README.md << 'EOF'
# Admin Manage

Environment management, monitoring, and teardown operations for student environments.
EOF

cat > admin/validate/README.md << 'EOF'
# Admin Validate

Testing and validation scripts to ensure deployed student environments are working correctly.
EOF

# Dev READMEs
cat > dev/README.md << 'EOF'
# Developer Workflow

Development tools for building, testing, and debugging the code-server student image.

## Directories

- **build/** - Build and image creation scripts
- **fix/** - Debug and issue resolution tools
- **test/** - Developer testing and validation scripts
EOF

cat > dev/build/README.md << 'EOF'
# Dev Build

Build and image creation scripts for the code-server student environment container.
EOF

cat > dev/fix/README.md << 'EOF'
# Dev Fix

Debug and issue resolution tools for troubleshooting development and deployment problems.
EOF

cat > dev/test/README.md << 'EOF'
# Dev Test

Developer testing and validation scripts for rapid development feedback loops.
EOF

# Shared READMEs
cat > shared/README.md << 'EOF'
# Shared Resources

Common resources used across admin and developer workflows.

## Directories

- **templates/** - Reusable configuration templates and startup scripts
- **configs/** - Configuration files and credential templates
- **utils/** - Utility scripts used by multiple workflows
EOF

cat > shared/templates/README.md << 'EOF'
# Shared Templates

Reusable configuration templates and startup scripts used across workflows.
EOF

cat > shared/configs/README.md << 'EOF'
# Shared Configs

Configuration files, credential templates, and environment settings.
EOF

cat > shared/utils/README.md << 'EOF'
# Shared Utils

Utility scripts used by multiple workflows (git operations, repository setup, etc.).
EOF

# Logs README
cat > logs/README.md << 'EOF'
# Logs Directory

Archived test reports, validation logs, and build outputs. 

**Note**: This directory should be gitignored to prevent log file accumulation in the repository.
EOF

echo ""
echo "✅ Directory structure created successfully!"
echo ""
echo "📂 New structure:"
echo "admin/{deploy,manage,validate}/"
echo "dev/{build,fix,test}/"  
echo "shared/{templates,configs,utils}/"
echo "logs/"

echo ""
echo "📋 Next steps:"
echo "1. Review the created directories: tree admin/ dev/ shared/ logs/"
echo "2. Check README files: find {admin,dev,shared,logs} -name README.md"
echo "3. Then we'll review what scripts should go in each directory"

echo ""
echo "🎯 No files have been moved yet - structure only"
