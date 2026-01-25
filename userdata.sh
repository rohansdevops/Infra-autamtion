#!/bin/bash
yum update -y
amazon-linux-extras install nginx1 -y
systemctl start nginx
systemctl enable nginx

PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

cat <<EOF > /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html>
<body>
<h1>CSA DevOps Exam – Instance IP: ${PRIVATE_IP}</h1>
</body>
</html>
EOF

systemctl restart nginx
