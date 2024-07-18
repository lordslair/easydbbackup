#!/bin/bash

ENGINE="SQLite"
PERIOD=$1
DB_PATH="/tmp/dump-$(echo "$ENGINE" | tr '[:upper:]' '[:lower:]')"
OK="[\e[92m✓\e[0m]"
KO="[\e[91m✗\e[0m]"

[[ $LOG_INFO == 'True' ]] && LOG='level=INFO | ' || LOG=''
[[ $LOG_DATE == 'True' ]] && NOW=$(date +'[%Y-%m-%d %H:%M:%S] ') || NOW=''

if [[ -e "$SQLITE_PATH/$SQLITE_DB" ]]
then
    echo   "$NOW$LOG[$PERIOD] $SQLITE_PATH/$SQLITE_DB"
    printf "$NOW$LOG[$PERIOD]  └> %9s " "Dumping"
    cp -a "$SQLITE_PATH/$SQLITE_DB" /tmp/
    sqlite3 \
        "/tmp/$SQLITE_DB" \
        .dump \
        > "$DB_PATH/$SQLITE_DB/dump.SQL"
    if [[ $? -eq 0 ]]; then echo -e $OK; else echo -e $KO; fi

    # We invoke the next part to Zip && rclone/rsync && clean
    bash /usr/local/bin/_backup-zip-push-clean.sh $PERIOD $ENGINE $SQLITE_DB
fi