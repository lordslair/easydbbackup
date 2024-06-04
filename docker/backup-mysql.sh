#!/bin/bash

ENGINE="MySQL"
PERIOD=$1
OK="[\e[92m✓\e[0m]"
KO="[\e[91m✗\e[0m]"

# LOG_INFO
[[ $LOG_INFO == 'True' ]] && LOG='level=INFO | ' || LOG=''

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

for MYSQL_DB in `echo $MYSQL_DB_LIST | tr "," "\n"`;do
    # LOG_DATE
    [[ $LOG_DATE == 'True' ]] && NOW=$(date +'[%Y-%m-%d %H:%M:%S] ') || NOW=''

    MYSQL_ZIP_FILE="/tmp/$HEADER-dump-$MYSQL_DB.SQL.zip"
    MYSQL_DB_FILE="/tmp/dump-$MYSQL_DB.SQL"

    echo    "$NOW$LOG[$PERIOD] $MYSQL_DB_HOST/$MYSQL_DB"
    printf "$NOW$LOG[$PERIOD]  └> %9s " "Dumping"
    mysqldump \
        --opt \
        --lock-tables \
        --user=$MYSQL_DB_USER \
        --password=$MYSQL_DB_PASS \
        --host=$MYSQL_DB_HOST \
        --port=$MYSQL_DB_PORT \
        $MYSQL_DB > $MYSQL_DB_FILE

    if [[ -e "$MYSQL_DB_FILE" ]]
    then
        echo -e $OK
        printf "$NOW$LOG[$PERIOD]  └> %9s " "Zipping"
        zip -qq $MYSQL_ZIP_FILE $MYSQL_DB_FILE
        if [[ -e "$MYSQL_ZIP_FILE" ]]
        then
            echo -e $OK

            if [[ $RCLONE_CONFIG_PCS_TYPE == 'swift' ]]
            then
                printf "$NOW$LOG[$PERIOD]  └> %9s " "Rcloning"
                rclone --quiet sync $MYSQL_ZIP_FILE pcs:"$RCLONE_CONFIG_PCS_DIR"/"$ENGINE"/"$PERIOD"/
                if [[ $? -eq 0 ]]; then echo -e $OK; else echo -e $KO; fi
            else
                printf "$NOW$LOG[$PERIOD]  └> %9s " "Rsyncing"
                sshpass -p "$PCA_PASS" rsync -e "ssh -o StrictHostKeyChecking=no" -a $MYSQL_ZIP_FILE "$PCA_USER"@"$PCA_HOST":"$PCA_DIR"/"$ENGINE"/"$PERIOD"/
                if [[ $? -eq 0 ]]; then echo -e $OK; else echo -e $KO; fi
            fi

            printf "$NOW$LOG[$PERIOD]  └> %9s " "Cleaning"
            rm $MYSQL_ZIP_FILE
            if [ ! -f $MYSQL_ZIP_FILE ]; then echo -e $OK; else echo -e $KO; fi
        else
            echo -e $KO
        fi
        rm $MYSQL_DB_FILE
    else
        echo -e $KO
    fi
done;
