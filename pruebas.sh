var="pepe"
echo $var > 1.p
var=`echo $var | sed "s/e/a/g"`
echo $var > 2.p
for arch in *.p
do
echo $arch
done
diff 1 2
if [ ! $? ]
then echo 'bien'; else echo 'mal'; fi
