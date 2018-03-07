#!/bin/bash

rm ~/.ssh/td_bg.pem
cp -f ~/.ssh/config.bk ~/.ssh/config
rm -f ~/td_bg.prod.secret.exs
