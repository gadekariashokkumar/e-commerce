#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-ecommerce"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$(pwd)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-script/16-logs.log

mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script with root privelege"
    exit 1 # failure is other than 0
fi

VALIDATE(){ # functions receive inputs through args just like shell script args
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

# Install nginx
dnf install nginx -y &>> $LOG_FILE
VALIDATE $? "Installing Nginx"

# Enable nginx
systemctl enable nginx &>> $LOG_FILE
VALIDATE $? "Enabling Nginx"

# Start nginx
systemctl start nginx &>> $LOG_FILE
VALIDATE $? "Starting Nginx"

# Clean old content
rm -rf /usr/share/nginx/html/*
VALIDATE $? "Removing Old Content"

# Download frontend
curl -L -o /tmp/frontend.zip https://expense-joindevops.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>> $LOG_FILE
VALIDATE $? "Downloading Frontend Code"

# Extract frontend
unzip -o /tmp/frontend.zip -d /usr/share/nginx/html &>> $LOG_FILE
VALIDATE $? "Extracting Frontend Code"

# Backup default nginx config (important safety)
if [ -f /etc/nginx/nginx.conf ]; then
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
fi

# Copy your custom config
cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>> $LOG_FILE
VALIDATE $? "Copying nginx.conf"

# Validate nginx config BEFORE restart
nginx -t &>> $LOG_FILE
VALIDATE $? "Validating Nginx Config"

# Restart nginx
systemctl restart nginx &>> $LOG_FILE
VALIDATE $? "Restarting Nginx"