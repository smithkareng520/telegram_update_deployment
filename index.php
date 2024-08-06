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
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f4f4f4;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .login-container {
            background: #fff;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
            width: 100%;
            max-width: 400px;
            box-sizing: border-box;
        }
        .login-container h2 {
            margin: 0 0 20px;
            font-size: 24px;
            color: #333;
        }
        .login-container form {
            display: flex;
            flex-direction: column;
        }
        .login-container form .form-group {
            margin-bottom: 15px;
        }
        .login-container form .form-group label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
            color: #666;
        }
        .login-container form .form-group input {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            box-sizing: border-box;
        }
        .login-container form .form-group input[type="submit"] {
            background-color: #28a745;
            color: #fff;
            border: none;
            cursor: pointer;
            font-size: 16px;
            transition: background-color 0.3s;
        }
        .login-container form .form-group input[type="submit"]:hover {
            background-color: #218838;
        }
        .login-container .error {
            color: #dc3545;
            margin-bottom: 15px;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="login-container">
        <h2>Login</h2>
        <form method="post" action="">
            <div class="error"><?php echo htmlspecialchars($error, ENT_QUOTES, 'UTF-8'); ?></div>
            <div class="form-group">
                <label for="username">Username:</label>
                <input type="text" id="username" name="username" required>
            </div>
            <div class="form-group">
                <label for="password">Password:</label>
                <input type="password" id="password" name="password" required>
            </div>
            <div class="form-group">
                <input type="submit" value="Login">
            </div>
        </form>
    </div>
</body>
</html>
