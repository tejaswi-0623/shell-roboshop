#!/bin/bash

userid=$(id -u)
logs_folder="var/log/shell-script"
logs_file="var/log/shell-script/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e33m"
N="\e0m"

if [ $userid -ne 0 ]; then
  echo -e "$R please run this script with root user access $N" |tee -a $logs_file
  exit 1
fi

validate(){
    if [ $1 -ne 0 ]; then
      echo -e "$R $2 is........failed $N" |tee -a $logs_file
      exit 1
    else
      echo -e "$G $2 is...........success $N"|tee -a $logs_file
    fi
}

dnf module disable nodejs -y &>> $logs_file
validate $? "disabling nodejs default version" 

dnf module enable nodejs:20 -y &>> $logs_file
validate $? "enabling nodejs 20 version"

dnf install nodejs -y &>> $logs_file
validate $? "install nodejs"

id system_user &>> $logs_file
if [ $3 -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $logs_file
  validate $? "creating system user"
else
  echo -e "$Y user already existed ....skipping $N"
fi

mkdir -p /app 
validate $? "creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
validate $? "downloading catalogue code"

cd /app 
validate $? "moving to app directory"

unzip /tmp/catalogue.zip
validate $? "unzipping the catalogue code"


