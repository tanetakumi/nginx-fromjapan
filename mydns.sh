#! /bin/bash

# スクリプトを置いた場所
HOME=$(cd $(dirname $0);pwd)

# MyDNS account + Discord webhook
source $HOME/.env

# ディスコード通知関数
function discordNotify(){
    curl -H "Accept: application/json" -H "Content-type: application/json" -X POST -d "{\"username\":\"HaneBot\",\"content\":\"${1}\"}" $DISCORD_WEBHOOK
}

# まずはmydnsに通知をする。(testサーバーでやるとまずい)
if curl -s -u ${MYDNS_USERNAME}:${MYDNS_PASSWORD} https://ipv4.mydns.jp/login.html ;then
    discordNotify "Succeeded to notify ipaddress to MyDNS"
    echo "mydns の通知成功"
else 
    discordNotify "[ERROR]Failed to notify ipaddress to MyDNS"
    echo "mydns の通知エラー"
fi