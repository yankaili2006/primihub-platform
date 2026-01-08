#!/bin/bash

cd /home/primihub/github/primihub-platform/primihub-service/application

echo "Starting PrimiHub with simple configuration..."

nohup java -jar target/application-1.0-SNAPSHOT.jar \
  --spring.profiles.active=simple \
  > /tmp/primihub-app.log 2>&1 &

echo $! > /tmp/primihub-app.pid

echo "Application started with PID: $(cat /tmp/primihub-app.pid)"
echo "Log file: /tmp/primihub-app.log"
echo "Use 'tail -f /tmp/primihub-app.log' to monitor logs"
