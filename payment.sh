#!/bin/bash

userid=$(id -u)
logs_folder="/var/log/shell-script"
logs_file="$logs_folder/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD

mkdir -p $logs_folder

if [ $userid -ne 0 ]; then
  echo -e "$R please run the script with root user access $N" |tee -a $logs_file
  exit 1
fi

validate(){
    if [ $1 -ne 0 ]; then
     echo -e "$2 is.......$R failed $N" |tee -a $logs_file
     exit 1
    else
      echo -e "$2 is........$G success $N" |tee -a $logs_file
    fi
 }

dnf install python3 gcc python3-devel -y &>>$logs_file
validate $? "installing python"

id roboshop &>>$logs_file
if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
  validate $? "creating system user"
else
  echo -e "roboshop user already exists......$Y skipping $N" 
fi

mkdir -p /app &>>$logs_file
validate $? "creating app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip 
validate $? "downloading payment code"

cd /app
validate $? "moving to app directory"

unzip /tmp/payment.zip &>>$logs_file
validate $? "unzipping the payment code"

pip3 install -r requirements.txt
validate $? "installing dependencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>>$logs_file
validate $? "creating systemctl services"

systemctl daemon-reload &>>$logs_file 
validate $? "reloading the service"

systemctl enable payment &>>$logs_file
systemctl start payment
validate $? "enable and start payment"