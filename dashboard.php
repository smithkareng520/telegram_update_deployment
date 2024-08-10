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
  <style>
    /* General styles */
    body {
      font-family: Arial, sans-serif;
      margin: 0;
      padding: 0;
      background: linear-gradient(to right, #ff7e5f, #feb47b); /* Gradient background */
      color: #333;
      overflow-x: hidden;
      cursor: url('https://img.icons8.com/ios/24/000000/hammer.png'), auto; /* Custom hammer cursor */
    }

    .container {
      display: flex;
      flex-direction: column;
      align-items: center;
      min-height: 100vh;
      padding: 20px;
    }

    header {
      text-align: center;
      width: 100%;
      margin-bottom: 20px;
    }

    h1 {
      font-size: 2.5rem;
      color: #fff;
      text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.6);
      margin: 0;
    }

    .logout {
      align-self: flex-end;
      margin-bottom: 20px;
    }

    .logout a {
      text-decoration: none;
      color: #fff;
      font-weight: bold;
      background-color: #333;
      padding: 10px 20px;
      border-radius: 5px;
      transition: background-color 0.3s ease;
    }

    .logout a:hover {
      background-color: #555;
    }

    main {
      width: 100%;
      max-width: 1200px;
    }

    .grid-container {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 20px;
      margin-top: 20px;
    }

    .card {
      background: #fff;
      border-radius: 10px;
      box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
      overflow: hidden;
      transition: transform 0.3s ease, box-shadow 0.3s ease;
      cursor: pointer;
    }

    .card:hover {
      transform: scale(1.05);
      box-shadow: 0 8px 16px rgba(0, 0, 0, 0.2);
    }

    .card-content {
      padding: 20px;
      text-align: center;
    }

    .card img {
      width: 60px;
      height: 60px;
      margin-bottom: 15px;
    }

    .card h2 {
      margin: 0;
      font-size: 1.25rem;
      color: #333;
    }

    .card p {
      margin: 10px 0;
      color: #555;
    }

    .card a {
      display: inline-block;
      padding: 10px 20px;
      background-color: #007bff;
      color: #fff;
      text-decoration: none;
      border-radius: 5px;
      transition: background-color 0.3s ease;
    }

    .card a:hover {
      background-color: #0056b3;
    }

    /* Paper plane styles */
    #paper-plane {
      position: absolute;
      width: 60px;
      height: 60px;
      background-image: url('https://img.icons8.com/ios/60/000000/paper-plane.png'); /* Paper plane icon */
      background-size: cover;
      pointer-events: none; /* Ensure the paper plane does not block clicks */
      transition: left 0.1s ease, top 0.1s ease, transform 0.1s ease; /* Smooth transition for position and rotation */
      transform: rotate(45deg); /* Initial rotation */
    }

    /* Missile styles */
    .missile {
      position: absolute;
      width: 30px;
      height: 30px;
      background-image: url('https://img.icons8.com/ios/50/000000/rocket.png'); /* Missile icon */
      background-size: cover;
      pointer-events: none; /* Ensure the missile does not block clicks */
      transition: left 0.2s ease, top 0.2s ease; /* Smooth transition for position */
    }

    /* Click effect styles */
    .click-effect {
      position: absolute;
      pointer-events: none;
      font-size: 1.5rem;
      font-weight: bold;
      transition: opacity 0.3s ease, transform 0.3s ease;
      transform: translate(-50%, -50%);
    }

    /* Hammer hit effect styles */
    .hammer-hit {
      position: absolute;
      width: 50px;
      height: 50px;
      background-image: url('https://img.icons8.com/ios/50/000000/hammer.png'); /* Hammer icon */
      background-size: cover;
      pointer-events: none; /* Ensure the hammer effect does not block clicks */
      transform: translate(-50%, -50%);
      animation: hammer-hit 0.3s ease forwards;
    }

    @keyframes hammer-hit {
      0% {
        transform: translate(-50%, -50%) scale(1);
      }
      50% {
        transform: translate(-50%, -50%) scale(1.2);
      }
      100% {
        transform: translate(-50%, -50%) scale(1);
        opacity: 0;
      }
    }

    /* Score/Hearts styles */
    #hearts {
      position: absolute;
      top: 20px;
      left: 20px;
      display: flex;
      gap: 5px;
    }

    .heart {
      width: 30px;
      height: 30px;
      background-image: url('https://img.icons8.com/ios-filled/50/000000/like.png'); /* Heart icon */
      background-size: cover;
    }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <h1>Welcome to the Dashboard</h1>
    </header>
    <div class="logout">
      <a href="logout.php">Logout</a>
    </div>

    <div class="logout">
      <a href="download.html">bili解析</a>
    </div>
    
    <main>
      <div class="grid-container">
        <div class="card">
          <div class="card-content">
            <img src="https://img.icons8.com/ios/60/000000/windows-10.png" alt="Windows Icon">
            <h2>Download Telegram for Windows</h2>
            <p>Get the latest portable version of Telegram for Windows.</p>
            <a href="file_win64.php">Download</a>
          </div>
        </div>
        <div class="card">
          <div class="card-content">
            <img src="https://img.icons8.com/ios/60/000000/macbook.png" alt="Mac Icon">
            <h2>Download Telegram for Mac</h2>
            <p>Download Telegram for your macOS system.</p>
            <a href="file_mac.php">Download</a>
          </div>
        </div>
        <div class="card">
          <div class="card-content">
            <img src="https://img.icons8.com/ios/60/000000/linux.png" alt="Linux Icon">
            <h2>Download Telegram for Linux</h2>
            <p>Get Telegram for Linux distributions.</p>
            <a href="file_linux.php">Download</a>
          </div>
        </div>
        <div class="card">
          <div class="card-content">
            <img src="https://img.icons8.com/ios/60/000000/android-os.png" alt="Android Icon">
            <h2>Download Telegram for Android</h2>
            <p>Download the APK file for Telegram on Android.</p>
            <a href="file_android.php">Download</a>
          </div>
        </div>
      </div>
      <div id="paper-plane"></div> <!-- Paper plane -->
      <div id="hearts">
        <div class="heart"></div>
        <div class="heart"></div>
        <div class="heart"></div>
        <div class="heart"></div>
        <div class="heart"></div>
      </div> <!-- Hearts display -->
    </main>
  </div>

  <div class="link">
      <a href="link.php">Link</a>
  </div>
  <script>
    let hearts = 5;
    const paperPlane = document.getElementById('paper-plane');
    const heartsContainer = document.getElementById('hearts');
    const missiles = [];
    let lastMissileTime = 0;
    const missileCooldown = 2000; // Cooldown time in milliseconds

    // JavaScript for click effect
    document.addEventListener('click', function(e) {
      console.log('Click detected at', e.clientX, e.clientY);

      const words = ['富强', '民主', '文明', '和谐', '自由', '平等', '公正', '法治', '爱国', '敬业', '诚信', '友善'];
      const selectedWord = words[Math.floor(Math.random() * words.length)];

      const clickEffect = document.createElement('div');
      clickEffect.classList.add('click-effect');
      clickEffect.textContent = selectedWord;
      clickEffect.style.left = `${e.clientX}px`;
      clickEffect.style.top = `${e.clientY}px`;
      clickEffect.style.color = `hsl(${Math.random() * 360}, 100%, 50%)`;
      clickEffect.style.transform = 'translate(-50%, -50%)';

      document.body.appendChild(clickEffect);

      console.log('Effect element added:', clickEffect);

      clickEffect.style.opacity = 1;

      setTimeout(() => {
        clickEffect.style.opacity = 0;
        setTimeout(() => {
          document.body.removeChild(clickEffect);
          console.log('Effect element removed');
        }, 300);
      }, 800);

      // Hammer hit effect
      const hammerHit = document.createElement('div');
      hammerHit.classList.add('hammer-hit');
      hammerHit.style.left = `${e.clientX}px`;
      hammerHit.style.top = `${e.clientY}px`;
      document.body.appendChild(hammerHit);

      setTimeout(() => {
        document.body.removeChild(hammerHit);
      }, 300);
    });

    // JavaScript for paper plane animation
    let targetX = window.innerWidth / 2;
    let targetY = window.innerHeight / 2;

    document.addEventListener('mousemove', function(e) {
      targetX = e.clientX;
      targetY = e.clientY;
    });

    function animatePlane() {
      const planeRect = paperPlane.getBoundingClientRect();
      const planeX = planeRect.left + planeRect.width / 2;
      const planeY = planeRect.top + planeRect.height / 2;

      const dx = targetX - planeX;
      const dy = targetY - planeY;
      const distance = Math.sqrt(dx * dx + dy * dy);

      if (distance > 1) {
        const angle = Math.atan2(dy, dx) * 180 / Math.PI;
        paperPlane.style.left = `${planeX + dx * 0.05 - planeRect.width / 2}px`;
        paperPlane.style.top = `${planeY + dy * 0.05 - planeRect.height / 2}px`;
        paperPlane.style.transform = `rotate(${angle + 45}deg)`;
      } else {
        paperPlane.style.left = `${targetX - planeRect.width / 2}px`;
        paperPlane.style.top = `${targetY - planeRect.height / 2}px`;
        paperPlane.style.transform = `rotate(45deg)`;
      }

      // Launch missile when close
      if (distance < 300) {
        const currentTime = Date.now();
        if (currentTime - lastMissileTime > missileCooldown) {
          launchMissile();
          lastMissileTime = currentTime;
        }
      }

      // Check missile collision
      missiles.forEach((missile, index) => {
        const missileRect = missile.getBoundingClientRect();
        const mouseRect = {
          left: targetX - 10,
          top: targetY - 10,
          right: targetX + 10,
          bottom: targetY + 10
        };

        if (
          missileRect.left < mouseRect.right &&
          missileRect.right > mouseRect.left &&
          missileRect.top < mouseRect.bottom &&
          missileRect.bottom > mouseRect.top
        ) {
          // Collision detected
          reduceHearts();
          document.body.removeChild(missile);
          missiles.splice(index, 1); // Remove the missile from the array
        }
      });

      requestAnimationFrame(animatePlane);
    }

    function launchMissile() {
      const missile = document.createElement('div');
      missile.classList.add('missile');
      missile.style.left = `${paperPlane.offsetLeft + paperPlane.offsetWidth / 2}px`;
      missile.style.top = `${paperPlane.offsetTop + paperPlane.offsetHeight / 2}px`;
      document.body.appendChild(missile);

      missiles.push(missile);

      const dx = targetX - (paperPlane.offsetLeft + paperPlane.offsetWidth / 2);
      const dy = targetY - (paperPlane.offsetTop + paperPlane.offsetHeight / 2);
      const angle = Math.atan2(dy, dx);

      let missileInterval = setInterval(() => {
        missile.style.left = `${missile.offsetLeft + Math.cos(angle) * 5}px`;
        missile.style.top = `${missile.offsetTop + Math.sin(angle) * 5}px`;
        if (missile.offsetLeft > window.innerWidth || missile.offsetTop > window.innerHeight || missile.offsetLeft < 0 || missile.offsetTop < 0) {
          clearInterval(missileInterval);
          document.body.removeChild(missile);
          missiles.splice(missiles.indexOf(missile), 1);
        }
      }, 20);
    }

    function reduceHearts() {
      if (hearts > 0) {
        hearts -= 1;
        console.log('Hearts remaining:', hearts);
        heartsContainer.removeChild(heartsContainer.children[hearts]);
        if (hearts === 0) {
          alert('Game Over');
        }
      }
    }

    animatePlane();
  </script>
</body>
</html>
