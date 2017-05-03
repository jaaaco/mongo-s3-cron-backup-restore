#!/usr/bin/env bash

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  echo "AWS_ACCESS_KEY_ID must be set"
  HAS_ERRORS=true
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "AWS_SECRET_ACCESS_KEY must be set"
  HAS_ERRORS=true
fi

if [ -z "$S3BUCKET" ]; then
  echo "S3BUCKET must be set"
  HAS_ERRORS=true
fi

if [ $HAS_ERRORS ]; then
  echo "Exiting.... "
  exit 1
fi

if [ -z "$DATEFORMAT" ]; then
  DATEFORMAT='%Y%m%d_%H%M%S'
fi

if [ -z "$FILEPREFIX" ]; then
  FILEPREFIX=''
fi

if [ -z "$MONGO_HOST" ]; then
  MONGO_HOST="localhost"
fi

if [ -z "$MONGO_PORT" ] ; then
  MONGO_PORT="27017"
fi

if [[ -n "$DB" ]]; then
  DB_ARG="--db $DB"
fi

FILENAME=$FILEPREFIX.latest.tar.gz
FILE=/backup/backup-$FILENAME

if [ "$1" == "backup" ] ; then
  echo "Starting backup... $(date)"
  echo "mongodump --quiet -h $MONGO_HOST -p $MONGO_PORT $DB_ARG"
  mongodump --quiet -h $MONGO_HOST -p $MONGO_PORT $DB_ARG
  if [ -d dump ] ; then
      tar -zcvf $FILE dump/
      aws s3api put-object --bucket $S3BUCKET --key $FILENAME --body $FILE
      echo "Cleaning up..."
      rm -rf dump/ $FILE
  else
      echo "No data to backup"
  fi
  exit 0
fi

echo "Restoring latest backup"
aws s3api get-object --bucket $S3BUCKET --key $FILENAME latest.tar.gz
if [ -e latest.tar.gz ] ; then
    tar zxfv latest.tar.gz
    mongorestore --drop -h $MONGO_HOST -p $MONGO_PORT dump/
    echo "Cleaning up..."
    rm -rf dump/ latest.tar.gz
else
    echo "No backup to restore"
fi

CRON_SCHEDULE=${CRON_SCHEDULE:-0 3 * * *}

LOGFIFO='/var/log/cron.fifo'
if [[ ! -e "$LOGFIFO" ]]; then
    touch "$LOGFIFO"
fi

CRON_ENV="MONGO_HOST='$MONGO_HOST'"
CRON_ENV="$CRON_ENV\nMONGO_PORT='$MONGO_PORT'"
CRON_ENV="$CRON_ENV\nAWS_ACCESS_KEY_ID='$AWS_ACCESS_KEY_ID'"
CRON_ENV="$CRON_ENV\nAWS_SECRET_ACCESS_KEY='$AWS_SECRET_ACCESS_KEY'"
CRON_ENV="$CRON_ENV\nS3BUCKET='$S3BUCKET'"
CRON_ENV="$CRON_ENV\nPATH=$PATH"

echo -e "$CRON_ENV\n$CRON_SCHEDULE /backup.sh backup > $LOGFIFO 2>&1" | crontab -
crontab -l
cron
tail -f "$LOGFIFO"