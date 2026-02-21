#!/bin/bash

userid=$(id -u)
logs_folder="/var/log/shell-script"
logs_file="$logs_folder/$0.log"
R="\e[31m"
G="\e[32m"
N="\e[0m"

mkdir -p $logs_folder

if [ $userid -ne 0 ]; then
  echo -e "$R please run the script with root user access $N" |tee -a $logs_file
  exit 1
fi

validate (){
    if [ $1 -ne 0 ]; then
     echo -e "$2 is........$R failed $N" |tee -a $logs_file
     exit 1
    else
     echo -e "$2 is.......$G success $N" |tee -a $logs_file
    fi
}

cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
validate $? "copying rabbitmq repo"

dnf install rabbitmq-server -y &>>$logs_file
validate $? "installing rabbitmq"
 
systemctl enable rabbitmq-server &>>$logs_file
systemctl start rabbitmq-server
validate $? "enable and start rabbitmq"

rabbitmqctl add_user roboshop roboshop123
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
validate $? "add user and set permissions"