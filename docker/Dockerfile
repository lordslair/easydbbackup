FROM alpine:3.12
MAINTAINER @Lordslair

RUN apk update --no-cache \
    && apk add --no-cache             rsync \
                                      openssh \
                                      sshpass \
                                      bash \
                                      zip \
                                      mysql-client \
    && apk add --no-cache --virtual  .build-deps \
                                      tzdata \
    && cp /usr/share/zoneinfo/Europe/Paris /etc/localtime \
    && apk del .build-deps

COPY cron-backup-sh.daily   /etc/periodic/daily/cron-backup-sh
COPY cron-backup-sh.hourly  /etc/periodic/hourly/cron-backup-sh
COPY cron-backup-sh.monthly /etc/periodic/monthly/cron-backup-sh
COPY cron-backup-sh.weekly  /etc/periodic/weekly/cron-backup-sh

COPY cron-status-sh.daily   /etc/periodic/daily/cron-status-sh

ENTRYPOINT ["crond", "-f", "-l", "2"]
