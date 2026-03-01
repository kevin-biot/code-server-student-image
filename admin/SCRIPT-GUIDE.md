# 📋 Admin Workflow Script Guide

**Complete reference for `admin-workflow.sh` - the unified DevOps bootcamp administration interface.**

## 🎯 Overview

The `admin-workflow.sh` script provides a unified entry point for all administrative operations in the DevOps bootcamp environment. It orchestrates calls to organized scripts in the `deploy/`, `manage/`, and `validate/` subdirectories.

## 🚀 Quick Start

### Make Executable (First Time)
```bash
chmod +x admin-workflow.sh
```

### Basic Usage
```bash
./admin-workflow.sh [command] [subcommand] [arguments...]
./admin-workflow.sh help                    # Show all available commands
```

## 📖 Command Reference

### 🚀 DEPLOY Commands

Deploy and provision student environments.

#### Deploy Students
```bash
./admin-workflow.sh deploy [start_num] [end_num]
```

**Examples:**
```bash
./admin-workflow.sh deploy 1 5          # Deploy 5 students (testing)
./admin-workflow.sh deploy 1 25         # Deploy 25 students (production)
./admin-workflow.sh deploy 10 15        # Deploy students 10-15 only
```

**What it does:**
- Calls `deploy/complete-student-setup-simple.sh` - **THE TESTED WORKING SCRIPT**
- Creates student namespaces with code-server deployments
- Sets up OpenShift user accounts with authentication
- Configures ArgoCD RBAC for GitOps access
- Applies security policies and resource limits

**Requirements:**
- OpenShift cluster admin access
- Shipwright build system installed
- Available cluster resources for student pods

---

### ✅ VALIDATE Commands

Test and validate deployed environments.

#### Comprehensive Validation
```bash
./admin-workflow.sh validate full
```
- Runs complete environment validation suite
- Tests all deployed student environments
- Validates network connectivity and access
- Checks resource quotas and security policies

#### Quick Preflight Checks
```bash
./admin-workflow.sh validate quick
```
- Fast infrastructure validation
- Checks cluster connectivity and permissions
- Validates build system availability
- Architecture-aware (x86_64/arm64) compatibility checks

#### End-to-End Integration Test
```bash
./admin-workflow.sh validate e2e
```
- Complete workflow validation
- Tests deployment → authentication → access → cleanup cycle
- Validates RBAC and OAuth integration
- Security isolation testing

#### 518-Test Framework
```bash
./admin-workflow.sh validate framework
```
- Runs the comprehensive codeserver test framework
- Executes 518 individual validation tests
- Provides detailed pass/fail reporting
- **Target: 100% success rate** (518/518 tests passed)

**Test Categories:**
- Student environment accessibility
- Code-server functionality
- Development tool availability
- Network policies and isolation
- Resource limits and quotas

---

### 🔧 MANAGE Commands

Monitor, scale, and maintain deployed environments.

#### Monitor Student Environments
```bash
./admin-workflow.sh manage monitor
```
- Real-time status dashboard of all student environments
- Resource usage monitoring (CPU, memory, storage)
- Pod status and recent events
- Formatted table output with color coding

#### Smart Restart Operations
```bash
./admin-workflow.sh manage restart              # Smart restart (batch=3)
./admin-workflow.sh manage restart-batch [size] # Custom batch size
```

**Examples:**
```bash
./admin-workflow.sh manage restart             # Default batch=3 (safe)
./admin-workflow.sh manage restart-batch 1     # Ultra-safe (one at a time)
./admin-workflow.sh manage restart-batch 5     # Faster (5 at a time)
```

**Production-Grade Features:**
- **Batch Processing**: Prevents cluster overload (learned from 37+ server issues)
- **PVC Lock Detection**: Fixes ghost node PVC bindings that cause deployment failures  
- **Image Pull Policy**: Forces fresh image pulls (avoids cache issues)
- **Timeout Handling**: 15-minute timeout per deployment, force-delete stuck pods
- **Progress Monitoring**: Real-time status updates during restart process

**Addresses Historical Issues:**
- ✅ **37+ Server Problem**: Batched approach prevents resource contention
- ✅ **PVC Mode Locks**: Detects and cleans ghost node bindings
- ✅ **Stale Image Cache**: Forces fresh pulls with proper imagePullPolicy
- ✅ **Stuck Deployments**: Timeout and force-delete logic for recovery

#### Teardown/Cleanup Environments
```bash
./admin-workflow.sh manage teardown              # Interactive mode
./admin-workflow.sh manage teardown [start] [end] # Specific range
```

**Examples:**
```bash
./admin-workflow.sh manage teardown             # Interactive safety prompts
./admin-workflow.sh manage teardown 1 5         # Remove students 1-5
./admin-workflow.sh manage teardown 10 10       # Remove only student 10
```

**Safety Features:**
- Interactive confirmation for destructive operations
- Clear indication of what will be deleted
- Comprehensive cleanup including namespaces, RBAC, and storage

#### Scale Operations
```bash
./admin-workflow.sh manage scale [replica_count]
```

**Examples:**
```bash
./admin-workflow.sh manage scale 0              # Scale down (maintenance mode)
./admin-workflow.sh manage scale 1              # Scale up (operational mode)
```

**Use Cases:**
- **Scale to 0**: Maintenance, cost reduction, or troubleshooting
- **Scale to 1**: Normal operation for workshops
- **Emergency operations**: Quick response to cluster issues

---

### 📊 STATUS Command

Quick cluster and environment overview.

```bash
./admin-workflow.sh status
```

**Information Provided:**
- **Cluster Status**: Number of deployed students, running pods
- **Build System**: Shipwright configuration status
- **Quick Actions**: Common next steps and commands

**Sample Output:**
```
📊 Admin Status Dashboard
==================================

🏗️  Cluster Status:
   Students deployed: 5
   Running pods: 5

🔧 Build System:
   ✅ Shipwright build config exists

⚡ Quick Actions:
   ./admin-workflow.sh validate quick       # Quick health check
   ./admin-workflow.sh manage monitor       # Detailed monitoring
   ./admin-workflow.sh deploy 1 3          # Deploy test environment
```

---

## 🏗️ Workflow Separation

### **The Three-Phase Approach**

Based on production experience with 37+ code-server deployments, the workflow is separated into distinct phases:

#### **Phase 1: Build (Separate)**
```bash
# Always run image builds separately
./build-and-verify.sh                    # Clean image build
```
**Why Separate?** 
- Build operations can fail independently
- Mixing build + restart caused production issues
- Clean separation allows troubleshooting

#### **Phase 2: Deploy (Fresh Environments)**
```bash
# For new student environments
./admin-workflow.sh deploy 1 25          # Fresh deployment
```

#### **Phase 3: Manage (Existing Environments)**
```bash
# For existing environments needing updates
./admin-workflow.sh manage restart       # Smart restart with all fixes
```

### **⚠️ Deprecated Approach**

The old `update-and-restart-codeserver.sh` mixed build + restart operations, causing:
- Resource contention with 37+ servers
- PVC lock issues (ghost node bindings)
- Image cache problems
- Complex failure scenarios

**✅ Solution:** Clean separation allows each phase to be optimized and troubleshot independently.

## 🎯 Common Workflows

### Production Bootcamp Deployment

**Full 25-student workshop setup:**
```bash
# 1. Pre-flight checks
./admin-workflow.sh validate quick

# 2. Deploy all students
./admin-workflow.sh deploy 1 25

# 3. Comprehensive validation
./admin-workflow.sh validate framework

# 4. Monitor during delivery
./admin-workflow.sh manage monitor
```

### Development Testing

**Small-scale testing and validation:**
```bash
# 1. Deploy test environment
./admin-workflow.sh deploy 1 3

# 2. Quick validation
./admin-workflow.sh validate quick

# 3. Test specific functionality
./admin-workflow.sh validate e2e

# 4. Cleanup after testing
./admin-workflow.sh manage teardown 1 3
```

### Troubleshooting and Maintenance

**Diagnostic and maintenance operations:**
```bash
# Status overview
./admin-workflow.sh status

# Detailed environment monitoring
./admin-workflow.sh manage monitor

# Scale down for maintenance
./admin-workflow.sh manage scale 0

# Comprehensive health check
./admin-workflow.sh validate full

# Scale back up
./admin-workflow.sh manage scale 1
```

### Emergency Response

**Quick incident response:**
```bash
# Immediate status check
./admin-workflow.sh status

# Scale down affected environments
./admin-workflow.sh manage scale 0

# Run diagnostics
./admin-workflow.sh validate quick

# Targeted cleanup if needed
./admin-workflow.sh manage teardown [affected_range]
```

---

## 🏗️ Architecture Integration

### Script Organization

The workflow script integrates with the organized directory structure:

```
admin/
├── admin-workflow.sh           # ← Main unified interface
├── deploy/
│   ├── complete-student-setup-simple.sh  # ← THE KEY WORKING SCRIPT
│   ├── configure-argocd-rbac.sh
│   └── deploy-bulk-students.sh
├── manage/
│   ├── monitor-students.sh
│   ├── teardown-students.sh
│   └── scale.sh
└── validate/
    ├── codeserver_test_framework.sh
    ├── comprehensive-validation.sh
    ├── end-to-end-test.sh
    └── preflight-checks.sh
```

### Dependencies

**Required Infrastructure:**
- OpenShift cluster with admin access
- Shipwright build system
- OpenShift GitOps (ArgoCD)
- Sufficient cluster resources

**Script Dependencies:**
- All subdirectory scripts must be executable
- Proper OpenShift CLI (`oc`) configuration
- Network connectivity to cluster

---

## 🔧 Customization

### Environment Variables

The script respects environment variables set by underlying scripts:

```bash
export CLUSTER_DOMAIN="apps.your-cluster.com"
export SHARED_PASSWORD="YourPassword123!"
export BUILD_TIMEOUT="1200"
```

### Configuration Files

**Student Template**: `deploy/student-template.yaml` (the working template)
**Credentials**: `../shared/configs/student-credentials.txt`
**Build Config**: `../shipwright/build.yaml`

---

## 🧪 Testing and Validation

### Pre-Deployment Testing

Before any student deployment:
```bash
./admin-workflow.sh validate quick          # Infrastructure readiness
./admin-workflow.sh status                  # Current state assessment
```

### Post-Deployment Validation

After student environment setup:
```bash
./admin-workflow.sh validate framework      # Comprehensive testing
./admin-workflow.sh manage monitor          # Real-time monitoring
```

### Continuous Monitoring

During workshop delivery:
```bash
# Regular status checks
watch -n 30 './admin-workflow.sh status'

# Detailed monitoring when needed
./admin-workflow.sh manage monitor
```

---

## 🚨 Error Handling

### Common Issues and Solutions

**1. Permission Errors**
```bash
# Symptom: "Permission denied" or cluster access issues
# Solution: Verify OpenShift login and admin privileges
oc whoami
oc auth can-i '*' '*' --all-namespaces
```

**2. Resource Constraints**
```bash
# Symptom: Pod creation failures or resource limits
# Solution: Check cluster capacity and resource quotas
./admin-workflow.sh status
./admin-workflow.sh manage monitor
```

**3. Build System Issues**
```bash
# Symptom: Image build failures
# Solution: Verify Shipwright installation and configuration
oc get buildconfig -n devops
./admin-workflow.sh validate quick
```

### Script Debugging

**Verbose Output**: Most underlying scripts support verbose modes
**Log Locations**: Check `../logs/` directory for detailed logs
**Manual Execution**: Run individual scripts directly for debugging

---

## 📚 Additional Resources

### Documentation Links
- **Main Admin Guide**: `README.md`
- **Deploy Documentation**: `deploy/README.md`
- **Validation Guide**: `validate/README.md`
- **Management Operations**: `manage/README.md`

### Key Scripts Reference
- **Primary Deploy**: `deploy/complete-student-setup-simple.sh`
- **Monitoring**: `manage/monitor-students.sh`
- **Testing**: `validate/codeserver_test_framework.sh`
- **Status**: Built into this workflow script

### Related Documentation
- **Build System**: `../shipwright/README.md`
- **Student Guide**: `../STUDENT-QUICK-START.md`
- **Project Overview**: `../README.md`

---

## 🎯 Success Metrics

### Deployment Success
- **Target**: 100% student environments successfully deployed
- **Validation**: All students can access their code-server environments
- **Authentication**: OpenShift console and code-server login working

### Testing Success  
- **518-Test Framework**: 100% pass rate (518/518 tests)
- **End-to-End**: Complete workflow validation passes
- **Performance**: Deployment completes within expected timeframes

### Operational Success
- **Monitoring**: Real-time visibility into environment health
- **Scaling**: Smooth scale-up/scale-down operations
- **Cleanup**: Complete environment teardown without orphaned resources

---

**🚀 The admin workflow script provides professional-grade administration capabilities for DevOps bootcamp delivery at scale!**
