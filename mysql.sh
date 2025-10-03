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

dnf install mysql-server -y &>>$Logs_file
VALIDATE $? "Installing MySQL"

systemctl enable mysqld &>>$Logs_file
VALIDATE $? "Enabling MySQL"

systemctl start mysqld &>>$Logs_file
VALIDATE $? "Starting MySQL"  

mysql_secure_installation --set-root-pass RoboShop@1
VALIDATE $? "Setting up root password"

End_time=$(date +%s)
Total_time=$(($End_time - $Start_time))
echo -e "Script excuted in $Y $Total_time $N Seconds"