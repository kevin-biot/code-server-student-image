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
