#!/bin/bash

ENGINE="MongoDB"
DB_LIST=$MONGO_DB_LIST
PERIOD=$1
DB_PATH="/tmp/dump-$(echo "$ENGINE" | tr '[:upper:]' '[:lower:]')"
MONGO_DB_AUTH=admin
OK="[\e[92m✓\e[0m]"
KO="[\e[91m✗\e[0m]"

[[ $LOG_INFO == 'True' ]] && LOG='level=INFO | ' || LOG=''

for DATABASE in `echo $DB_LIST | tr "," "\n"`;do
    [[ $LOG_DATE == 'True' ]] && NOW=$(date +'[%Y-%m-%d %H:%M:%S] ') || NOW=''

    MONGO_URI="mongodb://$MONGO_DB_USER:$MONGO_DB_PASS@$MONGO_DB_HOST/$DATABASE?authSource=$MONGO_DB_AUTH&replicaSet=replicaset&tls=true"

    echo   "$NOW$LOG[$PERIOD] $MONGO_DB_HOST/$DATABASE"

    if [[ $MONGODB_EXPORT == 'True' ]]
    then
    printf "$NOW$LOG[$PERIOD]  └> %9s " "Exporting"
        MONGO_COLLECTION_LIST=`ls -c1 $DB_PATH/$DATABASE/ | grep .bson | sed -e 's/.bson//'`
        for MONGO_COLLECTION in $MONGO_COLLECTION_LIST;do
            mongoexport \
                --quiet \
                --uri $MONGO_URI \
                --collection $MONGO_COLLECTION \
                --out $DB_PATH/$DATABASE/$MONGO_COLLECTION.json
        done;
        echo -e $OK
    fi

    printf "$NOW$LOG[$PERIOD]  └> %9s " "Dumping"
    mongodump \
        --quiet \
        --uri $MONGO_URI \
        --out $DB_PATH
    if [[ $? -eq 0 ]]; then echo -e $OK; else echo -e $KO; fi

    # We invoke the next part to Zip && rclone/rsync && clean
    bash /usr/local/bin/_backup-zip-push-clean.sh $PERIOD $ENGINE $DATABASE

done;