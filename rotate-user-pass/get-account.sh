#!/bin/bash

# Set variables
accounts=/root/URL-management/scripts/rotate-user-pass/accounts
tmpsqlchange=/root/URL-management/scripts/rotate-user-pass/tmp_sql-change-url
tmpsqlgetuserpass=/root/URL-management/scripts/rotate-user-pass/tmp_sql-get-current_user-pass_USER1
sqlgetuseractivity=/root/URL-management/scripts/rotate-user-pass/SQL_get-last-1-min
logs=/root/URL-management/scripts/rotate-user-pass/log
checkbgchannelnumb=294044

processcheck=""
processcheck=$(ps -ef | grep -v grep | grep get-account.sh |wc -l)
if [[ "$processcheck" -gt "2" ]]; then
  echo "The same process already running. Goodbye!"
  exit 0
fi

countaccounts=$(wc -l $accounts |cut -f 1 -d " ")
if [[ $countaccounts -gt 10 ]]
  then
    echo ">>> The counter (now there is $countaccounts) for accounts are good!"
  else
    echo ">>> Send notification via Telegram"
    curl -kX POST "https://api.telegram.org/bot5155869***:AAH1q0PT7SMA57NQr05p8LCB945G4GpB***/sendMessage" -d "chat_id=1494035***&text=Check list of accounts on server%0A-> The list of accounts are $countaccounts!"
    yes |cp -f /root/URL-management/scripts/rotate-user-pass/accounts_bkp $accounts
fi

# Get username and password from DB for configured short links and import it on indexed key/value array with name "channels"
declare -A srvcredentials

while IFS='' read -r line ; do
    srvusername=""
    srvpassword=""
    srvusername=$(echo $line|cut -f 2 -d'='|sed 's/&password//g')
    srvpassword=$(echo $line|cut -f 3 -d'='|sed 's/&type//g')
    srvurl=$(echo $line|cut -f 1 -d'?'|sed 's/\/get.php//g')
    srvcredentials["$srvusername"]="$srvpassword"
done < $accounts
# Check for local activity. If there is interruption for less than 1 min go to next steps, if no exit from execution
getlocaluserstatus=$(mysql -N < $sqlgetuseractivity)
[[ -z "$getlocaluserstatus" ]] && { echo "No local user activity. Goodbye!"; exit 0; }

for KEY in "${!srvcredentials[@]}"; do
    srvurl=""
    getaccountstatus=""
    srvurl=$(grep $KEY $accounts |cut -f 1 -d'?'|sed 's/http:\/\/\|\/get.php//g')
    # Print the KEY value
    echo "_____________________________________________"
    echo "check user: $KEY => ${srvcredentials[$KEY]}"
    getaccountstatus=$(curl -s -H "Accept: application/json" "http://$srvurl/player_api.php?username=$KEY&password=${srvcredentials[$KEY]}&type=m3u_plus"|jq -r '.user_info.active_cons')
    if [[ "$getaccountstatus" == "0" ]]; then
            ffprobe -hide_banner -v panic -select_streams a:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1 http://$srvurl/$KEY/${srvcredentials[$KEY]}/$checkbgchannelnumb |grep -q bit_rate
            if [ $? -eq 0 ]
             then
              echo ">>> there is BG channel"
             else
              echo ">>> skip this user, no bg channels"
              unset 'srvcredentials[$KEY]'
	      sleep 4
	      continue
            fi
            echo "use yourls;" > $tmpsqlgetuserpass
            echo "select url from yourls_url where url like \"http://$srvurl%\" and keyword like \"ugr%\";" >> $tmpsqlgetuserpass
            dbfindstring=$(mysql -N < $tmpsqlgetuserpass |cut -f -5 -d'/'|head -n 1)
            echo "use yourls;" > $tmpsqlchange
            echo "update yourls_url set url = REPLACE(url,\"$dbfindstring/\",\"http://$srvurl/$KEY/${srvcredentials[$KEY]}/\");" >> $tmpsqlchange
            echo "select keyword,url,title from yourls_url where url like \"%$KEY%\";" >> $tmpsqlchange
            mysql -N < $tmpsqlchange
            unset 'srvcredentials[$KEY]'
            rm -f $tmpsqlgetuserpass
            rm -f $tmpsqlchange
            break
        elif [[ "$getaccountstatus" -gt "0" ]]; then
            unset 'srvcredentials[$KEY]'
            echo "SAFE sleep 4 sec user is watching TV, skipp..."
            sleep 4
        else
            unset 'srvcredentials[$KEY]'
            echo "SAFE sleep 4 sec invalid user"
            sed -i "/$KEY/d" $accounts
            sleep 4
    fi
done
echo "_____________________________________________"
