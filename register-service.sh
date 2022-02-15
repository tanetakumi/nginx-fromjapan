#! /bin/bash

# スクリプトを置いた場所
HOME=$(cd $(dirname $0);pwd)
SYSTEM_DIR=/etc/systemd/system

# root ユーザでの実行をしてもらう
if [ "`whoami`" != "root" ]; then
  echo "Permission denied"
  exit 1
fi

MYDNS_SERVICE="${HOME}/mydns.sh"
sed -e "s|<user>|root|g" -e "s|<cmd>|${MYDNS_SERVICE}|g" ${HOME}/util/system/mydns.service > $SYSTEM_DIR/mydns.service
cp util/system/mydns.timer $SYSTEM_DIR

sudo systemctl daemon-reload

sudo systemctl enable mydns.timer