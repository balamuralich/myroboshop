#!/bin/bash

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

VALIDATE(){
            if [ $1 -ne 0 ]; then
                echo -e "$2 .... $R FAILURE $N" | tee -a $Logs_file
                exit 1
            else
                echo -e "$2 .... $G SUCCESS $N" | tee -a $Logs_file
            fi
}

dnf module disable nodejs -y &>>Logs_file
VALIDATE $? "Disabling NodeJS"

dnf module enable nodejs:20 -y &>>Logs_file
VALIDATE $? "Enabling NodeJS:20"

dnf install nodejs -y &>>Logs_file
VALIDATE $? "Installing NodeJS"

id roboshop &>>Logs_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>Logs_file
    VALIDATE $? "Creating System User"
else
    echo -e "User already exist .... hence, $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>Logs_file
VALIDATE $? "Downloading catalogue Application"

cd /app
VALIDATE $? "Changing to App Directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/catalogue.zip &>>Logs_file
VALIDATE $? "Unzip Catalogue"

npm install &>>Logs_file
VALIDATE $? "Installing Dependencies"

cp $SCRIPT_DIR/catalogue_service /etc/systemd/system/catalogue.service
VALIDATE $? "Copy systemctl service"

systemctl daemon-reload
systemctl enable catalogue
VALIDATE $? "Enabling Catalogue"

cp $SCRIPT_DIR/etc/yum.repos.d/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copy Mongo repo"

dnf install mongodb-mongosh -y &>>Logs_file
VALIDATE $? "Installing mongodb client"

mongosh --host $MONGODB_HOST </app/db/master-data.js &>>Logs_file
VALIDATE $? "Load Catalogue products"

systemctl restart catalogue
VALIDATE $? "Restarted Catalogue"



