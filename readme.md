[![Docker Build Status](https://img.shields.io/docker/build/jaaaco/mongo-s3-cron-backup-restore.svg)](https://hub.docker.com/r/jaaaco/mongo-s3-cron-backup-restore/)

# Automatic mongodb restore and cron based backups

At startup script tries to restore local mongo database from latest backup, then it starts cron service and creates 
backup in S3 bucket **using same file every time**. There is no backup retention.

## Usage

Example docker-compose.yml:

```
version: '2.1'
services:
  mongodb:
    image: mongo:3.2.12
    healthcheck:
      test: 'timeout 2 bash -c "</dev/tcp/localhost/27017"'
      interval: 5s
      timeout: 5s
      retries: 10
    ports:
      - 27017:27017
  app:
    build:
      context: app
    environment:
      MONGO_URL: "mongodb://mongodb:27017/app"
    ports:
      - 80:80
    depends_on:
      mongodb:
        condition: service_healthy
  backup:
    image: jaaaco:mongo-s3-cron-backup-restore
    environment:
      AWS_ACCESS_KEY_ID: "PLACE_YOUR_KEYS_HERE"
      AWS_SECRET_ACCESS_KEY: "PLACE_YOUR_KEYS_HERE"
      S3BUCKET: "PLACE_YOUR_BUCKET_NAME_HERE"
      DB: "app"
    links:
      - mongodb
    depends_on:
      mongodb:
        condition: service_healthy
```

## Required ENV variables

* AWS_ACCESS_KEY_ID - user with s3 put-object and get-object perrmissions
* AWS_SECRET_ACCESS_KEY
* S3BUCKET - S3 bucket name
* FILEPREFIX - (optional) file prefix
* DB - (optional) database name
* CRON_SCHEDULE - (optional) cron schedule, defaults to 0 3 * * * (at 3 am, every day)
* MONGO_HOST - (optional) defaults to mongodb
* MONGO_PORT - (optional) defaults to 27017
