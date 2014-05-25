#/bin/sh
REDMINE_DB_NAME=$1
REDMINE_DB_USER_NAME=$2
REDMINE_DB_PW=$3

service mysqld start

mysql -uroot -e "create database $REDMINE_DB_NAME default character set utf8;"
mysql -uroot -e "grant all on $REDMINE_DB_NAME.* to $REDMINE_DB_USER_NAME@localhost identified by '$REDMINE_DB_PW';"
mysql -uroot -e "flush privileges;"
