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

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>Logs_file  #Downloads the catalogue app zip file.
VALIDATE $? "Downloading cart Application"

cd /app                                             #Navigates to /app.
VALIDATE $? "Changing to App Directory"

unzip /tmp/cart.zip &>>Logs_file               #Unzips the new code.
VALIDATE $? "Unzip Cart"

rm -rf /app/*                                       #Clears old code.
VALIDATE $? "Removing existing code"

npm install &>>Logs_file                            #Installs required Node.js packages from package.json.
VALIDATE $? "Installing Dependencies"

cp $SCRIPT_DIR/cart_service /etc/systemd/system/cart.service &>>Logs_file #Copies the service file to systemd.
VALIDATE $? "Copy systemctl service"

systemctl daemon-reload                             #Reloads systemd to recognize the new service.
systemctl enable cart                          #Enables the service to start on boot.
VALIDATE $? "Enabling Cart"

systemctl start cart                        #Restarts the service to apply changes.
VALIDATE $? "Restarted cart"

End_time=$(date +%s)
Total_time=$(($End_time - $Start_time))
echo -e "Script excuted in $Y $Total_time $N Seconds"