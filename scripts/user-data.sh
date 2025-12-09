#!/bin/bash
# This script runs when a new EC2 instance launches
# It installs Node.js, pulls the app code, and starts the server

set -e

# update system packages
sudo yum update -y

# install Node.js 18
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs git

# clone the app
cd /home/ec2-user
git clone https://github.com/Prashantsit16/Auto-Scaling-Web-App-EC2.git app
cd app/app

# install dependencies and start
npm install
sudo npm start &

echo "App started on port 3000"
