# Quick Start Guide

## Prerequisites
- OpenShift cluster access with `oc` CLI
- Logged in as cluster admin or user with sufficient permissions
- `devops` namespace exists (for building images)

## 1. Build the Image (First Time)

```bash
# Apply the Shipwright build configuration
oc apply -f shipwright/

# Trigger the build
oc create -f shipwright/buildrun.yaml

# Monitor the build (replace xxxxx with actual buildrun name)
oc get buildruns -n devops
oc logs -f buildrun/code-server-student-image-xxxxx -n devops
```

## 2. Deploy Student Environments

### Option A: Using the Script (Recommended)
```bash
# Make scripts executable
chmod +x deploy-students.sh monitor-students.sh

# Deploy 5 students with your cluster domain
./deploy-students.sh -n 5 -d apps.your-cluster-domain.com

# Force redeploy if namespaces already exist
./deploy-students.sh -n 5 -d apps.your-cluster-domain.com --force

# Check deployment status
./monitor-students.sh
```

If a namespace already exists, deployment is skipped unless you use `--force`.

### Option B: Using Make (if you have make installed)
```bash
# Deploy 3 students (default)
make deploy CLUSTER_DOMAIN=apps.your-cluster-domain.com

# Deploy 10 students
make deploy STUDENT_COUNT=10

# Monitor status
make monitor
```

## 3. Access Student Environments

After deployment completes:
1. Check `student-credentials.txt` for URLs and passwords
2. Each student gets: `https://studentXX-code-server.apps.your-cluster-domain.com`
3. Login with the generated password from the credentials file

## 4. Common Operations

```bash
# Check status
./monitor-students.sh

# Deploy specific students
./deploy-students.sh -s alice,bob,charlie -d apps.your-cluster-domain.com

# Clean up all environments
./deploy-students.sh -n 5 --cleanup  # adjust number as needed

# View logs
make logs

# Quick status
oc get pods -A -l app=code-server
```

## 5. Troubleshooting

### Build Issues
```bash
# Check build status
oc get builds -n devops
oc describe build code-server-student-image -n devops
```

### Deployment Issues
```bash
# Check specific student
oc get all -n student01
oc describe pod -n student01
oc logs deployment/code-server -n student01
```

### Route Issues
```bash
# Verify routes
oc get routes -A | grep code-server
```

## 6. Customization

- **Add tools**: Edit `Dockerfile`
- **Change resources**: Modify `student-template.yaml`
- **Customize welcome**: Edit `startup.sh`
- **Add extensions**: Update Dockerfile with additional VS Code extensions

## Next Steps

1. Test with 1-2 students first
2. Verify all tools work as expected
3. Scale up to your full class size
4. Set up regular monitoring and cleanup procedures

## Support

- Check the main README.md for detailed documentation
- Use `make help` for available commands
- Monitor with `./monitor-students.sh`
