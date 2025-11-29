#!/bin/bash
set -e

# 1. Prevent interactive prompts
export DEBIAN_FRONTEND=noninteractive

# --- FIX PART 1: FORCE ENVIRONMENT VARIABLES ---
# This ensures PM2 saves the dump file to /root/.pm2/
export HOME=/root
export PM2_HOME=/root/.pm2

# 2. Update and Install Prerequisites
apt-get update -y
apt-get install -y curl

# 3. Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt-get install -y nodejs

# 4. Install Stress Tool
apt-get install -y stress || true

# 5. Install PM2
npm install -g pm2

# 6. Create app directory
mkdir -p /var/www/app
cd /var/www/app

# 7. Create server file
cat <<EOF > server.js
const http = require('http');
const os = require('os');
const port = ${app_port};

function getLocalIp() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return 'Unknown IP';
}

const localIp = getLocalIp();

const requestHandler = (request, response) => {
  response.writeHead(200, {'Content-Type': 'text/plain'});
  response.end('Hello! Node.js is running on Port ' + port + ' | Server IP: ' + localIp + '\\n');
}

const server = http.createServer(requestHandler);

server.listen(port, '0.0.0.0', (err) => {
  if (err) {
    return console.log('Error:', err);
  }
  console.log('Server is listening on port ' + port + ' and IP ' + localIp);
});
EOF

# 8. Start the app & Ensure Persistence
# Start the app
pm2 start server.js --name "simple-app"

# --- FIX PART 2: CORRECT ORDER & EXPLICIT PATHS ---

# A. Create the SystemD Service explicitly for root
# This tells the OS: "On boot, look into /root for instructions"
pm2 startup systemd -u root --hp /root

# B. Save the process list
# Because we exported HOME=/root at the top, this saves to /root/.pm2/dump.pm2
# This matches exactly where the SystemD service will look.
pm2 save

echo "User Data Script Finished Successfully!"



