#!/bin/bash

E_WRONGARGS=201;
E_NO_CD=202;
E_NO_FILE_CREATION=203;

m_E_WRONGARGS="El primer parametro, en donde se especifica el directorio a reemplazar los templates, es obligatorio";
m_E_NO_CD="No pudo posicionarse en";
m_E_NO_FILE_CREATION="No se pudo crear el archivo";
m_modifying="Modificando";
m_modify_success="\e[01;32mMODIFICADO\e[00m";
m_modify_none="\e[01;33mSIN CAMBIOS\e[00m";
m_modify_error="\e[01;31mERROR\e[00m";

#echo_begin_patterns = sed 's/<?\(php\)\? \?\(=\|echo\) \?\$\?/\{\{ /g'
#echo_end_patterns=('}}' 'php?>' '?>')
#if_begin_patterns=('{%' '\<\?if ' '\<\? if ?\(')

if [[ -n $1 ]]
then
	dir=`echo $1 | sed -e "s%/$%%"`
else
	echo $m_E_WRONGARGS;
	exit $E_WRONGARGS;
fi

cd $dir
if [ `pwd` != "$dir" ]
then
	echo "$m_E_NO_CD $dir";
	exit $E_NO_CD
fi

#Tranforms echos structures
sed_args=("-e 's/<?\(php\)\? \?\(=\|echo\) \?/{{ /g; :r; s/\({{.*\)?>/\1}}/g; tr'")

#Transforms control structures
sed_args+=("-e 's/<?\(php\)\? \?/{% /g; s/\({%.*\)[;:{] \??>/\1%}/g;'")

#Transforms variable's methods calls inside structures
sed_args+=("-e ':m; s/\({{\|{%\)\(.*\)\\$\([[:alnum:].]*\)->\(is\|get\)\(.*\)\(}}\|%}\)/\1\2$\3.\5\6/; tm'")

#Removes undesired characters and fixes control structures
sed_args+=("-e ':s; s/\({{\|{%\)\(.*\)[$;]\(.*\)\(}}\|%}\)/\1\2\3\4/; ts; s/{%\([^(]*\)(\(.*\))\(.*\)%}/{%\1 \2 \3%}/'")

#Fixes foreach tags
sed_args+=("-e 's/{% *foreach *\([[:graph:]]*\) *as *\([[:graph:]]*\) *%}/{% for \2 in \1 %}/g'")

#Fixes identation
sed_args+=("-e 's/ *\(}}\|%}\)/ \1/g; s/\({{\|{%\) */\1 /g'")

for file in *.php
do
	if [ -f $file ]
	then
		#Modifying message
		echo -n "$m_modifying......................................................."; echo -en "\033[12G\e[01;38m `basename $file`\e[00m"
		
		twig="$file.twig"
		
		transform_output=$(eval "sed ${sed_args[@]} $file" 2>&1)
		
		vars=( $(echo -e "$transform_output" | grep -o -e "{{ *[[:alnum:]_-]\+" | grep -o -e "[[:alnum:]_-]\+$") )
		vars+=( $(echo -e "$transform_output" | grep -o -e "{% *for.*in [[:alnum:]_-]\+" | grep -o -e "[[:alnum:]_-]\+$") )
		vars+=( $(echo -e "$transform_output" | grep -o -e "{% *if [[:alnum:]_-]\+" | grep -o -e "[[:alnum:]_-]\+$") )
		var_removals=( $(echo -e "$transform_output" | grep -o -e "{% *for [[:alnum:]_-]\+" | grep -o -e "[[:alnum:]_-]\+$") )
		
		unset variables
		declare -A variables
		
		for var in ${vars[@]}
		do
		  variables[$var]=
		done
		
		for rem in ${var_removals[@]}
		do
		  unset variables[$rem]
		done
		
		comment="{# @VARS"
		for var in ${!variables[@]}
		do
		  comment+=" $var"
		done
		comment+=" #}\n"
		
		if [ "$comment" != "{# @VARS #}\n" ]
		then
		  final_output="$comment\n$transform_output"
		  echo -e "$final_output" > $twig
		else
		  echo -e "$transform_output" > $twig
		fi
		
		if [ -f "$twig" ]
		then
		  
		  diff $twig $file 1> /dev/null #diff outpu: 0= no differences | 1= files differs
		  
		  if [ $? -gt 0 ]
		  then
		    echo -e "\033[67G$m_modify_success"
		  else
		    echo -e "\033[67G$m_modify_none"
		  fi

		else
		  echo -e "\033[67G$m_modify_error"
		  echo -e $m_E_NO_FILE_CREATION
		  exit $E_NO_FILE_CREATION
		fi
	fi
done
