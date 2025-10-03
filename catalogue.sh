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

dnf module disable nodejs -y &>>Logs_file           #Disables any existing Node.js module.
VALIDATE $? "Disabling NodeJS"                      

dnf module enable nodejs:20 -y &>>Logs_file         #Enables Node.js version 20.
VALIDATE $? "Enabling NodeJS:20"

dnf install nodejs -y &>>Logs_file                  #Installs Node.js..
VALIDATE $? "Installing NodeJS"

id roboshop &>>Logs_file                            #Checks if roboshop user exists. If not, creates a system user with no login shell and /app as home.
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>Logs_file
    VALIDATE $? "Creating System User"
else
    echo -e "User already exist .... hence, $Y SKIPPING $N"
fi

mkdir -p /app                                       #Creates /app directory if it doesn't exist.
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>Logs_file.  #Downloads the catalogue app zip file.
VALIDATE $? "Downloading catalogue Application"

cd /app                                             #Navigates to /app.
VALIDATE $? "Changing to App Directory"

rm -rf /app/*                                       #Clears old code.
VALIDATE $? "Removing existing code"

unzip /tmp/catalogue.zip &>>Logs_file               #Unzips the new code.
VALIDATE $? "Unzip Catalogue"

npm install &>>Logs_file                            #Installs required Node.js packages from package.json.
VALIDATE $? "Installing Dependencies"

cp $SCRIPT_DIR/catalogue_service /etc/systemd/system/catalogue.service  #Copies the service file to systemd.
VALIDATE $? "Copy systemctl service"

systemctl daemon-reload                             #Reloads systemd to recognize the new service.
systemctl enable catalogue                          #Enables the service to start on boot.
VALIDATE $? "Enabling Catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo  #Adds MongoDB repo.
VALIDATE $? "Copy Mongo repo"

dnf install mongodb-mongosh -y &>>Logs_file         #Installs mongosh, the MongoDB shell client.
VALIDATE $? "Installing mongodb client"

INDEX=$(mongosh mongodb.jyobala.space --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')") #Checks if catalogue DB exists., If not, loads initial data from master-data.js.
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>Logs_file
    VALIDATE $? "Load Catalogue products"
else
    echo -e "Catalogue products already loaded ... $Y SKIPPING $N"
fi

systemctl restart catalogue                         #Restarts the service to apply changes.
VALIDATE $? "Restarted Catalogue"