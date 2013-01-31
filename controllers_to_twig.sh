#!/bin/bash

E_WRONGARGS=201;
E_NO_CD=202;
E_NO_FILE_CREATION=203;

m_E_WRONGARGS="El primer parametro, en donde se especifica el directorio de los controllers, es obligatorio";
m_E_NO_CD="No pudo posicionarse en";
m_E_NO_FILE_CREATION="No se pudo crear el archivo";
m_modifying="Modificando";
m_modify_success="\e[01;32mMODIFICADO\e[00m";
m_modify_none="\e[01;33mSIN CAMBIOS\e[00m";
m_modify_error="\e[01;31mERROR\e[00m";

#echo_begin_patterns = sed 's/<?\(php\)\? \?\(=\|echo\) \?\$\?/\{\{ /g'
#echo_end_patterns=('}}' 'php?>' '?>')
#if_begin_patterns=('{%' '\<\?if ' '\<\? if ?\(')

if [[ -n "$1" ]]
then
	dir=`echo $1 | sed -e "s%/$%%"`
else
	echo $m_E_WRONGARGS;
	exit $E_WRONGARGS;
fi

cd $dir
if [[ `pwd` != "$dir" ]]
then
	echo "$m_E_NO_CD $dir";
	exit $E_NO_CD
fi

if [[ -n "$2" ]]
then 
	views_pattern=$2
else
	views_pattern='/views/'
fi

if [[ ! -d old_controllers ]]
then
	mkdir old_controllers
fi

for file in *.php
do
	if [ -f $file ]
	then
		echo -n "$m_modifying......................................................."; echo -en "\033[12G\e[01;38m `basename $file`\e[00m"
		
		unset occurrences
		declare -A occurrences
		
		file_contents=`cat $file`
		
		IFS=$'\n'
		occs=( `echo -e "$file_contents" | grep -n -e "$views_pattern"` )
		
		for occ in ${occs[*]}
		do
			occurrences[`echo $occ | cut -f1 -d:`]=`echo $occ | cut -f2 -d:`
		done
		unset IFS
		#echo -e "${!occurrences[@]}"
		#echo -e "${occurrences[@]}"
		for o in ${!occurrences[@]}
		do
			#echo "[$o]=${occurrences[$o]}"
			template_dir="$(echo ${occurrences[$o]} | grep -o -e "\('\|\"\).*\('\|\"\)" | grep -o -e "[^\"\']*").twig"
			#echo -e "Tmp. Dir: $template_dir"
			
			if [[ `head -n1 $template_dir` == "{# @NOT_TWIG@ #}" ]]; then
				echo "{# @NOT_TWIG@ #}"
				break
			fi
			
			template_name="$(echo $template_dir | grep -o -e "[[:alnum:]_-]*.php").twig"
			#echo -e "Tmp. Name: $template_name"
			unset template_vars
			if [[ `head -n1 $template_dir` =~ \{#.*@VARS.*#\} ]]
			then
				template_vars=`head -n1 $template_dir | sed "s/{# @VARS \(.*\) #}/\1/"`
				#echo -e "Temp. vars: $template_vars"
			fi

			replace_str="\$twig->render('$template_name'"
			
			if [[ -n $template_vars ]] #If there are variables
			then
				replace_str+=", array("
				for var in $template_vars
				do
					replace_str+="'$var' => \$$var, "
				done
				replace_str=`echo "$replace_str" | sed -e 's/, $/));/'`
			else
				replace_str+=");"
			fi
			
			if [[ ${occurrences[$o]} =~ ^[[:blank:]]*(include|require)(_once)? ]]; then
				occurrences[$o]="$(echo ${occurrences[$o]} | grep -o -e "^[[:blank:]]*")echo $replace_str"
			elif [[ ${occurrences[$o]} =~ \$[[:alnum:]_-]* ]]; then
				occurrences[$o]="$(echo ${occurrences[$o]} | grep -o -e '^[[:blank:]]*\$[[:alnum:]_-]* \?=') $replace_str"
			else
				echo "FATAL ERROR! (occurrence[$o]=${occurrences[$o]})"
				exit 0
			fi
			
			file_contents=`echo -e "$file_contents" | sed "$o c ${occurrences[$o]}"`
			
		done
		
		#new_name=`echo "$file" #| sed 's/\(.*\)\.php/\1_c.php/'`
		#echo -e "$file_contents" > $new_name
		
		mv $file old_controllers/
		echo -e "$file_contents" > $file
		
		if [ -f "$file" ]
		then
		  
		  #diff $new_name $file 1> /dev/null #diff outpu: 0= no differences | 1= files differs
		  diff old_controllers/$file $file 1> /dev/null #diff outpu: 0= no differences | 1= files differs
		  
		  if [ $? -gt 0 ]
		  then
		    echo -e "\033[67G$m_modify_success"
		  else
		    echo -e "\033[67G$m_modify_none"
		  fi

		else
		  echo -e $m_modify_error;
		  echo -e $m_E_NO_FILE_CREATION
		  exit $E_NO_FILE_CREATION
		fi
	fi
done
