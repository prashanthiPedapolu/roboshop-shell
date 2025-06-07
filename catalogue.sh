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

# Node.js setup
dnf module disable nodejs -y &>> $LOG_FILE
VALIDATE $? "Disabling Node.js module"

dnf module enable nodejs:20 -y &>> $LOG_FILE
VALIDATE $? "Enabling Node.js 20 module"

dnf install nodejs -y &>> $LOG_FILE
VALIDATE $? "Installing Node.js"

# roboshop user creation
id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOG_FILE
  VALIDATE $? "Creating roboshop user"
else
  echo -e "roboshop user already exists ... $Y SKIPPING $N" | tee -a $LOG_FILE
fi

# App setup
mkdir -p /app
VALIDATE $? "Creating /app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $LOG_FILE
VALIDATE $? "Downloading catalogue application package"

cd /app
unzip -o /tmp/catalogue.zip &>> $LOG_FILE
VALIDATE $? "Unzipping catalogue application package"

npm install &>> $LOG_FILE
VALIDATE $? "Installing Node.js dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>> $LOG_FILE
VALIDATE $? "Copying catalogue service file"

systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "Reloading systemd daemon"

systemctl enable catalogue &>> $LOG_FILE
VALIDATE $? "Enabling catalogue service"

systemctl restart catalogue &>> $LOG_FILE
VALIDATE $? "Restarting catalogue service"

# MongoDB repo and schema
cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongodb.repo &>> $LOG_FILE
VALIDATE $? "Copying MongoDB repo file"

dnf install mongodb-mongosh -y &>> $LOG_FILE
VALIDATE $? "Installing MongoDB client"

mongosh --host mongodb.mylearnings.sitee </app/db/master-data.js
VALIDATE $? "Loading MongoDB schema"
