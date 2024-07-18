#!/bin/bash

ENGINE="Redis"
PERIOD=$1
DB_PATH="/tmp/dump-$(echo "$ENGINE" | tr '[:upper:]' '[:lower:]')"
DATABASE=$(echo "$ENGINE" | tr '[:upper:]' '[:lower:]')
OK="[\e[92m✓\e[0m]"
KO="[\e[91m✗\e[0m]"

[[ $LOG_INFO == 'True' ]] && LOG='level=INFO | ' || LOG=''
[[ $LOG_DATE == 'True' ]] && NOW=$(date +'[%Y-%m-%d %H:%M:%S] ') || NOW=''

echo   "$NOW$LOG[$PERIOD] $REDIS_DB_HOST"
printf "$NOW$LOG[$PERIOD]  └> %9s " "Dumping"
mkdir -p "$DB_PATH/$DATABASE"
redis-cli \
    -u "redis://$REDIS_DB_HOST:$REDIS_DB_PORT" \
    --rdb "$DB_PATH/$DATABASE/dump.RDB" \
    &>/dev/null
if [[ $? -eq 0 ]]; then echo -e $OK; else echo -e $KO; fi

# We invoke the next part to Zip && rclone/rsync && clean
bash /usr/local/bin/_backup-zip-push-clean.sh $PERIOD $ENGINE $DATABASE