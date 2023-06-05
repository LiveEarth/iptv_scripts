#!/bin/bash
# Set variable
getdate=$(date +%Y-%m-%d)
gettime=$(date +%H:%M:%S)
sqlcleanstat=/root/URL-management/scripts/clean_stats/SQL_clean_stat

mysql --table < $sqlcleanstat

echo "Done at: $getdate on $gettime"
