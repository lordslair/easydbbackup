FROM alpine:3.20

COPY docker/cron-backup-sh.daily   /etc/periodic/daily/cron-backup-sh
COPY docker/cron-backup-sh.hourly  /etc/periodic/hourly/cron-backup-sh
COPY docker/cron-backup-sh.monthly /etc/periodic/monthly/cron-backup-sh
COPY docker/cron-backup-sh.weekly  /etc/periodic/weekly/cron-backup-sh

COPY docker/cron-status-sh.daily   /etc/periodic/daily/cron-status-sh

COPY docker/backup-mongodb.sh      /usr/local/bin/backup-mongodb.sh
COPY docker/backup-mysql.sh        /usr/local/bin/backup-mysql.sh
COPY docker/backup-redis.sh        /usr/local/bin/backup-redis.sh
COPY docker/backup-sqlite.sh       /usr/local/bin/backup-sqlite.sh

COPY docker/_backup-zip-push-clean.sh /usr/local/bin/_backup-zip-push-clean.sh

RUN apk update --no-cache \
    && apk add --no-cache \
        "bash" \
        "mariadb-connector-c" \
        "mysql-client" \
        "mongodb-tools" \
        "openssh" \
        "rclone" \
        "sqlite" \
        "sshpass" \
        "zip" \
    && apk add --no-cache --virtual  .build-deps \
        "redis" \
        "tzdata" \
    && cp -a /usr/share/zoneinfo/Europe/Paris /etc/localtime \
    && cp -a /usr/bin/redis-cli /usr/local/bin/ \
    && apk del .build-deps

ENTRYPOINT ["crond", "-f", "-l", "2"]
