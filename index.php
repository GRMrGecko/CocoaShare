<?php
//
//  index.php
//  CocoaShare
//
//  Created by Mr. Gecko on 4/14/10.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

$_CS = array();
$_CS['version'] = "0.1";
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

$_CS['domain'] = $_SERVER['SERVER_NAME'];
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

if (isset($_REQUEST['login'])) {
	$password = $_CS['users'][strtolower($_REQUEST['user'])];
	if ($password==md5($_REQUEST['password'])) {
		setcookie("{$_CS['cookiePrefix']}user", strtolower($_REQUEST['user']), $_CS['time']+31536000/* 1 year */, $_COOKIE['cookiePath'], $_COOKIE['cookieDomain']);
		setcookie("{$_CS['cookiePrefix']}password", md5($_CS['salt'].md5($_REQUEST['password'])), $_CS['time']+31536000/* 1 year */, $_COOKIE['cookiePath'], $_COOKIE['cookieDomain']);
		echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
		?>
		<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
		<plist version="1.0">
		<dict>
			<key>successful</key>
			<true/>
			<key>loggedIn</key>
			<true/>
		</dict>
		</plist>
		<?
	} else {
		echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
		?>
		<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
		<plist version="1.0">
		<dict>
			<key>successful</key>
			<false/>
			<key>error</key>
			<string>Incorrect login details.</string>
			<key>loggedIn</key>
			<false/>
		</dict>
		</plist>
		<?
	}
	exit();
}
if ($_CS['loggedIn']) {
	if (isset($_REQUEST['upload'])) {
		$file = $_FILES[$_REQUEST['upload']];
		$fileNameArr = explode(".", basename($file['name']));
		$fileEtc = strtolower(end($fileNameArr));
		$uploadName = basename($file['name']);
		if (file_exists("./{$uploadName}"))
			unlink("./{$uploadName}");
		if (move_uploaded_file($file['tmp_name'], "./{$uploadName}")) {
			chmod("./{$uploadName}", 0666);
			echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
			?>
			<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
			<plist version="1.0">
			<dict>
				<key>successful</key>
				<true/>
				<key>url</key>
				<string><?=generateURL(rawurlencode($uploadName))?></string>
				<key>loggedIn</key>
				<true/>
			</dict>
			</plist>
			<?
		} else {
			echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
			?>
			<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
			<plist version="1.0">
			<dict>
				<key>successful</key>
				<false/>
				<key>error</key>
				<string>Incorrect access.</string>
				<key>loggedIn</key>
				<true/>
			</dict>
			</plist>
			<?
		}
	} else {
		echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
		?>
		<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
		<plist version="1.0">
		<dict>
			<key>successful</key>
			<false/>
			<key>error</key>
			<string>Incorrect access.</string>
			<key>loggedIn</key>
			<true/>
		</dict>
		</plist>
		<?
	}
} else {
	echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
	?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	<dict>
		<key>successful</key>
		<false/>
		<key>error</key>
		<string>You need to login.</string>
		<key>loggedIn</key>
		<false/>
	</dict>
	</plist>
	<?
}
?>