#!/bin/bash
if [ -n $1 ]
then
	cd /var/www/html/Proyecto/entrega2/frontend/controller
else
	cd $1
fi

if [ -n $2 ]
then
	pattern='/views/'
else
	pattern=$2
fi

declare -A occurrences

for arch in *.php
do
	file_contents=`cat $arch`
	
	IFS=$'\n'

	occs=( $( echo -e "$file_contents" | grep -n -e "$pattern" ) )
	
	for occ in ${occs[*]}
	do
		occurrences[`echo $occ | cut -f1 -d:`]=`echo $occ | cut -f2 -d:`
	done
	unset IFS
	#echo -e "${!occurrences[@]}"
	#echo -e "${occurrences[@]}"
	for o in ${!occurrences[@]}
	do
		#echo $o
		template_dir=`echo ${occurrences[$o]} | grep -o -e "\('\|\"\).*\('\|\"\)" | grep -o -e "[^\"']*"`
		#echo -e "$template_dir"
		template_name=`echo $template_dir | grep -o -e "[[:alnum:]_-]*.php"`
		#echo -e "$template_name"
		template_vars=`head -n1 $template_dir | sed "s/{# @VARS \(.*\) #}/\1/"`
		#echo -e "$template_vars"
		replace_str="\$twig->render('$template_name.twig'"
		
		if [[ $template_vars =~ '[[:alnum:]_-]' ]] #If there are variables
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
		
		if [[ $occurrences[$o] =~ '^[[:blank:]]*\(include\|require\)_once\?' ]]; then
			$occurrences[$o]="$(echo $occurrences[$o] | grep -o -e "^[[:blank:]]*")echo $replace_str"
		elif [[ $occurrences[$o] =~ '^[[:blank:]]*\\$[[:alnum:]_-] \?=' ]]; then
			$occurrences[$o]="$(echo $occurrences[$o] | grep -o -e '^[[:blank:]]*\\$[[:alnum:]_-] \?=') $replace_str"
		fi
		
		file_contents=`echo -e "$file_contents" | sed "$o c $occurrences[$o]"`
		#echo "occurrences[$o] => ${occurrences[$o]}"
		
	done
	
	echo -e "$file_contents"
	#vars=(`echo -e "$file_contents" | grep "$pattern" | grep -o -e "^[[:blank:]]*\\$.*=" | grep -o -e "[[:alnum:]_-]*"`)
	#echo ${vars[@]}
	#file_contents=`sed -e "s%^\([[:blank:]]*\)include.*$pattern\([[:alnum]_-]*\.php\).*$%\1echo \$twig->render('\2.twig', array('name' => 'Fabien'));
done

