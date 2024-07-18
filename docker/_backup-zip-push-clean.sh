#!/bin/bash

PERIOD=$1
ENGINE=$2
DATABASE=$3

DB_PATH="/tmp/dump-$(echo "$ENGINE" | tr '[:upper:]' '[:lower:]')"
OK="[\e[92m✓\e[0m]"
KO="[\e[91m✗\e[0m]"

[[ $LOG_INFO == 'True' ]] && LOG='level=INFO | ' || LOG=''
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
        echo "${NOW}${LOG}Invalid value for PERIOD: $PERIOD"
        exit
        ;;
esac

if [[ -d "$DB_PATH/$DATABASE" ]]
then
    printf "$NOW$LOG[$PERIOD]  └> %9s " "Zipping"
    ZIP_FILE="/tmp/${DATABASE}_${HEADER}.zip"
    zip \
        --quiet \
        --recurse-paths \
        $ZIP_FILE \
        $DB_PATH/$DATABASE
    if [[ -e "$ZIP_FILE" ]]
    then
        echo -e $OK

        if [[ $RCLONE_REMOTE_TYPE == 'swift' ]]; then
            printf "$NOW$LOG[$PERIOD]  └> %9s " "Rcloning"
            rclone --quiet sync $ZIP_FILE pcs:"$RCLONE_REMOTE_PATH"/"$ENGINE"/"$PERIOD"/
            if [[ $? -eq 0 ]]; then echo -e $OK; else echo -e $KO; fi
        elif [[ $RCLONE_REMOTE_TYPE == 's3' ]]; then
        printf "$NOW$LOG[$PERIOD]  └> %9s " "Rcloning"
            rclone --quiet sync $ZIP_FILE s3backup:"$RCLONE_REMOTE_PATH"/"$ENGINE"/"$PERIOD"/
            if [[ $? -eq 0 ]]; then echo -e $OK; else echo -e $KO; fi
        elif [[ $RCLONE_REMOTE_TYPE == 'rsync' ]]; then
            printf "$NOW$LOG[$PERIOD]  └> %9s " "Rsyncing"
            sshpass -p "$PCA_PASS" rsync -e "ssh -o StrictHostKeyChecking=no" -a $ZIP_FILE "$PCA_USER"@"$PCA_HOST":"$PCA_DIR"/"$ENGINE"/"$PERIOD"/
            if [[ $? -eq 0 ]]; then echo -e $OK; else echo -e $KO; fi
        else
            printf "$NOW$LOG[$PERIOD]  └> %9s " "\$RCLONE_REMOTE_TYPE not set, doing nothing"
            echo -e $KO
        fi

        printf "$NOW$LOG[$PERIOD]  └> %9s " "Cleaning"
        rm $ZIP_FILE
        if [ ! -f $ZIP_FILE ]; then echo -e $OK; else echo -e $KO; fi
    else
        echo -e $KO
    fi
else
    echo -e $KO
fi