#!/bin/bash

set -euo pipefail

trap 'echo "There is an error in $LINENO, Command is: $BASH_COMMAND"' ERR

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
B="\e[1m" #Bold
N1="\e[22m" #No Bold

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.jyobala.space
Logs_file="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER

USERID=$(id -u)

if [ $USERID -ne 0 ]; then
    echo -e "$R $B ERROR $N1 $N - Please run with root privileges"
    exit 1
fi

dnf module disable nodejs -y &>>Logs_file
dnf module enable nodejs:20 -y &>>Logs_file
dnf install nodejs -y &>>Logs_file
id roboshop &>>Logs_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>Logs_file
else
    echo -e "User already exist .... hence, $Y SKIPPING $N"
fi
mkdir -p /app
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>Logs_file
cd /app
rm -rf /app/*
unzip /tmp/catalogue.zip &>>Logs_file
npm installll &>>Logs_file
cp $SCRIPT_DIR/catalogue_service /etc/systemd/system/catalogue.service
systemctl daemon-reload
systemctl enable catalogue
cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>>Logs_file
INDEX=$(mongosh mongodb.jyobala.space --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>Logs_file
else
    echo -e "Catalogue products already loaded ... $Y SKIPPING $N"
fi
systemctl restart catalogue