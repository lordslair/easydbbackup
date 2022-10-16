# easydbbackup, the project :

This project started to have a simple and lightweight container to :
- backup MySQL/MariaDB, Redis, or SQLite databases
- export the dumps to a remote archive server accessible with rsync or rclone

All of this inside Docker containers for portable purposes.  
This containers is powered up by Kubernetes

### Variables

To work properly, the scripts will require informations and credentials  
We assume they are passed to the container in ENV

Logging related variables:
- `LOG_DATE`: boolean, to output current date in logs
- `LOG_INFO`: boolean, to output loglevel in logs

MySQL/MariaDB server related variables :
- `MYSQL_DUMP`: boolean, to execute this backup type
- `MYSQL_DBLIST`: is a list, representing the DB to backup
- `MYSQL_DB_HOST`: mysql-server hostname or IP
- `MYSQL_DB_PORT`: mysql-server port
- `MYSQL_DB_USER`: mysql-server username
- `MYSQL_DB_PASS`: mysql-server password

SQLite server related variables :
- `SQLITE_DUMP`: boolean, to execute this backup type
- `SQLITE_DB`: sqlite database filename (ex: sqlite3.db)
- `SQLITE_PATH`: sqlite database location (ex: /db)

Redis server related variables :
- `REDIS_DUMP`: boolean, to execute this backup type
- `REDIS_DB_HOST`: redis-server hostname or IP
- `REDIS_DB_PORT`: redis-server port

In my case I use a rsync enabled remote storage called PCA (Public Cloud Archive), hence the variable names

- `PCA_USER`: destination rsync username
- `PCA_PASS`: destination rsync password
- `PCA_HOST`: destination rsync host
- `PCA_DIR`: destination direcory to store the backups

Specific variables are used for rclone copies.  
Please refer to the corresponding `k8s/deployment-rclone.yaml` to see them all
Hint: ALL the variables are mandatory

### Output

Here are the outputs with ENV vars `LOG_INFO` and `LOG_DATE` set to `True`

```
MySQL/MariaDB version
[2022-10-16 22:58:40] level=INFO | [hourly] my-mysql-server/my-database
[2022-10-16 22:58:40] level=INFO | [hourly]  └>  Dumping [✓]
[2022-10-16 22:58:40] level=INFO | [hourly]  └>  Zipping [✓]
[2022-10-16 22:58:40] level=INFO | [hourly]  └> Rcloning [✓]
[2022-10-16 22:58:40] level=INFO | [hourly]  └> Cleaning [✓]
[2022-10-16 22:58:42] level=INFO | [hourly] my-mysql-server/mysql
[2022-10-16 22:58:42] level=INFO | [hourly]  └>  Dumping [✓]
[2022-10-16 22:58:42] level=INFO | [hourly]  └>  Zipping [✓]
[2022-10-16 22:58:42] level=INFO | [hourly]  └> Rcloning [✓]
[2022-10-16 22:58:42] level=INFO | [hourly]  └> Cleaning [✓]

Redis version
[2022-10-16 23:00:08] level=INFO | [daily] sep-backend-redis-svc
[2022-10-16 23:00:08] level=INFO | [daily]  └>  Dumping [✓]
[2022-10-16 23:00:08] level=INFO | [daily]  └>  Zipping [✓]
[2022-10-16 23:00:08] level=INFO | [daily]  └> Rcloning [✓]
[2022-10-16 23:00:08] level=INFO | [daily]  └> Cleaning [✓]

SQLite version
[2022-10-16 23:00:12] level=INFO | [daily] /db/sqlite3.db
[2022-10-16 23:00:12] level=INFO | [daily]  └>  Dumping [✓]
[2022-10-16 23:00:12] level=INFO | [daily]  └>  Zipping [✓]
[2022-10-16 23:00:12] level=INFO | [daily]  └> Rcloning [✓]
[2022-10-16 23:00:12] level=INFO | [daily]  └> Cleaning [✓]
```

Once a day, a status will be displayed with Size used & number of zip files  
This will occur, whether you use rsync or rclone
```
[2022-10-16 22:12:41] level=INFO |-----------------------------------|
[2022-10-16 22:12:41] level=INFO |        Remote Usage Status        |
[2022-10-16 22:12:41] level=INFO |-----------------------------------|
[2022-10-16 22:12:41] level=INFO |  Period | Engine |    Size | ZIPs |
[2022-10-16 22:12:41] level=INFO |---------|--------|---------|------|
[2022-10-16 22:12:41] level=INFO |  hourly |  MySQL |   58 MB |   21 |
[2022-10-16 22:12:41] level=INFO |  hourly |  Redis |    0 MB |    7 |
[2022-10-16 22:12:41] level=INFO |         |  TOTAL |   58 MB |   28 |
[2022-10-16 22:12:54] level=INFO |   daily |  MySQL |    8 MB |    3 |
[2022-10-16 22:12:54] level=INFO |   daily |  Redis |    0 MB |    1 |
[2022-10-16 22:12:54] level=INFO |         |  TOTAL |    8 MB |    4 |
[2022-10-16 22:13:03] level=INFO |  weekly |  MySQL |    8 MB |    3 |
[2022-10-16 22:13:03] level=INFO |  weekly |  Redis |    0 MB |    1 |
[2022-10-16 22:13:03] level=INFO |         |  TOTAL |    8 MB |    4 |
[2022-10-16 22:13:12] level=INFO | monthly |  MySQL |    8 MB |    3 |
[2022-10-16 22:13:12] level=INFO | monthly |  Redis |    0 MB |    1 |
[2022-10-16 22:13:12] level=INFO |         |  TOTAL |    8 MB |    4 |
[2022-10-16 22:13:12] level=INFO |---------|--------|---------|------|
[2022-10-16 22:13:12] level=INFO |                  |   82 MB |   40 |
[2022-10-16 22:13:12] level=INFO |-----------------------------------|
```

### Destination folders

On the remote storage `PCA_HOST` or the rclone remote destination  
the backups are stored in `PCA_DIR` (or `RCLONE_CONFIG_PCS_DIR`) are stored this way :

```
.
└── DIR
    ├── MySQL
    │  ├── daily
    │  │   └── $(date +%d)-dump-$(dbname).SQL.zip
    │  ├── hourly
    │  │   └── $(date +%H)-dump-$(dbname).SQL.zip
    │  ├── monthly
    │  │   └── $(date +%B)-dump-$(dbname).SQL.zip
    │  └── weekly
    │      └── $(date +%W)-dump-$(dbname).SQL.zip
    ├── Redis
    │  └── ...
    └── SQLite
       └── ...    
```

### Tech

I used mainly :

* Bash
* [docker/docker-ce][docker] to make it easy to maintain
* [kubernetes/kubernetes][kubernetes] to make everything smooth
* [Alpine][alpine] - probably the best/lighter base container to work with

And of course GitHub to store all these shenanigans.

### Installation

You can build the container yourself :
```
$ git clone https://github.com/lordslair/easydbbackup
$ cd easydbbackup
$ docker build .
```

Or the latest build is available on docker hub :
```
# docker pull lordslair/easydbbackup
Using default tag: latest
latest: Pulling from lordslair/easydbbackup
Digest: sha256:20a216bc9c9e5bbea2a64f1ef152ee8874dcdec5faec6a9ccfab70cb0e1c1ba7
Status: Downloaded newer image for lordslair/easydbbackup:latest
```

For a Kubernetes (k8s) deployment with MySQL/MariaDB, I added examples files :  
Of course, you'll have to modify the secrets to fit with your credentials
```
$ git clone https://github.com/lordslair/easydbbackup
$ cd easydbbackup/k8s
$ kubectl apply -f secrets.yaml
$ kubectl apply -f deployment.yaml
```

For a Kubernetes (k8s) deployment with SQLite, I added examples files :  
Of course, you'll have to modify the env vars to fit with your credentials
```
$ git clone https://github.com/lordslair/easydbbackup
$ cd easydbbackup/k8s
$ kubectl apply -f deployment-sqlite.yaml
```

For a Kubernetes (k8s) deployment with MySQL/MariaDB and rclone, I added examples files :  
Of course, you'll have to modify the env vars to fit with your credentials
```
$ git clone https://github.com/lordslair/easydbbackup
$ cd easydbbackup/k8s
$ kubectl apply -f deployment-rclone.yaml
```

#### Disclaimer/Reminder

> Always double-check your backups and test the restoration process once in a while.  
> I won't take the blame =)  

### Todos

 - Nothing yet

---
   [kubernetes]: <https://github.com/kubernetes/kubernetes>
   [docker]: <https://github.com/docker/docker-ce>
   [alpine]: <https://github.com/alpinelinux>
