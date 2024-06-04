#!/bin/bash

ENGINE="SQLite"
PERIOD=$1
OK="[\e[92m✓\e[0m]"
KO="[\e[91m✗\e[0m]"

# LOG_INFO
[[ $LOG_INFO == 'True' ]] && LOG='level=INFO | ' || LOG=''
# LOG_DATE
[[ $LOG_DATE == 'True' ]] && NOW=$(date +'[%Y-%m-%d %H:%M:%S] ') || NOW=''

SQLITE_ZIP_FILE="/tmp/$HEADER-dump-$SQLITE_DB.SQL.zip"
SQLITE_DB_FILE="/tmp/dump-$SQLITE_DB.SQL"

if [[ -e "$SQLITE_PATH/$SQLITE_DB" ]]
then
    echo    "$NOW$LOG[$PERIOD] $SQLITE_PATH/$SQLITE_DB"
    printf "$NOW$LOG[$PERIOD]  └> %9s " "Dumping"
    cp -a "$SQLITE_PATH/$SQLITE_DB" /tmp/
    sqlite3 "/tmp/$SQLITE_DB" .dump > $SQLITE_DB_FILE
    if [[ -e "$SQLITE_DB_FILE" ]]
    then
        echo -e $OK
        printf "$NOW$LOG[$PERIOD]  └> %9s " "Zipping"
        zip -qq $SQLITE_ZIP_FILE $SQLITE_DB_FILE
        if [[ -e "$SQLITE_ZIP_FILE" ]]
        then
            echo -e $OK

            if [[ $RCLONE_CONFIG_PCS_TYPE == 'swift' ]]
            then
                printf "$NOW$LOG[$PERIOD]  └> %9s " "Rcloning"
                rclone --quiet sync $SQLITE_ZIP_FILE pcs:"$RCLONE_CONFIG_PCS_DIR"/"$ENGINE"/"$PERIOD"/
                if [[ $? -eq 0 ]]; then echo -e $OK; else echo -e $KO; fi
            else
                printf "$NOW$LOG[$PERIOD]  └> %9s " "Rsyncing"
                sshpass -p "$PCA_PASS" rsync -e "ssh -o StrictHostKeyChecking=no" -a $SQLITE_ZIP_FILE "$PCA_USER"@"$PCA_HOST":"$PCA_DIR"/"$ENGINE"/"$PERIOD"/
                if [[ $? -eq 0 ]]; then echo -e $OK; else echo -e $KO; fi
            fi

            printf "$NOW$LOG[$PERIOD]  └> %9s " "Cleaning"
            rm $SQLITE_ZIP_FILE "/tmp/$SQLITE_DB"
            if [ ! -f $SQLITE_ZIP_FILE ]; then echo -e $OK; else echo -e $KO; fi
        else
            echo -e $KO
        fi
        rm $SQLITE_DB_FILE
    else
        echo -e $KO
    fi
fi