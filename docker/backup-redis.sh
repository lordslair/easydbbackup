#!/bin/bash

ENGINE="Redis"
PERIOD=$1
OK="[\e[92m✓\e[0m]"
KO="[\e[91m✗\e[0m]"

# LOG_INFO
[[ $LOG_INFO == 'True' ]] && LOG='level=INFO | ' || LOG=''
# LOG_DATE
[[ $LOG_DATE == 'True' ]] && NOW=$(date +'[%Y-%m-%d %H:%M:%S] ') || NOW=''

# Check the value of the PERIOD variable
case "$PERIOD" in
    daily)
        HEADER=$(date +%d)
        ;;
    hourly)
        HEADER=$(date +%H)
        ;;
    monthly)
        HEADER=$(date +%B)
        ;;
    weekly)
        HEADER=$(date +%W)
        ;;
    *)
        echo "Invalid value for PERIOD: $PERIOD"
        exit
        ;;
esac

REDIS_ZIP_FILE="/tmp/$HEADER-dump-redis.RDB.zip"
REDIS_DB_FILE="/tmp/dump-redis.RDB"

echo    "$NOW$LOG[$PERIOD] $REDIS_DB_HOST"
printf "$NOW$LOG[$PERIOD]  └> %9s " "Dumping"
redis-cli -u "redis://$REDIS_DB_HOST:$REDIS_DB_PORT" --rdb $REDIS_DB_FILE &>/dev/null
if [[ -e "$REDIS_DB_FILE" ]]
then
    echo -e $OK
    printf "$NOW$LOG[$PERIOD]  └> %9s " "Zipping"
    zip -qq $REDIS_ZIP_FILE $REDIS_DB_FILE
    if [[ -e "$REDIS_ZIP_FILE" ]]
    then
        echo -e $OK

        if [[ $RCLONE_CONFIG_PCS_TYPE == 'swift' ]]
        then
            printf "$NOW$LOG[$PERIOD]  └> %9s " "Rcloning"
            rclone --quiet sync $REDIS_ZIP_FILE pcs:"$RCLONE_CONFIG_PCS_DIR"/"$ENGINE"/"$PERIOD"/
            if [[ $? -eq 0 ]]; then echo -e $OK; else echo -e $KO; fi
        else
            printf "$NOW$LOG[$PERIOD]  └> %9s " "Rsyncing"
            sshpass -p "$PCA_PASS" rsync -e "ssh -o StrictHostKeyChecking=no" -a $REDIS_ZIP_FILE "$PCA_USER"@"$PCA_HOST":"$PCA_DIR"/"$ENGINE"/"$PERIOD"/
            if [[ $? -eq 0 ]]; then echo -e $OK; else echo -e $KO; fi
        fi

        printf "$NOW$LOG[$PERIOD]  └> %9s " "Cleaning"
        rm $REDIS_ZIP_FILE
        if [ ! -f $REDIS_ZIP_FILE ]; then echo -e $OK; else echo -e $KO; fi
    else
        echo -e $KO
    fi
    rm $REDIS_DB_FILE
else
    echo -e $KO
fi