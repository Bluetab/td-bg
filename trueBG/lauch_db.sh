#!/bin/bash

passwd=$1
if [ -z $passwd ];then
  echo "You must pass password as argument EJ. ./launch.sh mypassword"
  exit 0
fi
sudo docker run --name truebg-postgres -p 5432:5432 -e POSTGRES_PASSWORD=$passwd -d postgres:10.1
