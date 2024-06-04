#!/bin/bash

ENGINE="MongoDB"
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

for MONGO_DB in `echo $MONGO_DB_LIST | tr "," "\n"`;do
    # LOG_DATE
    [[ $LOG_DATE == 'True' ]] && NOW=$(date +'[%Y-%m-%d %H:%M:%S] ') || NOW=''

    MONGO_ZIP_FILE="/tmp/$HEADER-dump-$MONGO_DB.zip"
    MONGO_DB_DIR="/tmp/dump-mongodb"

    MONGO_DB_AUTH=admin
    MONGO_URI="mongodb://$MONGO_DB_USER:$MONGO_DB_PASS@$MONGO_DB_HOST/$MONGO_DB?authSource=$MONGO_DB_AUTH&replicaSet=replicaset&tls=true"

    echo    "$NOW$LOG[$PERIOD] $MONGO_DB_HOST/$MONGO_DB"

    if [[ $MONGODB_EXPORT == 'True' ]]
    then
    printf "$NOW$LOG[$PERIOD]  └> %9s " "Exporting"
        MONGO_COLLECTION_LIST=`ls -c1 $MONGO_DB_DIR/$MONGO_DB/ | grep .bson | sed -e 's/.bson//'`
        for MONGO_COLLECTION in $MONGO_COLLECTION_LIST;do
            mongoexport \
                --quiet \
                --uri $MONGO_URI \
                --collection $MONGO_COLLECTION \
                --out $MONGO_DB_DIR/$MONGO_DB/$MONGO_COLLECTION.json
        done;
        echo -e $OK
    fi

    printf "$NOW$LOG[$PERIOD]  └> %9s " "Dumping"
    mongodump \
        --quiet \
        --uri $MONGO_URI \
        --out $MONGO_DB_DIR

    if [[ -d "$MONGO_DB_DIR/$MONGO_DB" ]]
    then
        echo -e $OK
        printf "$NOW$LOG[$PERIOD]  └> %9s " "Zipping"
        zip --quiet --recurse-paths $MONGO_ZIP_FILE $MONGO_DB_DIR/$MONGO_DB
        if [[ -e "$MONGO_ZIP_FILE" ]]
        then
            echo -e $OK

            if [[ $RCLONE_CONFIG_PCS_TYPE == 'swift' ]]
            then
                printf "$NOW$LOG[$PERIOD]  └> %9s " "Rcloning"
                rclone --quiet sync $MONGO_ZIP_FILE pcs:"$RCLONE_CONFIG_PCS_DIR"/"$ENGINE"/"$PERIOD"/
                if [[ $? -eq 0 ]]; then echo -e $OK; else echo -e $KO; fi
            else
                printf "$NOW$LOG[$PERIOD]  └> %9s " "Rsyncing"
                sshpass -p "$PCA_PASS" rsync -e "ssh -o StrictHostKeyChecking=no" -a $MONGO_ZIP_FILE "$PCA_USER"@"$PCA_HOST":"$PCA_DIR"/"$ENGINE"/"$PERIOD"/
                if [[ $? -eq 0 ]]; then echo -e $OK; else echo -e $KO; fi
            fi

            printf "$NOW$LOG[$PERIOD]  └> %9s " "Cleaning"
            rm $MONGO_ZIP_FILE
            if [ ! -f $MONGO_ZIP_FILE ]; then echo -e $OK; else echo -e $KO; fi
        else
            echo -e $KO
        fi
    else
        echo -e $KO
    fi
done;