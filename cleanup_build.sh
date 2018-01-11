#!/bin/bash

rm ~/.ssh/truebg.pem
cp -f ~/.ssh/config.bk ~/.ssh/config
rm -f ~/truebg.prod.secret.exs
