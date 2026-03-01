# Admin Workflow

Administrative operations for DevOps bootcamp student environments.

## 🚀 Quick Start

### Unified Admin Interface
Use the main workflow script for all admin operations:

```bash
# Make executable (first time only)
chmod +x admin-workflow.sh

# Deploy students
./admin-workflow.sh deploy 1 5          # Test environment (5 students)
./admin-workflow.sh deploy 1 25         # Full bootcamp (25 students)

# Validate deployment
./admin-workflow.sh validate framework  # 518-test framework
./admin-workflow.sh validate full       # Comprehensive validation

# Monitor and manage
./admin-workflow.sh status              # Quick status dashboard
./admin-workflow.sh manage monitor      # Detailed monitoring
./admin-workflow.sh manage teardown     # Cleanup environments
```

### Help and Documentation
```bash
./admin-workflow.sh                     # Show all available commands
./admin-workflow.sh help                # Same as above
```

## 📁 Directory Structure

- **deploy/** - Scripts to provision and setup student environments
  - `complete-student-setup-simple.sh` - **THE KEY TESTED DEPLOY SCRIPT**
  - `configure-argocd-rbac.sh` - ArgoCD access configuration
  - `deploy-bulk-students.sh` - Bulk environment deployment
  
- **manage/** - Environment management, monitoring, and teardown operations
  - `monitor-students.sh` - Real-time environment monitoring
  - `teardown-students.sh` - Safe environment cleanup
  - `scale.sh` - Pod scaling operations
  
- **validate/** - Testing and validation scripts for deployed environments
  - `codeserver_test_framework.sh` - 518-test validation framework
  - `comprehensive-validation.sh` - Complete environment validation
  - `end-to-end-test.sh` - Integration testing

## 🎯 Common Workflows

### Production Bootcamp Deployment
```bash
# 1. Deploy all students
./admin-workflow.sh deploy 1 25

# 2. Validate deployment
./admin-workflow.sh validate framework

# 3. Monitor during bootcamp
./admin-workflow.sh manage monitor
```

### Development Testing
```bash
# 1. Deploy test environment
./admin-workflow.sh deploy 1 3

# 2. Quick validation
./admin-workflow.sh validate quick

# 3. Cleanup after testing
./admin-workflow.sh manage teardown 1 3
```

### Troubleshooting
```bash
# Status check
./admin-workflow.sh status

# Detailed monitoring
./admin-workflow.sh manage monitor

# Scale down for maintenance
./admin-workflow.sh manage scale 0

# Scale back up
./admin-workflow.sh manage scale 1
```
