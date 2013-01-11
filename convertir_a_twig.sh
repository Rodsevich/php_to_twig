#!/bin/bash

E_WRONGARGS=201;
E_NO_CD=202;
E_NO_FILE_CREATION=203;

m_E_WRONGARGS="El primer parametro, en donde se especifica el directorio a reemplazar los templates, es obligatorio";
m_E_NO_CD="No pudo posicionarse en $DIR.";
m_E_NO_FILE_CREATION="No se puedo crear el archivo";
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

for arch in *.php
do
	if [ -f $arch ]
	then
		echo -n $m_modifying; echo -en "\e[01;38m `basename $arch`... \e[00m"
		twig="$arch.twig"
		cat $arch > "./$twig"
		if [ -f "$twig" ]
		then
		  
		  transform=`cat $arch`
		  
		  #Tranforms echos structures
		  $transform=${`echo $transform` | sed -e 's/<?\(php\)\? \?\(=\|echo\) \?\$\?/\{\{ /g' -e 's/\({{.*\)?>/ }}/g'}
		  #Transforms control structures
		  $transform=${`echo $transform` | sed -e 's/<?\(php\)\? \?/{% /g' -e "s/\({%.*\) \?[;:{] ?>/\1 %}/g"}
		  #Transforms variables
		  $transform=${`echo $transform` | sed -e "s/\({{\|{%.*\)$/VARIABLE=> /g"}
		  
		  $transform > $twig

		else
		  echo $m_modify_error;
		  echo $m_E_NO_FILE_CREATION
		  exit $E_NO_FILE_CREATION
		fi
	fi
done
