<?php 

// directory
$directory = "uploads/";
 
// file type
$images = glob("" . $directory . "*.jpg");
 
foreach ($images as $image) {
	echo '<img src="' . $image . '" width="960" /> ';
} 
 
?>
<meta http-equiv="refresh" content="15">