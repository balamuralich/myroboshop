#!/bin/bash

#These are ANSI escape codes used to format terminal output with colors and bold text.

R="\e[31m"  #Red color
G="\e[32m"  #Green color
Y="\e[33m"  #Yellow color
N="\e[0m"   #No color
B="\e[1m"   #To start Bold letters
N1="\e[22m" #To stop Bold

LOGS_FOLDER="/var/log/shell-roboshop"       #Directory to store logs.
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)     #Extracts the script name (without extension).
SCRIPT_DIR=$PWD                             #Current working directory.
MONGODB_HOST=mongodb.jyobala.space          #MongoDB hostname.
Logs_file="$LOGS_FOLDER/$SCRIPT_NAME.log"   #Full path to the log file for this script.
Start_time=$(date +%s)

mkdir -p $LOGS_FOLDER                       #Ensures the log directory exists.

USERID=$(id -u)                             #Checks if the script is run as root (id -u returns 0 for root).
                                            #If not, it exits with an error.
if [ $USERID -ne 0 ]; then                  
    echo -e "$R $B ERROR $N1 $N - Please run with root privileges"
    exit 1
fi

#Below is the a helper function to check the exit status of commands.
#Logs success or failure and exits on error.

VALIDATE(){
            if [ $1 -ne 0 ]; then
                echo -e "$2 .... $R FAILURE $N" | tee -a $Logs_file
                exit 1
            else
                echo -e "$2 .... $G SUCCESS $N" | tee -a $Logs_file
            fi
}

dnf module disable nginx -y &>>Logs_file
dnf module enable nginx:1.24 -y &>>Logs_file
dnf install nginx -y &>>Logs_file
VALIDATE $? "Installing Nginx"

systemctl enable nginx &>>Logs_file
systemctl start nginx &>>Logs_file
VALIDATE $? "Starting Nginx"

rm -rf /usr/share/nginx/html/* 

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>Logs_file

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>Logs_file
VALIDATE $? "Unzip Frontend"

rm -rf /etc/nginx/nginx.conf
cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copying nginx.conf"

systemctl restart nginx
VALIDATE $? "Restarting Nginx"

End_time=$(date +%s)
Total_time=$(($End_time - $Start_time))
echo -e "Script excuted in $Y $Total_time $N Seconds"

