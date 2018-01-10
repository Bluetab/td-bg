#!/bin/bash

rm ~/.ssh/fastTag.pem
cp -f ~/.ssh/config.bk ~/.ssh/config
rm -f ~/truebg.prod.secret.exs
