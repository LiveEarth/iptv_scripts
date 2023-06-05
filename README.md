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

### Step 1 - prepare docker containers
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
