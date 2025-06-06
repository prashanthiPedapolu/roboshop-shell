#!/bin/bash
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshopshell-log"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
mkdir -p $LOGS_FOLDER
echo "script started and executed at : $(date)" &>>$LOG_FILE

if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N"
    exit 1 #give other than 0 upto 127
else
    echo "You are running with root access"
fi

# validate functions takes input as exit status, what command they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "Installing $2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "Installing $2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
    }
    cp C:\Users\ammul\devops\shell-repo\shell-script\roboshop-shell\mongo.repo /etc/yum.repos.d/mongod.repo &>>$LOG_FILE
    VALIDATE $? "copying mongo db repo"

    dnf install mongodb-org -y &>>$LOG_FILE
    VALIDATE $? "Mongodb installing server"

    systemctl enable mongod &>>$LOG_FILE
    VALIDATE $? "enabling mongod"

    systemctl start mongod &>>$LOG_FILE
    VALIDATE $? "starting mongod"

    sed -i 's/127.0.0.0/0.0.0.0/g' /etc/mongod.conf &>>$LOG_FILE
    VALIDATE $? "changing bind ip in mongod.conf"

    systemctl restart mongod &>>$LOG_FILE
    VALIDATE $? "Restarting  mogod"
