#!/bin/bash

userid=$(id -u)
logs_folder="var/log/shell-script"
logs_file="var/log/shell-script/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
Script_dir=$PWD
mongodb_ip="mongodb.jarugula.online"

if [ $userid -ne 0 ]; then
  echo -e "$R please run this script with root user access $N" |tee -a $logs_file
  exit 1
fi

validate(){
    if [ $1 -ne 0 ]; then
      echo -e "$2 is........$R failed $N" |tee -a $logs_file
      exit 1
    else
      echo -e "$2 is...........$G success $N"|tee -a $logs_file
    fi
}

dnf module disable nodejs -y &>>$logs_file
validate $? "disabling nodejs default version" 

dnf module enable nodejs:20 -y &>>$logs_file
validate $? "enabling nodejs 20 version"

dnf install nodejs -y &>>$logs_file
validate $? "install nodejs"

id system_user &>>$logs_file #id username if output is not zero create user else skip it
if [ $3 -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$logs_file
  validate $? "creating system user"
else
  echo -e "user already existed ....$Y skipping $N"
fi

mkdir -p /app 
validate $? "creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$logs_file
validate $? "downloading catalogue code"

cd /app &>>$logs_file &>>$logs_file
validate $? "moving to app directory"

rm -rf /app/* #if you run the code again it will ask to download it again so we are removing the code which already has and downloading now
validate $? "removing the existing code"

unzip /tmp/catalogue.zip &>>$logs_file
validate $? "unzipping the catalogue code"

npm install 
validate $? "installing dependencies"

cp $Script_dir/catalogue.service /etc/systemd/system/catalogue.service #created catalogue.service script and copying 
validate $? "copying catalogue service file"

systemctl daemon reload
systemctl enable catalogue
systemctl start catalogue &>>$logs_file
validate $? "enable the start the catalogue"

cp $Script_dir/mongodb.repo /etc/yum.repos.d/mongo.repo #copying mongo repo 
dnf install mongodb-mongosh -y &>>$logs_file


data=$(mongosh --host $MONGODB_HOST --quiet  --eval 'db.getMongo().getDBNames().indexOf("catalogue")') #vairable=$(command)

if [ $data -ne 0 ]; then
  mongosh --host  $mongodb_ip </app/db/master-data.js
  validate $? "loading products"
else
  echo -e "products or data is already loaded....$Y skipping $N"
fi

systemctl restart catalogue
validate $? "restarting the catalogue"


