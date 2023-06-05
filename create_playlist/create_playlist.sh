#!/bin/bash

# Set variables
sqlcreateplaylist1=/root/URL-management/scripts/create_playlist/SQL_create_playlist_USER1
sqlcreateplaylist2=/root/URL-management/scripts/create_playlist/SQL_create_playlist_USER2
tmpplaylist=/root/URL-management/scripts/create_playlist/tmp_playlist
theplaylist=/root/URL-management/scripts/create_playlist/playlist.m3u

# Check MySQL service availability and read channels for user1
echo "Check MySQL service"
mysql -N < $sqlcreateplaylist1 > $tmpplaylist
  if [ $? -eq 0 ]
    then
      echo ">>> Good!"
    else
      echo ">>> Send notification via Telegram"
      curl -kX POST "https://api.telegram.org/bot5155869***:AAH1q0PT7SMA57NQr05p8LCB945G4GpB***/sendMessage" -d "chat_id=1494035***&&text=CHECK STREAM%0A-> Failed connection to MySQL %0A-> Check mysql service"
  fi

# Prepare playlist
echo "Prepare playlist"
echo "#EXTM3U" > $theplaylist

while IFS='' read -r line || [[ -n "$line" ]]; do
  streamurl=""
  channelname=""
  channelurl=""
  channelname=$(echo $line|cut -f 2- -d' ')
  streamurl=$(echo $line|cut -f 1 -d' ')
  echo "#EXTINF:-1,$channelname" >> $theplaylist
  echo "http://myiptv.exampledns.org/$streamurl" >> $theplaylist
done < $tmpplaylist
rm -f $tmpplaylist
# Read channels from DB for user2
mysql -N < $sqlcreateplaylist2 > $tmpplaylist
while IFS='' read -r line || [[ -n "$line" ]]; do
  streamurl=""
  channelname=""
  channelurl=""
  channelname=$(echo $line|cut -f 2- -d' ')
  streamurl=$(echo $line|cut -f 1 -d' ')
  echo "#EXTINF:-1,UGR-$channelname" >> $theplaylist
  echo "http://myiptv.exampledns.org/$streamurl" >> $theplaylist
done < $tmpplaylist
rm -f $tmpplaylist
# Playlist ready, now copy it to Docker container
echo ">>> Playlist ready, now copy it to Docker container"
docker cp $theplaylist url-management-yourls-1:/var/www/html/
  if [ $? -eq 0 ]
    then
      echo ">>> Done!"
    else
      echo ">>> Send notification via Telegram"
      curl -kX POST "https://api.telegram.org/bot5155869***:AAH1q0PT7SMA57NQr05p8LCB945G4GpB***/sendMessage" -d "chat_id=1494035***&&text=CHECK STREAM%0A-> Failed copy playlist to Docker container %0A-> Check docker container"
  fi
# Set permission for playlist file in docker container
docker exec -u 0 -it url-management-yourls-1 chown www-data:www-data /var/www/html/playlist.m3u
# Clean up temporary playlist
rm -f $theplaylist
