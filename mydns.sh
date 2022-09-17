#! /bin/bash

# スクリプトを置いた場所
HOME=$(cd $(dirname $0);pwd)

# MyDNS account + Discord webhook
source $HOME/.env

# ディスコードに通知関数
function discordNotify(){
    # 書き方が json なので {"key":"value"} にしないといけない
    head='{"username":"Hane","content":"'
    back='"}'
    message=${head}${1}${back}
    echo $message
    curl -H "Accept: application/json" -H "Content-type: application/json" \
    -X POST -d $message $DISCORD_WEBHOOK
}

# まずはmydnsに通知をする。(testサーバーでやるとまずい)
if curl -s -u ${MYDNS_USERNAME}:${MYDNS_PASSWORD} https://ipv4.mydns.jp/login.html ;then
    discordNotify "Succeeded_to_notify_ipaddress_to_MyDNS"
    echo "mydns の通知成功"
else 
    discordNotify "[ERROR]Failed_to_notify_ipaddress_to_MyDNS"
    echo "mydns の通知エラー"
fi