#!bin/bash

userid=$(id -u)
logs_folder="var/log/shell-script"
logs_file="$logs_folder/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
$script=$PWD

mkdir -p $logs_folder

if [ $userid -ne 0 ]; then
  echo -e "$R please run the script with root user access $N" |tee -a $logs_file
  exit 1
fi

validate(){
   if [ $1 -ne 0]; then
     echo -e "$2 is.........$R failed $N" |tee -a $logs_file
     exit 1
   else
     echo -e " $2 is........$G success $N"|tee -a $logs_file
   fi
}

dnf module disable redis -y &>>$logs_file
validate $? "disabling default version"

dnf module enable redis:7 -y &>>$logs_file
validate $? "enabling redis-7 version"

dnf install redis -y &>>$logs_file
validate $? "installing redis"

sed -i  's/127.0.0.1/0.0.0.0/g' /etc/redis/redis.conf
sed -i   '/protected-mode/ c protected-mode no' /etc/redis/redis.conf  #c means change in the line to no
validate $? "allowing remote connections"

systemctl enable redis
systemctl start redis
validate $? "enabling and starting redis"
