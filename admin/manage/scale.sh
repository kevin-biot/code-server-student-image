# OpenShift Admin Scale Utility (Monkey-Proof Edition)

This utility safely scales student pods and worker nodes for night/weekend cost-saving and restores them for weekday usage.

✅ Enforces the **critical order of operations** to avoid cluster disruptions:  
- 🔻 Scale-Down: Pods first → Nodes second  
- 🔼 Scale-Up: Nodes first → Pods second (slowly)  
✅ Includes built-in checkpoints and delays to prevent hasty admin errors.  
✅ Designed for junior admins to run without breaking the cluster.  
✅ Logs all actions for audit and troubleshooting.  

---

## 🚀 How to Use

### 1️⃣ Run the script:
    bash admin-scale.sh

---

### 2️⃣ Choose an action:
| Option | Description                                   |
|--------|-----------------------------------------------|
| 1      | 🔻 Scale down for NIGHT/WEEKEND               |
| 2      | 🔼 Scale up in the MORNING                    |
| 3      | 🩺 Run Cluster HEALTH CHECK only              |
| 4      | ❌ Exit                                       |

---

### 3️⃣ Follow on-screen prompts:

✅ **When scaling down**, the script will:  
- Scale down all `student` pods (except test namespaces like `student01`, `student02`).  
- Introduce a **delay** to allow PVC detach and SDN cleanup.  
- Prompt you to manually scale worker nodes to 2 via AWS/OpenShift console.  
- Verify all pods are cleaned up before proceeding.  

✅ **When scaling up**, the script will:  
- Prompt you to manually scale worker nodes **back to 6** in AWS/OpenShift console.  
- Scale up student pods **slowly** with delays between each namespace.  

✅ **When running a health check**, the script will:  
- Display cluster health and recommend monitoring commands.

---

## 📦 AWS/OpenShift Node Scaling

When the script prompts:  

### 🔻 Night/Weekend Scale-Down
1. Go to **AWS Console > EC2 Auto Scaling Groups** (or OpenShift MachineSets).  
2. Find your worker pool (e.g., `worker-pool-abc123`).  
3. Scale desired capacity from `6 → 2`.  
4. Wait until `oc get nodes` shows only 2 worker nodes in **Ready** state.  

### 🔼 Morning Scale-Up
1. Scale desired capacity from `2 → 6`.  
2. Wait until all 6 worker nodes are **Ready**.  
3. Confirm in the script when prompted.

---

## 👀 Monitoring Commands

Run these in a separate terminal to monitor progress:  

- Cluster health:  
      oc get co

- Nodes:  
      oc get nodes

- Pods (all namespaces):  
      oc get pods --all-namespaces

- Watch pod state live:  
      watch -n5 'oc get pods -A'

- Check for terminating pods:  
      oc get pods --all-namespaces | grep Terminating

- Check worker distribution:  
      oc get pods -o wide

---

## 📂 Logs

All actions are logged to:  
    /tmp/admin-scale.log

---

## ⚠️ Critical Notes

- **NEVER reverse the order**:  
  - Scale pods down **before** scaling nodes down.  
  - Scale nodes up **before** scaling pods up.  

- PVC detach/attach can take time — be patient during delays.  
- The script will refuse to proceed unless you confirm worker node scaling at the checkpoint.  

---

## 🛡 Design Notes

This script was built to:  
✔ Protect the cluster from operator error.  
✔ Avoid API server or SDN overload during scale operations.  
✔ Allow even junior admins to execute the procedure confidently.
