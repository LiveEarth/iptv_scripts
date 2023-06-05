#!/bin/bash
#Set variable
sqlgeturlchannels=/root/URL-management/scripts/check-available-stream/SQL_get_url_channels
tmplist=/root/URL-management/scripts/check-available-stream/tmp_list
#Get channels data from DB
mysql -N < $sqlgeturlchannels > $tmplist
#Set localhost for public visible IP
#publicip=$(nslookup myiptv.exampledns.org | awk -F': ' 'NR==6 { print $2 } ''')
publicip="myiptv.exampledns.org"
#grep -iq $publicip $tmplist
grep -iq "myiptv.exampledns.org" $tmplist
  if [ $? -eq 0 ]
    then
      sed -i "s/$publicip/localhost/g" $tmplist
    else
      echo "" >/dev/null
  fi
#Check yourls web service
echo "-> Checking WEB server"
curl -Is http://localhost:80/admin | grep -q Location
if [ $? -eq 0 ]
  then
    echo ">>> good!"
  else
    echo ">>> Send notification via Telegram"
    curl -kX POST "https://api.telegram.org/bot5155869***:AAH1q0PT7SMA57NQr05p8LCB945G4GpB***/sendMessage" -d "chat_id=1494035***&&text=CHECK WEB server%0A-> Web server is not running!"
    exit 1
fi
# Read the data from tmp_list and check each channel availability. 
while IFS='' read -r line || [[ -n "$line" ]]; do
  streamurl=""
  channelname=""
  channelurl=""
  channelname=$(echo $line|cut -f 2- -d' ')
  streamurl=$(echo $line|cut -f 1 -d' ')
  echo "_____________________________________________________________________________"
  echo "### Test channel $channelname with stream $streamurl ###"
  ffprobe -hide_banner -v panic -select_streams a:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1 $streamurl |grep -q bit_rate
  if [ $? -eq 0 ]
    then
      echo ">>> good"
    else
      echo ">>> Send notification via Telegram"
      curl -kX POST "https://api.telegram.org/bot5155869***:AAH1q0PT7SMA57NQr05p8LCB945G4GpB***/sendMessage" -d "chat_id=1494035***&&text=CHECK STREAM%0A-> Failed channel: $channelname %0A-> Check stream: $streamurl"
  fi
done < $tmplist
# Clean up the temp file
rm -f $tmplist
