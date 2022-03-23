#! /bin/bash

# スクリプトを置いた場所
HOME=$(cd $(dirname $0);pwd)

# MyDNS account + Discord webhook + ip
source $HOME/.env

# SYSTEM directory
SYSTEM_DIR=/etc/systemd/system

# root ユーザでの実行をしてもらう
if [ "`whoami`" != "root" ]; then
    echo "Permission denied"
    exit 1
fi

# 値が入ってるときは　-n "${変数}"　= true
if [ -z "${IPADD}" ]; then
    echo ".env が設定されていません。" 2>&1
    exit 1
fi

# nginx が入っているか
if !(dpkg -s "nginx" > /dev/null 2>&1); then
    echo -e "\033[31mnginx is not installed.\033[m"
    apt-get -y install nginx
else
    echo -e "\033[32mnginx is installed.\033[m"
fi

# nginx の設定

sed -e "s|<server_ip>|${IPADD}|g" ${HOME}/util/nginx-config/nginx.conf > /etc/nginx/nginx.conf
systemctl restart nginx


# --------
# mydnsのserviceの作成とコピー
MYDNS_CMD="${HOME}/mydns.sh"
sed -e "s|<user>|root|g" -e "s|<cmd>|${MYDNS_CMD}|g" ${HOME}/util/system/mydns.service > $SYSTEM_DIR/mydns.service

# mydnsのtimerをコピーして有効化
cp util/system/mydns.timer $SYSTEM_DIR
sudo systemctl enable mydns.timer

echo "mydnsの通知サービスの有効化"


# 全デーモンのリロード
sudo systemctl daemon-reload




# ssh のport の上書き
sed -i -e "s/#\?\s*Port\s*[0-9]\+/Port 27/" /etc/ssh/sshd_config
systemctl restart sshd
echo "ssh Port 27に設定しました"

ufw allow 27/tcp
ufw allow 25565/tcp
ufw allow 25566/tcp
ufw allow 19132/udp
ufw enable