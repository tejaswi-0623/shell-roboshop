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

id roboshop &>>$logs_file
if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$logs_file
  validate $? "creating system user"
else
  echo -e "roboshop user already exists.....$Y skipping $N"
fi

mkdir -p /app 
validate $? "create app directory"

rm -rf /app/*
validate $? "Removing existing code"  #remove the code if i run the script again before downloading

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip 
validate $? "downloading cart code"

cd /app 
validate $? "moving to app directory"

unzip /tmp/cart.zip 
validate $? "unzipping the cart code"

npm install &>>$logs_file
validate $? "installing dependencies"


cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
validate $? "systemctl services"

systemctl daemon-reload
systemctl enable cart
systemctl start cart
validate $? "enabling and start cart"