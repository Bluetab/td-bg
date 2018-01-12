#!/bin/bash

rm -f ~/.ssh/truebg.pem
echo "$PRODUCTION_PEM" | sed 's/\r//g' | sed 's/^ //g' > ~/.ssh/truebg.pem
chmod 400 ~/.ssh/truebg.pem
touch ~/.ssh/config
chmod 600 ~/.ssh/config
cp -f ~/.ssh/config ~/.ssh/config.bk
PRODUCTION_HOST=$(cat .deliver/config | grep PRODUCTION_HOSTS | cut -f2 -d"=" | sed -e 's/"//g')
echo "Host ${PRODUCTION_HOST}" > ~/.ssh/config
echo "IdentityFile ~/.ssh/truebg.pem" >>  ~/.ssh/config
chmod 400 ~/.ssh/config
