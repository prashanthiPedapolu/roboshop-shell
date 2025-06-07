#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshopshell-log"
SCRIPT_NAME=$(basename "$0" | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started and executed at: $(date)" &>> $LOG_FILE

if [ $USERID -ne 0 ]; then
  echo -e "$R ERROR: Please run this script with root access $N"
  exit 1
else
  echo "You are running with root access" | tee -a $LOG_FILE
fi

# Validate function to check last command status
VALIDATE() {
  if [ $1 -eq 0 ]; then
    echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
  else
    echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
    exit 1
  fi
}
 dnf module disable nodejs -y &>> $LOG_FILE
 VALIDATE $? "Disabling Node.js module" &>> $LOG_FILE

 dnf module enable nodejs:20 -y &>> $LOG_FILE
 VALIDATE $? "Enabling Node.js 20 module" &>> $LOG_FILE

 dnf install nodejs -y &>> $LOG_FILE
 VALIDATE $? "Installing Node.js" &>> $LOG_FILE

 useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOG_FILE
 VALIDATE $? "Creating roboshop user" &>> $LOG_FILE

 mkdir -p /app
 VALIDATE $? "Creating /app directory" &>> $LOG_FILE

 curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
 VALIDATE $? "Downloading catalogue application package" &>> $LOG_FILE

 cd /app    
 unzip -o /tmp/catalogue.zip &>> $LOG_FILE  
 VALIDATE $? "Unzipping catalogue application package" &>> $LOG_FILE

 npm install &>> $LOG_FILE
 VALIDATE $? "Installing Node.js dependencies" &>> $LOG_FILE   
 
 cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>> $LOG_FILE
 VALIDATE $? "Copying catalogue service file" &>> $LOG_FILE

 systemctl daemon-reload &>> $LOG_FILE
 VALIDATE $? "Reloading systemd daemon" &>> $LOG_FILE

 systemctl enable catalogue &>> $LOG_FILE
 VALIDATE $? "Enabling catalogue service" &>> $LOG_FILE

 systemctl restart catalogue &>> $LOG_FILE
 VALIDATE $? "Restarting catalogue service" &>> $LOG_FILE

 cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongodb.repo &>> $LOG_FILE
 dnf install mongodb-mongosh -y
VALIDATE $? "Installing MongoDB client" &>> $LOG_FILE

mongosh --host mongodb.mylearnings.site </app/db/master-data.js

