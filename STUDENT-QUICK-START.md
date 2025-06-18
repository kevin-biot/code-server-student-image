# 🚀 Student Quick Start Guide - Code Server Environment

## Welcome to Your Cloud Development Environment!

You have been provided with a **complete development environment** that runs in your web browser. **No laptop setup required!** Everything you need for this DevOps workshop is pre-installed and ready to use.

---

## 🌐 **Step 1: Access Your Environment**

### Your Personal Development Environment
- **URL**: `https://studentXX-code-server.apps.cluster.domain` (provided by instructor)
- **Password**: `your-unique-password` (provided by instructor)

### First Login
1. **Open your web browser** (Chrome, Firefox, Safari, Edge - any modern browser works)
2. **Navigate to your URL** (bookmark this!)
3. **Enter your password** when prompted
4. **You're in!** You should see a VS Code interface in your browser

> 💡 **Tip**: Keep your URL and password handy - you'll use them throughout the workshop

---

## 🖥️ **Step 2: Understanding Your Interface**

Your code-server environment looks and works exactly like **Visual Studio Code**, but runs in your browser!

### Key Interface Elements

```
┌─────────────────────────────────────────────────────────────────┐
│ [☰] File Edit View Terminal Help           🔍 Search    ⚙️ Settings│
├─────────────────────────────────────────────────────────────────┤
│ 📁 Explorer  🔍 Search  📦 Extensions  🐛 Debug  🔗 Remote     │
├─────────────────┬───────────────────────────────────────────────┤
│ 📂 workspace/   │                                               │
│ ├── 📁 labs/    │                                               │
│ ├── 📁 projects/│           📝 EDITOR AREA                     │
│ ├── 📁 examples/│                                               │
│ └── 📄 README.md│                                               │
├─────────────────┼───────────────────────────────────────────────┤
│                 │                                               │
│                 │          💻 TERMINAL AREA                    │
│                 │          (Opens here when needed)            │
└─────────────────┴───────────────────────────────────────────────┘
```

### Essential Areas
- **📁 File Explorer** (left sidebar): Navigate files and folders
- **📝 Editor Area** (center): Write and edit code
- **💻 Terminal Area** (bottom): Command line interface
- **🔍 Search** (Ctrl+Shift+F): Find files and text
- **📦 Extensions** (left sidebar): Pre-installed development tools

---

## 💻 **Step 3: Opening and Using the Terminal**

The terminal is your command-line interface - essential for DevOps work!

### How to Open Terminal
1. **Menu Method**: Click `Terminal` → `New Terminal`
2. **Keyboard Shortcut**: Press `Ctrl+Shift+`` (backtick key)
3. **Command Palette**: Press `Ctrl+Shift+P`, type "terminal", select "Terminal: Create New Terminal"

### Your Terminal Environment
Once opened, you'll see:
```bash
coder@code-server-xxxxx:~/workspace$ 
```

This is your command prompt! You can now run commands.

### Essential Terminal Commands for Beginners
```bash
# See where you are
pwd

# List files and folders
ls

# List files with details
ls -la

# Change directory
cd labs/day1-pulumi

# Go back to parent directory
cd ..

# Go back to home workspace
cd ~/workspace

# Clear the terminal screen
clear

# View file contents
cat README.md

# Get help for any command
oc --help
kubectl --help
```

---

## 🛠️ **Step 4: Pre-installed Tools Overview**

Your environment comes with **everything pre-installed**. No setup needed!

### DevOps & Cloud Tools
- **`oc`** - OpenShift command line
- **`kubectl`** - Kubernetes command line  
- **`tkn`** - Tekton pipelines
- **`pulumi`** - Infrastructure as Code
- **`argocd`** - GitOps workflows
- **`helm`** - Package manager

### Development Languages
- **`java`** - Java development
- **`mvn`** - Maven build tool
- **`python3`** - Python programming
- **`node`** - Node.js runtime
- **`npm`** - Node package manager

### Utilities
- **`git`** - Version control
- **`curl`** - HTTP requests
- **`jq`** - JSON processor
- **`yq`** - YAML processor

### Test Your Tools
Run this in your terminal to verify everything works:
```bash
# Test each tool
echo "Testing tools..."
oc version --client
kubectl version --client
pulumi version
java -version
python3 --version
node --version
git --version
echo "✅ All tools ready!"
```

---

## 📁 **Step 5: Workshop Structure Tour**

Let's explore your workspace organization:

### Navigate Your Workspace
```bash
# Start in your workspace
cd ~/workspace

# See the overall structure
ls -la

# Explore each area
ls labs/          # Workshop exercises
ls projects/      # Your work area
ls examples/      # Reference materials
ls templates/     # Starter code
```

### Workshop Directory Structure
```
workspace/
├── 📄 README.md              # Welcome guide (start here!)
├── 📁 labs/                  # Daily workshop exercises
│   ├── 📁 day1-pulumi/       # Day 1: Infrastructure as Code
│   ├── 📁 day2-tekton/       # Day 2: CI/CD Pipelines  
│   └── 📁 day3-gitops/       # Day 3: GitOps with ArgoCD
├── 📁 projects/              # Your development projects
├── 📁 examples/              # Sample code and references
└── 📁 templates/             # Workshop starter templates
```

### Read the Welcome Guide
```bash
# Open the main README in VS Code
# Click on README.md in the file explorer
# OR open in terminal:
cat README.md
```

---

## ⌨️ **Step 6: Essential Keyboard Shortcuts**

Master these shortcuts to work efficiently:

### File Operations
- **`Ctrl+N`** - New file
- **`Ctrl+O`** - Open file
- **`Ctrl+S`** - Save file
- **`Ctrl+Shift+P`** - Command palette (most important!)

### Editor Navigation
- **`Ctrl+F`** - Find in current file
- **`Ctrl+Shift+F`** - Find in all files
- **`Ctrl+G`** - Go to line number
- **`Ctrl+\`** - Split editor

### Terminal Operations
- **`Ctrl+Shift+``** - New terminal
- **`Ctrl+C`** - Stop running command
- **`Up Arrow`** - Previous command
- **`Tab`** - Auto-complete command

### Multi-cursor Editing
- **`Alt+Click`** - Add cursor at position
- **`Ctrl+D`** - Select next occurrence
- **`Ctrl+Shift+L`** - Select all occurrences

---

## 🚀 **Step 7: Your First DevOps Commands**

Let's run some real DevOps commands to get started!

### Check Your OpenShift Access
```bash
# See who you are in the cluster
oc whoami

# See your assigned namespace/project
oc project

# List all your permissions
oc auth can-i --list
```

### Explore Kubernetes
```bash
# List pods in your namespace
oc get pods

# See all resources
oc get all

# Describe your namespace
oc describe namespace $(oc project -q)
```

### Test Infrastructure Tools
```bash
# Check Pulumi setup
pulumi whoami

# List Tekton resources
tkn pipeline list

# Test Helm
helm version
```

---

## 🎯 **Step 8: Workshop-Specific Getting Started**

### Day 1: Pulumi Infrastructure Setup
```bash
# Navigate to Day 1 exercises
cd ~/workspace/labs/day1-pulumi

# Install dependencies
npm install

# Initialize your stack
pulumi stack init dev

# Set your namespace
pulumi config set student-infrastructure:namespace $(oc project -q)

# Ready to start Day 1!
```

### Day 2: Tekton Pipelines
```bash
# Navigate to Day 2 exercises  
cd ~/workspace/labs/day2-tekton

# Explore the pipeline structure
ls -la

# Check available pipelines
tkn pipeline list
```

### Day 3: ArgoCD GitOps
```bash
# Navigate to Day 3 exercises
cd ~/workspace/labs/day3-gitops

# Check ArgoCD connection
argocd version --client

# List applications
argocd app list
```

---

## 💡 **Pro Tips for Success**

### File Management
- **Always save your work**: `Ctrl+S` frequently
- **Use the file explorer**: Click folders to navigate
- **Create new files**: Right-click in explorer → "New File"
- **Multiple tabs**: Open multiple files for comparison

### Terminal Tips
- **Multiple terminals**: Open several terminals for different tasks
- **Copy/paste**: Use `Ctrl+C` and `Ctrl+V` (context matters!)
- **Command history**: Use ↑/↓ arrows to repeat commands
- **Tab completion**: Type first few letters, press Tab

### Working with Code
- **Syntax highlighting**: Automatic for all languages
- **Auto-completion**: Press `Ctrl+Space` for suggestions
- **Format code**: `Shift+Alt+F` to auto-format
- **Find references**: `F12` to go to definition

### Collaboration
- **Share URLs**: Your environment persists between sessions
- **Ask for help**: Instructors can see your screen when needed
- **Work together**: Each student has isolated environment

---

## 🆘 **Getting Help**

### If Something Doesn't Work

1. **Check the terminal for error messages**
   ```bash
   # Look for red text or "Error:" messages
   ```

2. **Restart a stuck terminal**
   - Close terminal tab (click X)
   - Open new terminal: `Ctrl+Shift+``

3. **Reload your browser**
   - Press `F5` or `Ctrl+R`
   - You won't lose your work!

4. **Check your connection**
   ```bash
   # Test OpenShift connection
   oc whoami
   
   # If not working, contact instructor
   ```

### Common Issues & Solutions

**Problem**: Terminal won't open
- **Solution**: Try `View` → `Terminal` from menu

**Problem**: Commands not found
- **Solution**: Refresh browser, all tools are pre-installed

**Problem**: Can't see files
- **Solution**: Click the Explorer icon (📁) in left sidebar

**Problem**: Forgot password
- **Solution**: Ask instructor - they have your credentials

**Problem**: Browser feels slow
- **Solution**: Close unused tabs, use Incognito/Private mode

---

## 🎓 **You're Ready to Start!**

Congratulations! You now have:
- ✅ Access to your personal cloud development environment
- ✅ Understanding of the VS Code interface
- ✅ Terminal skills for running commands
- ✅ Knowledge of pre-installed tools
- ✅ Workshop directory navigation
- ✅ Essential keyboard shortcuts

### Next Steps
1. **Bookmark your environment URL**
2. **Read the main workspace README.md**
3. **Start with Day 1 exercises in `labs/day1-pulumi/`**
4. **Ask questions when you need help!**

---

## 📚 **Quick Reference Card**

### Essential Shortcuts
| Action | Shortcut |
|--------|----------|
| New Terminal | `Ctrl+Shift+`` |
| Command Palette | `Ctrl+Shift+P` |
| Save File | `Ctrl+S` |
| Find in Files | `Ctrl+Shift+F` |
| Split Editor | `Ctrl+\` |

### Key Commands
| Tool | Check Version | Main Usage |
|------|---------------|------------|
| OpenShift | `oc version` | `oc get pods` |
| Kubernetes | `kubectl version` | `kubectl get all` |
| Pulumi | `pulumi version` | `pulumi up` |
| Tekton | `tkn version` | `tkn pipeline list` |
| Git | `git --version` | `git status` |

### Workshop Navigation
| Location | Command |
|----------|---------|
| Home | `cd ~/workspace` |
| Day 1 | `cd ~/workspace/labs/day1-pulumi` |
| Day 2 | `cd ~/workspace/labs/day2-tekton` |
| Day 3 | `cd ~/workspace/labs/day3-gitops` |
| Projects | `cd ~/workspace/projects` |

**Happy coding! 🚀**
