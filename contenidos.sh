#!/bin/bash

cd /var/www/Proyecto/frontend/controller

for arch in *.php
do
	echo -e "\n ------------   $arch   ---------------\n"
	matches=$(cat $arch | grep /views/)
	echo -e "$matches"
	vars=$(echo -e "$matches" | grep -e "^[[:blank:]]*\\$.*=")
	echo -e "Vars: $vars"
done

