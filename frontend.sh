#!/bin/bash

userid=$(id -u)
logs_folder="/var/log/shell-script"
logs_file="$logs_folder/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
SCRIPT_DIR=$PWD

mkdir -p $logs_folder

if [ $userid -ne 0 ]; then
  echo -e " $R please run the script with root user access $N" |tee -a $logs_file
  exit 1
fi 

validate(){
  if [ $1 -ne 0 ]; then
   echo -e "$2 is........$R failed $N" |tee -a $logs_file
   exit 1
  else
    echo -e "$2 is......$G success $N" |tee -a $logs_file
  fi   
}

dnf module disable nginx -y &>>$logs_file
validate $? "disable default version"

dnf module enable nginx:1.24 -y &>>$logs_file
validate $? "enable nginx 1.24 version"

dnf install nginx -y &>>$logs_file
validate $? "installing nginx"

systemctl enable nginx &>>$logs_file
systemctl start nginx
validate $? "enable and start nginx"

rm -rf /usr/share/nginx/html/* 
validate $? "remove nginx default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
validate $? "download the frontend code"

cd /usr/share/nginx/html 
validate $? "moving to nginx html folder"

unzip /tmp/frontend.zip &>>$logs_file
validate $? "unzipping the frontend code"

rm -rf /etc/nginx/nginx.conf #remove default content of service if script runs again

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
validate $? "creating nginx configuration file"

systemctl restart nginx &>>$logs_file
validate $? "restarting nginx"

