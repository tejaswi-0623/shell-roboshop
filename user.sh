#!/bin/bash

userid=$(id -u)
logs_folder="var/log/shell-script"
logs_file="$logs_folder/$0/log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
script_dir=$PWD

mkdir -p $logs_folder

if [ $userid -ne 0 ]; then
  echo -e "$R please run the script with root user access $N"|tee -a $logs_file
  exit 1
fi

validate (){
    if [ $1 -ne 0 ]; then
      echo -e "$2 is........$R failed $N"|tee -a $logs_file
      exit 1
    else
      echo -e "$2 is.......$G success $N"|tee -a $logs_file
    fi
}

dnf module disable nodejs -y &>>$logs_file
validate $? "disable default nodejs version"

dnf module enable nodejs:20 -y &>>$logs_file
validate $? "enable nodejs 20 version"

dnf install nodejs -y &>>$logs_file
validate $? "installing nodejs"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
  validate $? "creating system user"
else
  echo -e "roboshop user already exists.....$Y skipping $N"
fi

mkdir /app &>>$LOGS_FILE
validate $? "create app directory"

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip 
validate $? "downloading user code"

cd /app 
validate $? "moving to app directory"

unzip /tmp/user.zip &>>$LOGS_FILE
validate $? "unzipping the user code"

npm install &>>$LOGS_FILE
validate $? "installing dependencies"

cp $ript_dir/user.service  /etc/systemd/sytem/user.service
validate $? "systemctl services"

systemctl daemon-reload
systemctl enable user
systemctl start user
validate $? "enabling and start user"