#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
B="\e[1m" #Bold
N1="\e[22m" #No Bold

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
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
                echo -e "$2 .... $G SUCCRESS $N" | tee -a $Logs_file
            fi
}

# copy from mongo.repo to setup the MongoDB repo file, without this setup mongodb-org would not be installed.
cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding Mongo repo"

dnf install mongodb-org -y &>>$Logs_file
VALIDATE $? "Installing MongoDB"

systemctl enable mongod &>>$Logs_file
VALIDATE $? "Enabling MongoDB"

systemctl start mongod &>>$Logs_file
VALIDATE $? "Starting MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing remote connections to MongoDB"

systemctl restart mongod
VALIDATE $? "Restarted MongoDB"