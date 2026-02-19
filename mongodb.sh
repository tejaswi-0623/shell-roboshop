#!/bin/bash

userid=$(id -u)   #vairable=$(command)
logs_folder="var/log/shell-practice"
logs_file="var/log/shell-practice/$0.log"
R="\e[31m" #red color
G="\e[32m" #green
N="\e[0m"   #normal


if [ $userid -ne 0 ]; then
  echo -e "$R please run the script with root user access $N" |tee -a $logs_file #-e for colors
  exit 1
fi

mkdir -p $logs_folder

validate(){
    if [ $1 -ne 0 ]; then
      echo -e "$2 is.........$R failed $N"  |tee -a $l0gs_file
      exit 1
    else
      echo -e "$2 is........$G success $N" |tee -a $logs_file
    fi
}

#created mondodb repo and copying to mongodb path
cp mongodb.repo /etc/yum.repos.d/mongo.repo
validate $? "copying mongo repo" # $1=$? and $2=copying mongo repo from validate function

#installing mongodb
dnf install mongodb-org -y &>>$logs_file
validate $? "installing mongodb" # $1=$? and $2=installing mongodb from validate function

#systemctl services
systemctl enable mongod &>>$logs_file  #here in mongod d means dameon
validate $? "enable mongodb" # $1=$? and $2=enable mongodb from validate function

systemctl start mongod
validate $? "start mongodb " # $1=$? and $2=start mongodb from validate function

#mondodb give access to local host only but we need to connect to remote connections.so update address
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf #using sed editor to edit mongodb config file
validate $? "allow remote connections" # $1=$? and $2=allow remote connections from validate function

systemctl restart mongod
validate $? "restarted mongodb" # $1=$? and $2=restart mongodb from validate function