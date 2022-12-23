#! /bin/bash

# スクリプトを置いた場所
HOME=$(cd $(dirname $0);pwd)

# 環境変数の読み込み
# MyDNS account + Discord webhook
source $HOME/.env

# root ユーザでの実行をしてもらう
if [ "`whoami`" != "root" ]; then
  echo "Permission denied"
  exit 1
fi

# ディスコード通知関数
function discordNotify(){
    curl -H "Accept: application/json" -H "Content-type: application/json" -X POST -d "{\"username\":\"HaneBot\",\"content\":\"${1}\"}" $DISCORD_WEBHOOK
}


# +-----------------------+
# |   iptables settings   |
# +-----------------------+
# -j (--jump) ターゲット             条件に合った際のアクションを指定
# -p (--protocol) プロトコル名   プロトコル名(tcp, udp, icmp, all)を指定
# -s (--source) IPアドレス           送信元アドレス(IPアドレスかホスト名)を指定
# -d (--destination) IPアドレス  送信先アドレス(IPアドレスかホスト名)を指定
# --sport 送信元ポート番号           送信元ポート番号(80, httpなど)を指定
# --dport 宛先ポート番号             宛先ポート番号(80, httpなど）を指定
# -i (--in-interface) デバイス   パケット入力のインターフェースを指定
# -o (--out-interface) デバイス  パケットを出力するインターフェースを指定
# -m (--match) モジュール       特定の通信を検査する拡張モジュールを指定

# 設定をクリア
iptables -F
iptables -X

# 基本方針[1]
# 受信と転送は破棄、送信はすべて許可
# サーバーが受信するパケットを拒否
iptables -P INPUT DROP
# サーバーが転送させるパケットを拒否
iptables -P FORWARD DROP
# サーバーが送信するパケットを許可
iptables -P OUTPUT ACCEPT


#ローカルループバックの接続を許可する。
iptables -A INPUT -i lo -j ACCEPT
# すでに確立した通信(established)および関連したパケット(related)を許可する
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT



# ping(icmp) echo許可
iptables -A INPUT -p icmp --icmp-type 0 -j ACCEPT
# ping(icmp) echo reply許可
iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT


#IP Spoofing攻撃対策
iptables -A INPUT -s 127.0.0.1/8 -j DROP
iptables -A INPUT -s 10.0.0.0/8 -j DROP
iptables -A INPUT -s 172.16.0.0/12 -j DROP
iptables -A INPUT -s 192.168.0.0/16 -j DROP
iptables -A INPUT -s 192.168.0.0/24  -j DROP

# サーバ攻撃対策関連
# データを持たないパケットの接続を破棄
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
# SYNflood攻撃と追われる接続を破棄
iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
# ステルススキャンと思われる接続を破棄
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP


# Ping攻撃対策
#iptables -N PING_ATTACK
#iptables -A PING_ATTACK -m length --length :85 -j ACCEPT
#iptables -A PING_ATTACK -j DROP
#iptables -A INPUT -p icmp --icmp-type 8 -j PING_ATTACK
# Ping攻撃対策 + Ping Flood攻撃対策
#iptables -A PING_ATTACK -p icmp --icmp-type 8 -m length --length :85 -m limit --limit 1/s --limit-burst 4 -j ACCEPT

# Smurf攻撃対策+不要ログ破棄
iptables -A INPUT -d 255.255.255.255 -j DROP
iptables -A INPUT -d 224.0.0.1 -j DROP
# iptables -A INPUT -d 192.168.0.255 -j DROP

# ipset リセット
ipset destroy
# WHITELIST 作成
ipset create -exist WHITELIST hash:net

# ダウンロード
if curl -o $HOME/jp.txt -fsSL https://ipv4.fetus.jp/jp.txt; then
    discordNotify "Succeeded to get Japanese ipaddresses from ipv4.fetus.jp\n"
else
    discordNotify "[ERROR]Failed to get Japanese ip addresses from ipv4.fetus.jp\n"
fi
# ダウンロードした jp.txt を jp.conf に出力(空白行とコメントアウト行を削除)
# grep -v -e '^\s*#' -e '^\s*$' $DOWNLOAD/jp.txt > $DOWNLOAD/jp.conf
grep -v -e '^\s*#' -e '^\s*$' $HOME/jp.txt | while read line
do
    ipset add WHITELIST $line
done

# ipset は -m set --match-set で使用可能
# 27も日本からに制限
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 27 -m set --match-set WHITELIST src -j ACCEPT

# ----- Server1  JAVA + BE -----
# 25565 を日本からに制限
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 25565 -m set --match-set WHITELIST src -j ACCEPT
# 19132 を日本からに制限
iptables -A INPUT -m state --state NEW -m udp -p udp --dport 19132 -m set --match-set WHITELIST src -j ACCEPT

# ----- Server2  JAVA + BE -----
# 25569 を日本からに制限
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 25569 -m set --match-set WHITELIST src -j ACCEPT
# 19140 を日本からに制限
iptables -A INPUT -m state --state NEW -m udp -p udp --dport 19140 -m set --match-set WHITELIST src -j ACCEPT

# +-----------------------+
# |    nginx settings     |
# +-----------------------+
# nginx の設定
IP=`dig ${IPADD} +short`
sed -e "s|<server_ip>|${IP}|g" ${HOME}/util/nginx-config/nginx.conf > /etc/nginx/nginx.conf
service nginx restart
