#!/bin/bash
# move-logs-to-logs-dir.sh - Move all log files to logs/ directory

set -e

echo "🧹 Moving log files to logs/ directory..."
echo "========================================"

# Move all test reports
echo "📊 Moving test reports..."
mv codeserver_test_report_*.txt logs/ 2>/dev/null || echo "   No test reports to move"

# Move all validation logs  
echo "📋 Moving validation logs..."
mv codeserver_validation_*.log logs/ 2>/dev/null || echo "   No validation logs to move"

# Move build logs
echo "🏗️  Moving build logs..."
mv build-*.log logs/ 2>/dev/null || echo "   No build logs to move"

# Move backup files
echo "💾 Moving backup files..."
mv *.backup logs/ 2>/dev/null || echo "   No backup files to move"

# Move empty artifact files
echo "🗑️  Moving artifact files..."
mv main logs/ 2>/dev/null || echo "   No artifact files to move"

# Move temp validation script
echo "🧪 Moving temporary validation script..."
mv dob74-validation.sh logs/ 2>/dev/null || echo "   No temp validation script to move"

echo ""
echo "✅ Log file cleanup completed!"
echo ""
echo "📂 Files moved to logs/ directory:"
ls -la logs/

echo ""
echo "🧹 Root directory is now much cleaner!"
echo "📋 Next step: Analyze log patterns and create subdirectory structure"
