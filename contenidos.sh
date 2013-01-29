#!/bin/bash
if [[ -n $1 ]]
then
	cd $1
else
	#cd /var/www/html/Proyecto/entrega2/frontend/controller
	cd /var/www/Proyecto/frontend/controller
fi

if [[ -n $2 ]]
then
	pattern=$2
else
	pattern='/views/'
fi

declare -A occurrences

for arch in ctests.php #*.php
do
	file_contents=`cat $arch`
	
	IFS=$'\n'
	echo "patron=$pattern"
	occs=( `echo -e "$file_contents" | grep -n -e "$pattern"` )
	
	for occ in ${occs[*]}
	do
		occurrences[`echo $occ | cut -f1 -d:`]=`echo $occ | cut -f2 -d:`
	done
	unset IFS
	#echo -e "${!occurrences[@]}"
	#echo -e "${occurrences[@]}"
	for o in ${!occurrences[@]}
	do
		echo "[$o]=${occurrences[$o]}"
		template_dir="$(echo ${occurrences[$o]} | grep -o -e "\('\|\"\).*\('\|\"\)" | grep -o -e "[^\"\']*").twig"
		echo -e "Tmp. Dir: $template_dir"
		template_name="$(echo $template_dir | grep -o -e "[[:alnum:]_-]*.php").twig"
		echo -e "Tmp. Name: $template_name"

		if [[ `head -n1 $template_dir` =~ "{#.*@VARS.*#}" ]]
		then
			template_vars=`head -n1 $template_dir | sed "s/{# @VARS \(.*\) #}/\1/"`
			echo -e "Temp. vars: $template_vars"
		fi

		replace_str="\$twig->render('$template_name'"
		
		if [[ -n $template_vars ]] #If there are variables
		then
			replace_str+=", array("
			for var in $template_vars
			do
				replace_str+="'$var' => \$$var, "
			done
			replace_str=`echo $replace_str | sed -e 's/, $/);/'`
		else
			replace_str+=");"
		fi
		
		if [[ ${occurrences[$o]} =~ 'include' || ${occurrences[$o]} =~ 'require' ]]; then
			occurrences[$o]="$(echo ${occurrences[$o]} | grep -o -e "^[[:blank:]]*")echo $replace_str"
		elif [[ ${occurrences[$o]} =~ "\$" ]]; then
			occurrences[$o]="$(echo ${occurrences[$o]} | grep -o -e '^[[:blank:]]*\\$[[:alnum:]_-] \?=') $replace_str"
		else
			echo "FATAL ERROR! (occurrence[$o]=${occurrences[$o]})"
			exit 0
		fi
		
		file_contents=`echo -e "$file_contents" | sed "$o c ${occurrences[$o]}"`
		echo "occurrences[$o] => ${occurrences[$o]}"
		
	done
	
	echo -e "$file_contents"
	#vars=(`echo -e "$file_contents" | grep "$pattern" | grep -o -e "^[[:blank:]]*\\$.*=" | grep -o -e "[[:alnum:]_-]*"`)
	#echo ${vars[@]}
	#file_contents=`sed -e "s%^\([[:blank:]]*\)include.*$pattern\([[:alnum]_-]*\.php\).*$%\1echo \$twig->render('\2.twig', array('name' => 'Fabien'));
done

