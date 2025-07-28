#!/bin/bash

echo "📝 Basic Usage:"
echo "==============="
echo
echo "# Default check (students 1-37, table output):"
echo "./pvc-preflight-check.sh"
echo
echo "# Check specific range (students 1-25):"
echo "./pvc-preflight-check.sh 1 25"
echo
echo "# JSON output for logging:"
echo "./pvc-preflight-check.sh 1 37 json"
echo
echo "# CSV output for analytics:"
echo "./pvc-preflight-check.sh 1 37 csv"
echo

echo "📊 Daily Monitoring Setup:"
echo "=========================="
echo
echo "# Add to crontab for daily 6 AM checks:"
echo "0 6 * * * /path/to/pvc-preflight-check.sh > /var/log/pvc-health-\$(date +%Y%m%d).log 2>&1"
echo
echo "# Weekly trend analysis:"
echo "0 7 * * 1 /path/to/pvc-preflight-check.sh 1 37 csv > /var/log/pvc-weekly-\$(date +%Y%m%d).csv"
echo

echo "🚨 Alerting Setup:"
echo "=================="
echo
echo "# Alert on ghost nodes (exit code 1):"
echo "if ! ./pvc-preflight-check.sh >/dev/null 2>&1; then"
echo "  echo 'Ghost nodes detected!' | mail -s 'PVC Alert' admin@company.com"
echo "fi"
echo

echo "✅ Script is now executable and ready to use!"
