#!/bin/bash
# Efficient log cleanup script

echo "🧹 Moving remaining log files to logs/ directory..."

cd /Users/kevinbrown/code-server-student-image

# Move all remaining test reports
for file in codeserver_test_report_*.txt; do
    if [ -f "$file" ]; then
        echo "📊 Moving $file"
        mv "$file" logs/
    fi
done

# Move all remaining validation logs
for file in codeserver_validation_*.log; do
    if [ -f "$file" ]; then
        echo "📋 Moving $file"
        mv "$file" logs/
    fi
done

echo ""
echo "✅ Batch move completed!"
echo ""
echo "📂 Current logs/ directory contents:"
ls -la logs/ | head -20
echo ""
echo "📊 Total files in logs/:"
ls -1 logs/ | wc -l
