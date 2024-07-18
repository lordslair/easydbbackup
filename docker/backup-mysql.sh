#!/bin/bash

ENGINE="MySQL"
PERIOD=$1
DB_PATH="/tmp/dump-$(echo "$ENGINE" | tr '[:upper:]' '[:lower:]')"
OK="[\e[92m✓\e[0m]"
KO="[\e[91m✗\e[0m]"

[[ $LOG_INFO == 'True' ]] && LOG='level=INFO | ' || LOG=''

for DATABASE in `echo $MYSQL_DB_LIST | tr "," "\n"`;do
    [[ $LOG_DATE == 'True' ]] && NOW=$(date +'[%Y-%m-%d %H:%M:%S] ') || NOW=''

    echo   "$NOW$LOG[$PERIOD] $MYSQL_DB_HOST/$DATABASE"
    printf "$NOW$LOG[$PERIOD]  └> %9s " "Dumping"
    mkdir -p "$DB_PATH/$DATABASE"
    mysqldump \
        --opt \
        --lock-tables \
        --user=$MYSQL_DB_USER \
        --password=$MYSQL_DB_PASS \
        --host=$MYSQL_DB_HOST \
        --port=$MYSQL_DB_PORT \
        $DATABASE > "$DB_PATH/$DATABASE/dump.SQL"
    if [[ $? -eq 0 ]]; then echo -e $OK; else echo -e $KO; fi

    # We invoke the next part to Zip && rclone/rsync && clean
    bash /usr/local/bin/_backup-zip-push-clean.sh $PERIOD $ENGINE $DATABASE
done;