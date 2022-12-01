#! /bin/bash

# スクリプトを置いた場所
HOME=$(cd $(dirname $0);pwd)

# 環境変数の読み込み
source $HOME/.env

# SYSTEM directory
SYSTEM_DIR=/etc/systemd/system

# root ユーザでの実行をしてもらう
if [ "`whoami`" != "root" ]; then
    echo "Permission denied"
    exit 1
fi

# 値が入ってるときは　-n "${変数}"　= true
if [ -z "${MYDNS_PASSWORD}" ]; then
    echo ".env が設定されていません。" 2>&1
    exit 1
fi

timedatectl set-timezone Asia/Tokyo
echo "タイムゾーンを日本に変更"

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

# 全デーモンのリロード
sudo systemctl daemon-reload

# start.sh の起動
$HOME/mydns.sh