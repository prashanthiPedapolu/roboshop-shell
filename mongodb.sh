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

# Copy the repo file

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongodb.repo &>> $LOG_FILE
VALIDATE $? "Copying MongoDB repo file"

# Install MongoDB
dnf install -y mongodb-org &>> $LOG_FILE
VALIDATE $? "Installing MongoDB server"

# Enable MongoDB service
systemctl enable mongod &>> $LOG_FILE
VALIDATE $? "Enabling mongod service"

# Start MongoDB service
systemctl start mongod &>> $LOG_FILE
VALIDATE $? "Starting mongod service"

# Update MongoDB bind IP
sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf &>> $LOG_FILE
VALIDATE $? "Changing bind IP in mongod.conf"

# Restart MongoDB to apply config
systemctl restart mongod &>> $LOG_FILE
VALIDATE $? "Restarting mongod service"
