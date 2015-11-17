<?php
//
//  index.php
//  CocoaShare
//
//  Created by Mr. Gecko on 4/14/10.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

class shortID {
	var $lowerCase = false;
	
	var $check = array(3, 20);
	var $charactersAllCase = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890-_.";
	var $charactersLowerCase = "abcdefghijklmnopqrstuvwxyz1234567890-_.";
	var $alphabet = array();
	var $base = 0;
	
	function __construct($lowerCase = false) {
		$this->lowerCase = $lowerCase;
		$this->alphabet = str_split(($this->lowerCase ? $this->charactersLowerCase : $this->charactersAllCase));
		$this->base = count($this->alphabet);
	}
	
	function shuffleAlphabet($lowerCase = false) {
		$alphabet = str_split(($lowerCase ? $this->charactersLowerCase : $this->charactersAllCase));
		$count = count($alphabet);
		for ($i=0; $i<60; $i++) {
			for ($c=0; $c<$count; $c++) {
				$newPos = rand(0, $count);
				$tmp = $alphabet[$c];
				$alphabet[$c] = $alphabet[$newPos];
				$alphabet[$newPos] = $tmp;
			}
		}
		return implode($alphabet);
	}
	
	function encode($id) {
		if ($id<=0) {
			return "";
		}
		
		$checkString = "";
		foreach ($this->check as $check) {
			$checkString .= $this->alphabet[$id%$check];
		}
		
		$encoded = "";
		while ($id>0) {
			$encoded = $this->alphabet[$id%$this->base].$encoded;
			$id = (int)($id/$this->base);
		}
		
		return $checkString.$encoded;
	}
	
	function decode($encoded) {
		$checkSize = count($this->check);
		if (strlen($encoded)<=$checkSize) {
			return 0;
		}
		
		$id = 0;
		
		$checkString = substr($encoded, 0, $checkSize);
		
		$values = str_split(substr($encoded, $checkSize));
		
		foreach ($values as $value) {
			$id = ($id*$this->base)+array_search($value, $this->alphabet);
		}
		
		$newCheckString = "";
		foreach ($this->check as $check) {
			$newCheckString .= $this->alphabet[$id%$check];
		}
		
		if ($newCheckString!=$checkString) {
			return 0;
		}
		return $id;
	}
}

$_CS = array();
$_CS['version'] = "0.4";
$_CS['time'] = time();

// You are expected to understand a little PHP to use this file.
//
// Put this file in a folder with the permissions set so PHP can write to it (Some people use chmod 777 on the folder).
// After you have all of that setup, you just need to set the information below to make this secure.
// After everything is done, you can enter the address of the folder where this is into CocoaShare's HTTP service and the account information you have set.

$_CS['users'] = array("user" => "5f4dcc3b5aa765d61d8327deb882cf99"); // User list in format UserName => MD5 of Password. To MD5 a string, uncomment the code below the salt and visit the location of this file. The password for the default user is password, be sure to make the username lowercase so it can work well with the system.
$_CS['salt'] = ""; // Put a random bit of string here to make the cookie a bit more random.

error_reporting(0);

/*
// Beginning of MD5 code.
if (isset($_REQUEST['string']))
	echo md5($_REQUEST['string'])."<br />";
?>
<form method="POST">
<input type="text" placeholder="Put in your password." name="string" />
<input type="submit" value="Create MD5" />
</form>
<?
exit();
// End of MD5 code.
*/

/*
// Beginning of short URL shuffling.
header("Content-Type: text/plain");
$shortID = new shortID();
echo "All case: "$shortID->shuffleAlphabet()."\n";
echo "Lower case: "$shortID->shuffleAlphabet(true)."\n";
exit();
*/

$_CS['domain'] = $_SERVER['HTTP_HOST'];
$_CS['port'] = $_SERVER['SERVER_PORT'];
$_CS['ssl'] = ($_SERVER['HTTPS']=="on");

if ($_SERVER['REMOTE_ADDR'])
	$_CS['ip'] = $_SERVER['REMOTE_ADDR'];
if ($_SERVER['HTTP_PC_REMOTE_ADDR'])	
	$_CS['ip'] = $_SERVER['HTTP_PC_REMOTE_ADDR'];
if ($_SERVER['HTTP_CLIENT_IP'])
	$_CS['ip'] = $_SERVER['HTTP_CLIENT_IP'];
if ($_SERVER['HTTP_X_FORWARDED_FOR'])
	$_CS['ip'] = $_SERVER['HTTP_X_FORWARDED_FOR'];

$_CS['installPath'] = substr($_SERVER['SCRIPT_NAME'], 0, strlen($_SERVER['SCRIPT_NAME'])-strlen(end(explode("/", $_SERVER['SCRIPT_NAME']))));

function generateURL($path) {
	global $_CS;
	return "http".($_CS['ssl'] ? "s" : "")."://".$_CS['domain'].(((!$_CS['ssl'] && $_CS['port']==80) || ($_CS['ssl'] && $_CS['port']==443)) ? "" : ":{$_CS['port']}").$_CS['installPath'].$path;
}

$_CS['cookiePrefix'] = "";
$_CS['cookiePath'] = $_CS['installPath'];
$_CS['cookieDomain'] = ".".str_replace("www.", "", $_CS['domain']);

$_CS['loggedIn'] = false;
if (!empty($_COOKIE["{$_CS['cookiePrefix']}user"])) {
	$password = $_CS['users'][$_COOKIE["{$_CS['cookiePrefix']}user"]];
	if (md5($_CS['salt'].$password)==$_COOKIE["{$_CS['cookiePrefix']}password"])
		$_CS['loggedIn'] = true;
}


header("Content-Type: application/json");

$response = array();
$response["version"] = $_CS['version'];

if (isset($_REQUEST['login'])) {
	$password = $_CS['users'][strtolower($_REQUEST['user'])];
	if ($password==md5($_REQUEST['password'])) {
		setcookie("{$_CS['cookiePrefix']}user", strtolower($_REQUEST['user']), $_CS['time']+31536000/* 1 year */, $_COOKIE['cookiePath'], $_COOKIE['cookieDomain']);
		setcookie("{$_CS['cookiePrefix']}password", md5($_CS['salt'].md5($_REQUEST['password'])), $_CS['time']+31536000/* 1 year */, $_COOKIE['cookiePath'], $_COOKIE['cookieDomain']);
		$response["successful"] = true;
		$response["loggedIn"] = true;
		echo json_encode($response);
	} else {
		$response["successful"] = false;
		$response["loggedIn"] = false;
		$response["error"] = "Invalid login details.";
		echo json_encode($response);
	}
	exit();
}
if ($_CS['loggedIn']) {
	$response["loggedIn"] = true;
	if (isset($_REQUEST['upload'])) {
		$file = $_FILES[$_REQUEST['upload']];
		$fileNameArr = explode(".", basename($file['name']));
		$fileEtc = strtolower(end($fileNameArr));
		$uploadName = basename($file['name']);
		$currentID = 0;
		$idFile = "./index.txt";
		if (file_exists($idFile)) {
			$fp = fopen($idFile, "r");
			$currentID = intval(fread($fp, 10));//Max size is 2147483647 for 32bit int.
			fclose($fp);
		}
		if ($currentID!=2147483647) {//Max id reached.
			$currentID++;
			$shortID = new shortID();
			$uploadName = $shortID->encode($currentID).".".$fileEtc;
			$fp = fopen($idFile, "w+");
			fwrite($fp, $currentID);
			fclose($fp);
		}
		
		if (file_exists("./{$uploadName}"))
			unlink("./{$uploadName}");
		if (move_uploaded_file($file['tmp_name'], "./{$uploadName}")) {
			chmod("./{$uploadName}", 0666);
			$response["successful"] = true;
			$response["url"] = generateURL(rawurlencode($uploadName));
			echo json_encode($response);
		} else {
			$response["successful"] = false;
			$response["error"] = "Incorrect access.";
			echo json_encode($response);
		}
	} else {
		$response["successful"] = false;
		$response["error"] = "Invalid request.";
		echo json_encode($response);
	}
} else {
	$response["successful"] = false;
	$response["loggedIn"] = false;
	$response["error"] = "You need to login.";
	echo json_encode($response);
}
?>