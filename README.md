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
1. https://github.com/BstName/every-click-counts
2. https://github.com/williambargent/YOURLS-Forward-Slash-In-Urls
3. https://github.com/YOURLS/YOURLS/issues/2339#issuecomment-352127623
4. https://github.com/vaughany/yourls-popular-clicks-extended
5. https://github.com/seandrickson/YOURLS-Remove-the-Share-Function
6. https://github.com/YOURLS/timezones
7. https://github.com/GautamGupta/YOURLS-Import-Export

### The custom scripts

#### check-available-stream
As the name of the script suggest, here the task is to check whether a tv channel is available or not.
Let furst check the SQL data provided from DB:
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

#### create_playlist

#### import_playlist

#### rotate-user-pass
