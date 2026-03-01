# Legacy Scripts and Historical Content

This directory contains historical scripts, experimental code, and deprecated tools that have been superseded by the organized admin workflow system.

## 📁 Directory Structure

### Main Legacy Collection

**Authentication & Debug Scripts:**
- `debug-htpasswd-issues*.sh` - HTPasswd debugging evolution (3 versions)
- `debug-user-creation.sh` - User creation diagnostics
- `diagnose-oauth.sh` - OAuth troubleshooting
- `users.htpasswd` - Authentication artifacts

**Setup Script Evolution:**
- `complete-student-setup-fixed.sh` - Enhanced student setup (superseded)
- `complete-student-setup-simple-fixed.sh` - Minimal setup variant (superseded)
- `course-setup.sh` - Instructor cluster setup (archived)

**Deployment & Infrastructure:**
- `fresh-clone.sh` - Clean IaC setup with Pulumi (one-time utility)
- `urgent-deploy.sh` - Emergency deployment (superseded by admin workflow)
- `install-workshop-infrastructure.sh` - Infrastructure setup

**Git & Pipeline Operations:**
- `git-push*.sh` - Various git operation scripts
- `run-pipeline-legacy.sh` - Legacy pipeline execution
- `start-pipeline-legacy.sh` - Legacy pipeline triggers

**Deprecated Scripts:**
- `update-and-restart-codeserver-DEPRECATED.sh` - **DO NOT USE** (production issues)
- `omprehensive-pipeline-monitoring-typo.sh` - Duplicate file (typo in name)

**YAML Manifests:**
- `code-server-*.yaml` - Deployment, service, route manifests
- `student-template.yaml` - Legacy student template
- `htpasswd-oauth.yaml` - Authentication configuration

### 📂 Subdirectories

#### `development/` - Development Experiments
Development iterations and enhanced script variants:
- `complete-student-setup.sh` - Original setup approach
- `deploy-bulk-students-robust.sh` - Enhanced deployment with error handling
- `phase1-technical-setup.sh` - Structured testing approach
- `preflight-tool-check-*.sh` - Multiple tool validation variants
- `create-student-users*.sh` - User creation experiments

#### `rbac-experiments/` - Security Model Development
RBAC configuration experiments and GitOps security:
- `argocd-rbac-addition.yaml` - ArgoCD RBAC experiments
- `argocd-serviceaccount-rbac.yaml` - Service account configurations
- `openshift-gitops-rbac.yaml` - GitOps RBAC configurations

#### `testing/` - Historical Testing Approaches
Testing methodologies and validation frameworks:
- `test-student-experience.sh` - Comprehensive end-to-end testing
- `monitor-25-student-deployment.sh` - Large-scale monitoring
- `cluster-capacity-check.sh` - Resource validation
- `test-terminal-access.sh` - Terminal connectivity testing
- `quick-cluster-check.sh` - Fast health validation

#### `tmp-htpasswd/` - Authentication Artifacts
Temporary authentication files and debugging artifacts.

## 📚 Historical Documentation

**Project Planning:**
- `critical-path-plan.md` - Strategic project planning insights
- `staff-testing-plan.md` - Testing methodology and approach
- `two-phase-testing-plan.md` - Risk mitigation deployment strategy

**Staff Resources:**
- `staff-testing-feedback-form.md` - Testing feedback collection

## 🔄 Replacement Information

### Superseded Scripts
These legacy scripts have been replaced by the organized admin workflow:

| Legacy Script | Replacement | Location |
|---------------|-------------|----------|
| `urgent-deploy.sh` | `admin-workflow.sh deploy` | `admin/admin-workflow.sh` |
| `update-and-restart-codeserver.sh` | `admin-workflow.sh manage restart` | `admin/admin-workflow.sh` |
| `course-setup.sh` | Manual instructor setup | Documentation |
| Various monitoring scripts | `admin-workflow.sh manage monitor` | `admin/admin-workflow.sh` |

### Deprecated Features
- **Mixed build+restart operations** - Now separated into build phase + restart phase
- **Basic restart logic** - Replaced with enhanced batch processing and PVC lock detection
- **Individual script execution** - Unified under admin workflow interface

## 🎯 Usage Guidelines

### When to Reference Legacy Content

**For Historical Context:**
- Understanding evolution of deployment approaches
- Learning from testing methodologies
- RBAC configuration patterns
- Troubleshooting approaches that worked

**For Reuse Patterns:**
- Authentication debugging techniques (`debug-htpasswd-issues-final.sh`)
- Testing framework approaches (`test-student-experience.sh`)
- RBAC configuration examples (`rbac-experiments/`)
- Infrastructure setup patterns (`install-workshop-infrastructure.sh`)

### What NOT to Use

**Deprecated Scripts:**
- `update-and-restart-codeserver-DEPRECATED.sh` - Contains production issue warnings
- `omprehensive-pipeline-monitoring-typo.sh` - Duplicate file with typo

**Superseded Approaches:**
- Individual script execution instead of admin workflow
- Mixed build+restart operations
- Basic restart without batch processing

## 🔧 Maintenance Notes

### File Organization
- **All valuable content preserved** - Nothing lost during reorganization
- **Clear categorization** - Scripts grouped by purpose and development phase
- **Historical progression** - Multiple versions show evolution and lessons learned

### Tekton v1 Compatibility
- **Status**: ✅ No v1beta1 API references found in legacy directory
- **Result**: No breaking compatibility issues with current Tekton v1 deployment

### Quality Assessment
The legacy directory demonstrates:
- **Mature development practices** - Progressive refinement and testing
- **Comprehensive documentation** - Excellent project planning and methodology
- **Security awareness** - RBAC experimentation and security model development
- **Operational wisdom** - Testing frameworks and validation approaches

## 🚀 Current Status

**Legacy directory serves as:**
- **Institutional knowledge repository** - Preserves 2+ months of development evolution
- **Reference library** - Patterns and approaches for future development
- **Historical archive** - Complete audit trail of project development
- **Troubleshooting resource** - Working solutions for specific problems

**For current operations, use the organized admin workflow system in `/admin/`**
