# Java Webapp DevOps Workshop

## Workshop Kickoff Steps

Follow these exact steps in your code-server terminal for the workshop:

```bash
# 1. Navigate to your workshop directory
cd ~/workspace/labs/day2-tekton

# 2. Clone the workshop repository (development branch)
git clone -b dev <instructor-provided-repo-url>

# 3. Enter the project directory
cd devops-workshop

# 4. Make the setup script executable
chmod +x ./setup-student-pipeline.sh

# 5. Run the automated setup script
./setup-student-pipeline.sh
```

## What the Setup Script Does

The setup script will:
1. Prompt for your student namespace (e.g., student01)
2. Ask for Git repository URL (defaults to workshop repo)
3. Render all YAML templates with your namespace
4. Apply infrastructure resources to your namespace
5. Create a rendered directory with your personalized files

## Next Steps After Setup

After running the setup script:
1. Navigate to the rendered directory: `cd rendered_<your-namespace>`
2. Trigger a build: `oc create -f buildrun.yaml -n <your-namespace>`
3. Run the pipeline: `oc apply -f pipeline-run.yaml -n <your-namespace>`

For complete instructions, see the full README in the devops-workshop repository after cloning.
