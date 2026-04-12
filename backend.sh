#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-ecommerce"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$pwd
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

dnf module disable nodejs -y &>> $LOG_FILE
VALIDATE $? "Disabling NodeJS Module"
dnf module enable nodejs:20 -y &>> $LOG_FILE
VALIDATE $? "Enabling NodeJS 20 Module"
dnf install nodejs -y &>> $LOG_FILE
VALIDATE $? "Installing NodeJS"
useradd expense
VALIDATE $? "Creating Expense User"
mkdir /app
VALIDATE $? "Creating Application Folder"
curl -o /tmp/backend.zip https://expense-joindevops.s3.us-east-1.amazonaws.com/expense-backend-v2.zip
VALIDATE $? "Downloading Backend Application Code"
cd /app
unzip /tmp/backend.zip
cd /app
npm install
VALIDATE $? "Installing Backend Application Dependencies"
cp $SCRIPT_DIR/backend.service /etc/systemd/system/backend.service
VALIDATE $? "Copying Backend Service File"
systemctl daemon-reload
VALIDATE $? "Reloading Systemd Daemon"
systemctl start backend
VALIDATE $? "Starting Backend Service"
systemctl enable backend
VALIDATE $? "Enabling Backend Service"
dnf install mysql -y &>> $LOG_FILE
VALIDATE $? "Installing MySQL Client"
mysql -h my-sql.gadekari.store -uroot -pExpenseApp@1 < /app/schema/backend.sql
VALIDATE $? "Creating Backend Database and Tables"
systemctl restart backend
VALIDATE $? "Restarting Backend Service"


