#!/bin/bash

E_WRONGARGS=201;
E_NO_CD=202;
E_NO_FILE_CREATION=203;

m_E_WRONGARGS="El primer parametro, en donde se especifica el directorio a reemplazar los templates, es obligatorio";
m_E_NO_CD="No pudo posicionarse en $DIR.";
m_E_NO_FILE_CREATION="No se pudo crear el archivo";
m_modifying="Modificando";
m_modify_success="\e[01;32mMODIFICADO\e[00m";
m_modify_none="\e[01;33mSIN CAMBIOS\e[00m";
m_modify_error="\e[01;31mERROR\e[00m";

#echo_begin_patterns = sed 's/<?\(php\)\? \?\(=\|echo\) \?\$\?/\{\{ /g'
#echo_end_patterns=('}}' 'php?>' '?>')
#if_begin_patterns=('{%' '\<\?if ' '\<\? if ?\(')

if [ -n "$1" ]
then
	DIR=$1
else
	echo $m_E_WRONGARGS;
	exit $E_WRONGARGS;
fi

cd $DIR
if [ `pwd` != "$DIR" ]
then
	echo $m_E_NO_CD;
	exit $E_NO_CD
fi

#Tranforms echos structures
sed_args=("-e 's/<?\(php\)\? \?\(=\|echo\) \?/{{ /g' -e 's/\({{.*\);\? \??>/\1}}/g'")

#Transforms control structures
sed_args+=("-e 's/<?\(php\)\? \?/{% /g' -e 's/\({%.*\)[;:{] \??>/\1%}/g'")

#Transforms variables in structures
sed_args+=("-e 's/\(\({{\|{%\).*\)\\$\(.*\)->\(is\|get\)\(.*\)$/\1\3.\5/g' -e 's/\({{\|{%\)\(.*\)\\$/\1\2/g'")

#Fixes identation
sed_args+=("-e 's/ *\(}}\|%}\)/ \1/g'")

for file in *.php
do
	if [ -f $file ]
	then
		#Modifying message
		echo -n $m_modifying; echo -en "\e[01;38m `basename $file`... \e[00m"
		
		twig="$file.twig"
		
		transform_output=$(eval "sed ${sed_args[@]} $file" 2>&1)
		
		vars=( $(echo -e "$transform_output" | grep -o -e "{{ *[[:alnum:]]\+" | grep -o -e "[[:alnum:]]\+$") )
		#PROBAR!!
		vars+=( $(echo -e "$transform_output" | grep -o -e "{% *if [[:alnum:]]\+" | grep -o -e "[[:alnum:]]\+$") )
		
		declare -A variables
		
		for var in ${vars[@]}
		do
		  variables[$var]=
		done
		
		comment="{# @VARS"
		for var in ${!variables[@]}
		do
		  comment+=" $var"
		done
		comment+=" #}\n"
		
		final_output="$comment\n$transform_output"
		
		echo -e "$final_output" > $twig
		
		if [ -f "$twig" ]
		then
		  
		  diff $twig $file 1> /dev/null #diff outpu: 0= no differences | 1= files differs
		  
		  if [ $? -gt 0 ]
		  then
		    echo -e $m_modify_success
		  else
		    echo -e $m_modify_none
		    #rm $twig
		  fi

		else
		  echo -e $m_modify_error;
		  echo -e $m_E_NO_FILE_CREATION
		  exit $E_NO_FILE_CREATION
		fi
	fi
done
