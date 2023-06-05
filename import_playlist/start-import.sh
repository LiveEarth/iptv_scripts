#!/bin/sh
# Set variables
playlist=/root/URL-management/scripts/import_playlist/playlist
dbgetchannels=/root/URL-management/scripts/import_playlist/tmp_db-get-channels
tmpplaylist=/root/URL-management/scripts/import_playlist/tmp_arrays-playlist
sqlgetchannels=/root/URL-management/scripts/import_playlist/SQL_get_channels_USER1
arraychannels=/root/URL-management/scripts/import_playlist/tmp_array-channels
tmpsqlchange=/root/URL-management/scripts/import_playlist/tmp_sql-change-channel
dbbackuplocation=/root/URL-management/scripts/mysql_backup
getdate=$(date +%Y-%m-%d)
gettime=$(date +%H:%M:%S)
sqltimestamp="$getdate $gettime"
datetime="$getdate--$gettime"

# Get channels from playlist and import it on indexed key/value array with name "channels"
cat $playlist |sed '/#EXTM3U/d'|paste -sd ',\n' > $tmpplaylist
declare -A channels

while IFS='' read -r line ; do
    streamurl=""
    channelname=""
    channelname=$(echo $line|cut -d, -f2)
    streamurl=$(echo $line|cut -d, -f3)
    channels["$channelname"]="$streamurl"
done < $tmpplaylist

# Get channels from playlist and import it on indexed key/value array with name "dbchannels"
mysql -N < $sqlgetchannels > $dbgetchannels
declare -A dbchannels

while IFS='' read -r line ; do
    dbstreamurl=""
    dbchannelname=""
    dbchannelname=$(echo $line|cut -f 2- -d' ')
    dbstreamurl=$(echo $line|cut -f 1 -d' ')
    dbchannels["$dbchannelname"]="$dbstreamurl"
done < $dbgetchannels

# Backup database before that action
mysqldump yourls > $dbbackuplocation/backup-DB-$datetime.sql
# Use "mysql db_name < backup-file.sql
# Use "mysql yourls < backup-file.sql"

# Let's go to play :)
while :
do
    clear
    echo ">>> Found [ ${#channels[@]} ] channels in playlist!"
    echo ">>> Found [ ${#dbchannels[@]} ] channels in DB!"
    echo "#######################################"
    echo "# Welcome, choice a option            #"
    echo "#_____________________________________#"
    echo "#  [a]dd  [r]eplace  [q]uit           #"
    echo "#######################################"
    read -rsn1 mainmenu;
    case $mainmenu in
        a) clear
            echo "#######################################"
            echo "# ADD new channel to DB               #"
            echo "#######################################"
            echo "___________________________________________________________[Playlist channels]___"
            for KEY in "${!channels[@]}"; do
                # Print the KEY value
                echo "[$KEY] => ${channels[$KEY]}"
            done
            echo "_________________________________________________________________________________"
            read -p "Enter channel name from playlist: " addchannelname
            read -p "Enter short url [sof/...]: " shorturl
            echo "use yourls;" > $tmpsqlchange
            echo "INSERT INTO yourls_url (keyword,url,title,timestamp,ip,clicks) VALUES (\"sof/$shorturl\",\"${channels[$addchannelname]}\",\"$addchannelname\",\"$sqltimestamp\",\"127.0.0.1\",\"0\");" >> $tmpsqlchange
            echo "select * from yourls_url where title = \"$addchannelname\";" >> $tmpsqlchange
            mysql -N < $tmpsqlchange
            unset 'channels[$addchannelname]'
            rm -f $tmpsqlchange
            sleep 3;;

        r) clear
            for DBKEY in "${!dbchannels[@]}"; do
                clear
                echo "#######################################"
                echo "# REPLACE channel to DB               #"
                echo "#######################################"
                echo "___________________________________________________________[Playlist channels]___"
                for KEY in "${!channels[@]}"; do
                    # Print the KEY value
                    echo "[$KEY] => ${channels[$KEY]}"
                done
                echo "__________________________________________________________[Selected DB channel]___"
                echo ">>> DB channel [ $DBKEY ]"
                echo "======================================="
                echo "Continue [Yy], [Nn] or [*] skip?"
                echo "by press any other key from KB"
                echo "#######################################"
                read -rsn1 yn;
                case $yn in
                    [Yy]* ) read -p "Enter channel name from playlist: " readchannelname
                            echo "use yourls;" > $tmpsqlchange
                            echo "update yourls_url set url = \"${channels[$readchannelname]}\" where title = \"$DBKEY\";" >> $tmpsqlchange
                            echo "select title, url from yourls_url where title = \"$DBKEY\";" >> $tmpsqlchange
                            mysql -N < $tmpsqlchange
                            unset 'channels[$readchannelname]'
                            unset 'dbchannels[$DBKEY]'
                            rm -f $tmpsqlchange
                            sleep 2 ;;
                    [Nn]* ) # Remove temp playlist file
                            rm -f $arraychannels
                            rm -f $dbgetchannels
                            rm -f $tmpplaylist
                            break;;
                    * ) echo "Please answer yes or no, skip DB channel [ $DBKEY ]"
                    sleep 1 ;;
                esac
            done ;;
        q) echo "Quit application. Goodbye!"
           rm -f $arraychannels
           rm -f $dbgetchannels
           rm -f $tmpplaylist
           exit 0 ;;
    esac
done
