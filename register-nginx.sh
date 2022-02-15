#! /bin/bash

# スクリプトを置いた場所
HOME=$(cd $(dirname $0);pwd)

# MyDNS account + Discord webhook + ip
source $HOME/.env

# root ユーザでの実行をしてもらう
if [ "`whoami`" != "root" ]; then
  echo "Permission denied"
  exit 1
fi


if !(dpkg -s "nginx" > /dev/null 2>&1); then
    echo -e "\033[31mnginx is not installed.\033[m"
    apt-get -y install nginx
else
    echo -e "\033[32mnginx is installed.\033[m"
fi

if [ -n ${IPADD} ]; then
    sed -e "s|<server ip>|${IPADD}|g" ${HOME}/util/nginx-config/nginx.conf > /etc/nginx/nginx.conf
    systemctl restart nginx

    ufw allow 25565/tcp
    ufw allow 19132/udp
    ufw allow 25566/tcp
else
    echo ".env が設定されていません。" 2>&1
fi

