<?php echo "lapo ronga" ?> <?= "Uy nos rompieron el orto" ?>
<? if($pepe == "pepe"): ?>
<?php echo "perindonga" ?>
<? endif; ?>
<?= $var; ?>
<? else: ?>
<? foreach(%@$#%^@^) { ?>
<?php echo $arreglo['item']; ?>
<?= $obeto->getItem() ?>
<? if($objeto->isAlgo()) { ?>

<?php foreach ($usuarios as $usuario): ?>
	<tr>
		<td><?= $usuario['username']?></td>
		<td><?=	$usuario['nomyapp']; ?></td>
		<td><?= $usuario['email']?></td>
		<td><?= $usuario['telefono']?></td>
		<td><a href="<?=PUBLIC_DIR?>controller/ver_perfil.php?id=<?=$usuario['id']?>">ver perfil</a></td>
	</tr>
	<?php endforeach;?>
