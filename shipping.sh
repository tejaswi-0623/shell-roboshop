#!/bin/bash

userid=$(id -u)
logs_folder="/var/log/shell-script"
logs_file="$logs_folder/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD
MYSQL_HOST=mysql.jarugula.online

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
}

dnf install maven -y &>>$logs_file
validate $? "installing java"

id roboshop &>>$logs_file
if [ $? -ne 0 ]; then
 useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
 validate $? "creating system user"
else
  echo -e "roboshop user already exists.....$Y skipping $N" 
fi

mkdir /app
validate $? "creating app directory"

rm -rf /app/*
validate $? "removing the existing code"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip 
validate $? "downloading shipping code"

cd /app
validate $? "moving to app directory"

unzip /tmp/shipping.zip &>>$logs_file
validate $? "unzipping the shipping code"

mvn clean package &>>$logs_file
validate $? "installing and building the package"

mv target/shipping-1.0.jar shipping.jar 
validate $? "moving and renaming the shipping"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
validate $? "created systemctl services"

systemctl daemon-reload &>>$logs_file
validate $? "reloading the service"

dnf install mysql -y &>>$logs_file
validate $? "installing mysql"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities'
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$logs_file
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$logs_file
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$logs_file
    validate $? "loaded data into MySQL"
else
    echo -e "data is already loaded ... $Y skipping $N"
fi

systemctl enable shipping
systemctl start shipping
validate $? "enable and start shipping"