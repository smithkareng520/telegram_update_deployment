<?php
session_start();
if (isset($_SESSION['loggedin']) && $_SESSION['loggedin']) {
    header('Location: dashboard.php');
    exit();
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $_SESSION['loggedin'] = false;
    $username = $_POST['username'];
    $password = $_POST['password'];

    // 从安全目录读取用户名和密码
    $auth_file = '/var/private_data/auth.txt';
    if (file_exists($auth_file)) {
        $auth = file($auth_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        $valid = false;
        foreach ($auth as $line) {
            list($valid_username, $valid_password) = explode(':', $line);
            if ($username === $valid_username && $password === $valid_password) {
                $valid = true;
                break;
            }
        }

        if ($valid) {
            $_SESSION['loggedin'] = true;
            header('Location: dashboard.php');
            exit();
        } else {
            $error = 'Invalid username or password.';
        }
    } else {
        $error = 'Authentication file not found.';
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login</title>
</head>
<body>
    <div>
        <h2>Login</h2>
        <form method="post" action="">
            <div><?php echo htmlspecialchars($error, ENT_QUOTES, 'UTF-8'); ?></div>
            <div>
                <label for="username">Username:</label>
                <input type="text" id="username" name="username" required>
            </div>
            <div>
                <label for="password">Password:</label>
                <input type="password" id="password" name="password" required>
            </div>
            <div>
                <button type="submit">Login</button>
            </div>
        </form>
    </div>
</body>
</html>