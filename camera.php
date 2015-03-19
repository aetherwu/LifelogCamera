<?php

$target_path = "uploads/";
$filename = uniqid(rand(), true) . '.jpg';
$target_path = $target_path . $filename; 

if(move_uploaded_file($_FILES['userfile']['tmp_name'], $target_path)) {
    echo "1";
}
else
{ 
	echo "0";
}
?>