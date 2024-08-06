<?php
session_start();
if (!isset($_SESSION['loggedin']) || !$_SESSION['loggedin']) {
    header('Location: index.php');
    exit();
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard</title>
</head>
<body>
    <div>
        <header>
            <h1>Welcome to the Dashboard</h1>
        </header>
        <main>
            <p><a href="file_win64.php">Download Telegram Portable for Windows</a></p>
            <p><a href="file_mac.php">Download Telegram for Mac</a></p>
            <p><a href="file_linux.php">Download Telegram for Linux</a></p>
            <p><a href="file_android.php">Download Telegram for Android</a></p>
            <div>
                <p><a href="logout.php">Logout</a></p>
            </div>
        </main>
    </div>
</body>
</html>