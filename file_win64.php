<?php
session_start();
if (!isset($_SESSION['loggedin']) || !$_SESSION['loggedin']) {
    header('Location: index.php');
    exit();
}

$filename = '/var/private_data/telegram_win64_portable.zip';
$basename = basename($filename);

if (file_exists($filename)) {
    ob_clean();
    header('Content-Description: File Transfer');
    header('Content-Type: application/zip');
    header('Content-Disposition: attachment; filename="' . $basename . '"');
    header('Content-Length: ' . filesize($filename));
    readfile($filename);
    exit();
} else {
    echo "File not found.";
}
?>
