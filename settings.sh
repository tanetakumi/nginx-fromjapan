#! /bin/bash

# スクリプトを置いた場所
HOME=$(cd $(dirname $0);pwd)

# 環境変数の読み込み
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

timedatectl set-timezone Asia/Tokyo
echo "タイムゾーンを日本に変更"


# nginx が入っているか
if !(dpkg -s "nginx" > /dev/null 2>&1); then
    echo -e "\033[31mnginx is not installed.\033[m"
    apt-get -y install nginx
else
    echo -e "\033[32mnginx is installed.\033[m"
fi

# ipset が入っているか
if !(dpkg -s "ipset" > /dev/null 2>&1); then
    echo -e "\033[31mipset is not installed.\033[m"
    apt-get -y install ipset
else
    echo -e "\033[32mipset is installed.\033[m"
fi

# nginx の設定
IP=`dig ${IPADD} +short`
sed -e "s|<server_ip>|${IP}|g" ${HOME}/util/nginx-config/nginx.conf > /etc/nginx/nginx.conf
service nginx restart


# +------------------+
# | mydns settings   |
# +------------------+
# mydns.service  mydns.timer
MYDNS_CMD="${HOME}/mydns.sh"
sed -e "s|<user>|root|g" -e "s|<cmd>|${MYDNS_CMD}|g" ${HOME}/util/system/mydns.service > $SYSTEM_DIR/mydns.service
cp util/system/mydns.timer $SYSTEM_DIR

# 有効化
systemctl enable mydns.timer
systemctl start mydns.timer

echo "mydnsの通知サービスの有効化"


# --------
# reboot.service  reboot.timer
sed -e "s|<user>|root|g" -e "s|<cmd>|reboot|g" ${HOME}/util/system/reboot.service > $SYSTEM_DIR/reboot.service
cp util/system/reboot.timer $SYSTEM_DIR

# 有効化
systemctl enable reboot.timer
systemctl start reboot.timer

echo "再起動サービスの有効化"


# --------
# start.service
START_CMD="${HOME}/start.sh"
sed -e "s|<user>|root|g" -e "s|<cmd>|${START_CMD}|g" ${HOME}/util/system/start.service > $SYSTEM_DIR/start.service

# 有効化
systemctl enable start.service

echo "起動サービスの有効化"


# 全デーモンのリロード
sudo systemctl daemon-reload


# ssh のport の上書き
sed -i -e "s/#\?\s*Port\s*[0-9]\+/Port 27/" /etc/ssh/sshd_config
systemctl restart sshd
echo "ssh Port 27に設定しました"



# start.sh の起動
$HOME/start.sh

# start.sh の起動
$HOME/mydns.sh