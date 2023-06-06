*Hello, I am writing this article as an enthusiast and without much experience in iptv. The materials used in the article are borrowed from publicly available resources on the Internet. Use of the resources in this article is for educational purposes only.
Any constructive comments and suggestions regarding the content of this article are welcome!*

### The challenge
Lets imagine that we have an iptv device similar like [this one](https://www.infomir.eu/eng/products/archive/mag-257/ "Infomir MAG 257") and it is located in the grandparents in the village. In the best case, we will paid for iptv subscription and this article will not exist. But things are sometimes not so ideal and a solution to the problem must be sought.
In this article I will share one of probably many answers of question - how we can use static iptv playlist with dynamicly changed channel source into it.

### The BIG picture in my head :)
```
iptv client ---> myiptv.exampledns.org ---> yourls CP ---> iptv stream
^-(1)            ^-(2)                      ^-(3)         ^-(4)
```

(1) The Mag iptv STB make request to static iptv playlist (this playlist will not be changed in future) like this one:

```    #EXTM3U
    #EXTINF:-1,24kitchen
    http://myiptv.exampledns.org/user1/24kitchen
    #EXTINF:-1,Action Box
    http://myiptv.exampledns.org/user1/actionbox
    #EXTINF:-1,AMC
    http://myiptv.exampledns.org/user1/amc
    #EXTINF:-1,BNT1
    http://myiptv.exampledns.org/user2/bnt1
    #EXTINF:-1,BNT2
    http://myiptv.exampledns.org/user2/bnt2
    #EXTINF:-1,BNT3
    http://myiptv.exampledns.org/user2/bnt3
```

(2) Because the VM where is installed yourls Control Pannel have dinamic public ip address association, I use free DDNS services. If public ip adress on the VM will be changed in future I can change it on DDNS control pannel without change the saved iptv playlist on STB device.

(3) Here is our VM where is happen all redirects from client to iptv channel stream.  Later in this article you can found more information.

(4) This is public available (leacked) iptv channels stream.

### The requirement software
1. On Premise or Cloud server
2. docker compose
3. yourls
4. mysql
5. ffprobe

### The steps :)
#### Step 1 - prepare the docker containers
I use this docker compose file to setup the containers
```shell
#version: '3.1'

services:

  yourls:
    image: yourls
    restart: always
    ports:
      - 80:80
    environment:
      YOURLS_DB_USER: yourls-db-username
      YOURLS_DB_PASS: yourls-db-password
      YOURLS_DB_NAME: yourls-db-name
      YOURLS_SITE: http://public-ip:80
      YOURLS_USER: yourls-ui-username
      YOURLS_PASS: yourls-ui-password

  mysql:
    image: mysql
    restart: always
    ports:
      - 3306:3306
    environment:
      MYSQL_ROOT_PASSWORD: db-root-pw
      MYSQL_DATABASE: yourls-db-name
      MYSQL_USER: yourls-db-username
      MYSQL_PASSWORD: yourls-db-password
```
#### Step 2 - configure access to mysql DB
From user where we want to access mysql db without ask for username and password, just create a file named `.my.cnf` with permission `-rw-r--r--` and content like this one:
```
[client]
user=root
password=toor
host=127.0.0.1
port=3306
```
To access container shell you can use this commands:
```
[user@ ~]# docker ps
CONTAINER ID   IMAGE     COMMAND                  CREATED       STATUS       PORTS                                                    NAMES
b44f51607394   yourls    "docker-entrypoint.s…"   6 weeks ago   Up 13 days   0.0.0.0:80->80/tcp, :::80->80/tcp                        url-management-yourls-1
2219a5650b73   mysql     "docker-entrypoint.s…"   8 weeks ago   Up 7 hours   0.0.0.0:3306->3306/tcp, :::3306->3306/tcp                url-management-mysql-1

[user@ ~]# docker exec -it url-management-yourls-1 /bin/bash
or
[user@ ~]# docker exec -it url-management-mysql-1 /bin/bash
```

#### Step 3 - install yourls neccesairy plugins
1. https://github.com/BstName/every-click-counts - To count every request from iptv STB to channel stream.
2. https://github.com/williambargent/YOURLS-Forward-Slash-In-Urls - To allow forward slash in short links. This is usefull when we want to separate different groups in channels. For example http://myiptv.exampledns.org/user1/bnt1 and http://myiptv.exampledns.org/user2/bnt1 .
3. https://github.com/YOURLS/YOURLS/issues/2339#issuecomment-352127623 - To allow more rows on one page in list of short urls.
4. https://github.com/vaughany/yourls-popular-clicks-extended - To get group statictics for channels stream access for different time period (1 day, 7 days, 30 days, 1 year)
5. https://github.com/seandrickson/YOURLS-Remove-the-Share-Function - To remove unused share function for each short link (for channel stream)
6. https://github.com/YOURLS/timezones - If time zone on VM are different from preffered timezone you can use this plugin to correct time on web interface statistics. On DB records the timezone are get from OS (vm configuration)
7. https://github.com/GautamGupta/YOURLS-Import-Export - To be able to export channel list, edit it and import again in DB witout access to DB (from web GUI only)

### The custom scripts

#### check-available-stream
As the name of the script suggest, here the task is to check whether a tv channel is available or not.
Let first check the SQL data provided from DB:
```
MySQL [yourls]> select url, title from yourls_url where keyword like "user1%";
+-----------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------+
| url                                                                                                                                                 | title                           |
+-----------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------+
| http://83.228.88.114:8***/play/a***                                                                                                                 | BNT1                            |
| http://83.228.88.114:8***/play/a***                                                                                                                 | BNT2                            |
| http://83.228.88.114:8***/play/a***                                                                                                                 | BNT3                            |
+-----------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------+
```
From this data we get stream URLs and check each of them with ffprobe. If stream is available ok, check next one from list. If stream is not available send Telegram notification to prefered chat_id for monitoring purpose.

#### clean_stats
This is very simple script with which we want to clear clicks on short links from different user groups channels access. For example If me as administrator want to check working state of channels for different user and direct access his group channels. For example short link for user 1 for channel bnt1 http://myiptv.exampledns.org/user1/bnt1 redirect to long stream url http://83.228.88.114:8***/play/a*** and for user 2 for channel bnt1 http://myiptv.exampledns.org/user2/bnt1 redirect to long stream url http://83.228.88.115:8***/play/b*** . If we configure this script correctly and know from which source ip get requests for user 1 and user 2 we can clear the access logs and get correct statistics in yourls.

#### create_playlist
With this script you can create a playlist from short links from DB and copiyng it to docker container where yourls works. This is usefull when you make a changes from web GUI and want to have updated playlist of channels.

#### import_playlist
This is a script which can help you with filling DB with short links for iptv channels. Let imagine that you have a playlist with all you need and dont want to click from web GUI. You can use it to add or replace iptv stream channel for some short link. To work this you need a playlist file and check SQL file for which user are you need to fill the data in DB. To add a channel you will see all readed channels from playlist file and need to type channel name from playlist and short url. When you do this on next screen you will see again readed channels from playlist file but this time selected channel from last add action will not be in the list. For Replace function the work flow are the same - in loop you will see all readed channels from DB and need to enter channel name from playlist file to replace it into DB. If you dont want to change this channel from DB just press any key and continue to next one. 
This script have some limitation because for list of channels I use arrays instead changes on file which mean that if you interrupt the script execution you will start again from begining without saved changes from arrays data. On each action (Add or replace) you will make insert into DB so changes will be saved into DB.
*Need to make some little changes on script to precise the changes into DB, because found that on some case will change iptv stream for other users*

#### rotate-user-pass
This is helpful script for ethical use of paid iptv resources without interrupt users who paid for their subscription. Let imagine that you found records from some sites like examples in `rotate-user-pass/accounts` file. You need to have configured channels short links into DB for stream like this one `http://iptv.provider:80/username/password/channelID`. When you run the script will make following actions:
1. Check if the same process already exist. If the process is running from previous running the script will quit with error message describe the reason for this action.
2. If the first step pass (no running process from previous running of the script), the next step is to check count number in `rotate-user-pass/accounts` file. If the counted rows in file is less than 10 will send notification to Telegram chat_id channel configured for monitoring purpose. Why this is happen? In next steps from execution on this script if some account are not valid (changed passowrd or expired subscription) it will be deleted from `rotate-user-pass/accounts` file.
3. 
