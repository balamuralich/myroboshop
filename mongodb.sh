#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
B="\e[1m" #Bold
N1="\e[22m" #No Bold

roboshop_logsogs="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
Logs_file="$roboshop_logs/$SCRIPT_NAME.log"
export Logs_file
mkdir -p $roboshop_logs

USERID=$(id -u)

if [ $USERID -ne 0 ]; then
    echo -e "$R $B ERROR $N1 $N - Please run with root privileges"
    exit 1
fi

VALIDATE(){
            if [ $1 -ne 0 ]; then
                echo -e "$B$G $2 $N$N1 $3 installation $G $B SUCCESS $N1 $N"
                dnf install $i -y &>>Logs_file
                echo -e "$i installation $G $B SUCCESS $N1 $N"
            else
                echo -e "$2 already installed hence $Y SKIPPING $N"
            fi
}

# if we need to take i value from a list we need to create a list and re-place @ with that list name.

for i in $@
do
dnf list installed $i &>>install.log
VALIDATE $? "$i" "Packages"
done

