#! /bin/bash

# スクリプトを置いた場所
HOME=$(cd $(dirname $0);pwd)

LF=$'\n'

if [ ! -f $HOME/.env ]; then
    echo "Create a .env file."
    echo "# discordのwebhook${LF}DISCORD_WEBHOOK=${LF}${LF}# MyDNSの設定${LF}\
MYDNS_USERNAME=${LF}MYDNS_PASSWORD=${LF}${LF}# 接続ip${LF}IP=" > $HOME/.env
else
    echo ".env file exists."
fi
