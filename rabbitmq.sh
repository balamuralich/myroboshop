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
Start_time=$(date +%s)
SCRIPT_DIR=pwd

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

cp $SCRIPT_DIR/rabbimq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "Adding RabbitMQ repo"

dnf install rabbitmq-server -y
VALIDATE $? "Installing RabbitMQ"

systemctl enable rabbitmq-server
VALIDATE $? "Enabling RabbitMQ"

systemctl start rabbitmq-server
VALIDATE $? "Starting RabbitMQ"

rabbitmqctl add_user roboshop roboshop123
VALIDATE $? "Adding roboshop User"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
VALIDATE $? "Setting up permissions"

End_time=$(date +%s)
Total_time=$(($End_time - $Start_time))
echo -e "Script excuted in $Y $Total_time $N Seconds"



