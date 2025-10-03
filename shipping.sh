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
MYSQL_HOST=mysql.jyobala.space

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

dnf install maven -y &>>Logs_file

id roboshop &>>Logs_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>Logs_file
    VALIDATE $? "Creating System User"
else
    echo -e "User already exist .... hence, $Y SKIPPING $N"
fi

mkdir /app

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>Logs_file
VALIDATE $? "Downloading Shipping Application"

cd /app
VALIDATE $? "Creating App Directory"

rm -rf /app/*
VALIDATE $? "Removing exitsting code"

unzip /tmp/shipping.zip &>>Logs_file
VALIDATE $? "Unzip Shipping"

mvn clean package &>>Logs_file
VALIDATE $? "Maven Package cleaning"

mv target/shipping-1.0.jar shipping.jar &>>Logs_file

systemctl daemon-reload &>>Logs_file
VALIDATE $? "Reloading Daemon"

systemctl start shipping &>>Logs_file
VALIDATE $? "Start Shipping"

dnf install mysql -y &>>Logs_file
VALIDATE $? "Installing MySQL"

mysql -h $MYSQL_HOST -uroot >pRoboShop@1 -e 'use cities' &>>Logs_file

if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>Logs_file
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>>Logs_file
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>Logs_file
else
    echo "Shipping data already loaded hence..... $Y SKIPPING $N"
fi

systemctl restart shipping &>>Logs_file
VALIDATE $? "Shipping restart"


End_time=$(date +%s)
Total_time=$(($End_time - $Start_time))
echo -e "Script excuted in $Y $Total_time $N Seconds"