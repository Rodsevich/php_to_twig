cd /var/www/Proyecto/frontend/controller
for arch in *.php
do
	output+="$( cat $arch | grep /views/)"
done
echo -e "$output"
vars=$(echo -e "$output" | grep -e "\\$.*=")
	echo -e "$vars"
