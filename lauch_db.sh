#!/bin/bash

passwd=${1:-postgres}
docker run --name truebg-postgres -p 5432:5432 -e POSTGRES_PASSWORD=$passwd -d postgres:10.1
