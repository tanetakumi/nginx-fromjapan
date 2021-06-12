#! /bin/bash



# -j (--jump) ターゲット             条件に合った際のアクションを指定
# -p (--protocol) プロトコル名   プロトコル名(tcp, udp, icmp, all)を指定
# -s (--source) IPアドレス           送信元アドレス(IPアドレスかホスト名)を指定
# -d (--destination) IPアドレス  送信先アドレス(IPアドレスかホスト名)を指定
# --sport 送信元ポート番号           送信元ポート番号(80, httpなど)を指定
# --dport 宛先ポート番号             宛先ポート番号(80, httpなど）を指定
# -i (--in-interface) デバイス   パケット入力のインターフェースを指定
# -o (--out-interface) デバイス  パケットを出力するインターフェースを指定
# -m (--match) モジュール       特定の通信を検査する拡張モジュールを指定

# MyDNSの通知をするか？
mydns_notify=true

# ユーザー名
MYDNS_USERNAME=<username>
MYDNS_PASSWORD=<pass>

DISCORD_WEBHOOK=<webhook>
# ディスコードに通知関数
function discordNotify(){
    # 書き方が json なので {"key":"value"} にしないといけない
    head='{"username":"Hane","content":"'
    back='"}'
    message=${head}${1}${back}
    curl -H "Accept: application/json" -H "Content-type: application/json" \
    -X POST -d $message $DISCORD_WEBHOOK
}

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

# 25565の通信を許可する。
# iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 25565 -j ACCEPT
# 19132の通信を許可する。
# iptables -A INPUT -m state --state NEW -m udp -p udp --dport 19132 -j ACCEPT
# SSHを許可 (OpenSSHでポート変更済み 27)
# iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 27 -j ACCEPT

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
iptables -N PING_ATTACK
iptables -A PING_ATTACK -m length --length :85 -j ACCEPT
iptables -A PING_ATTACK -j DROP
iptables -A INPUT -p icmp --icmp-type 8 -j PING_ATTACK
# Ping攻撃対策 + Ping Flood攻撃対策
iptables -A PING_ATTACK -p icmp --icmp-type 8 -m length --length :85 -m limit --limit 1/s --limit-burst 4 -j ACCEPT


# Smurf攻撃対策+不要ログ破棄
iptables -A INPUT -d 255.255.255.255 -j DROP
iptables -A INPUT -d 224.0.0.1 -j DROP
# iptables -A INPUT -d 192.168.0.255 -j DROP

# ipset リセット
ipset destroy
# WHITELIST 作成
ipset create -exist WHITELIST hash:net

# ダウンロードフォルダー
DOWNLOAD_FOLDER=/etc/ipset/download
# なければ作成
mkdir -p $DOWNLOAD_FOLDER
# ダウンロード
if curl -o $DOWNLOAD_FOLDER/jp.txt -fsSL https://ipv4.fetus.jp/jp.txt;then
    discordNotify ipfetusSccess"\n"
else
    discordNotify ipfetusError"\n"
fi
# ダウンロードした jp.txt を jp.conf に出力(空白行とコメントアウト行を削除)
# grep -v -e '^\s*#' -e '^\s*$' $DOWNLOAD/jp.txt > $DOWNLOAD/jp.conf
grep -v -e '^\s*#' -e '^\s*$' $DOWNLOAD_FOLDER/jp.txt | while read line
do
    ipset add WHITELIST $line
done

# ipset は -m set --match-set で使用可能
# 25564 を日本からに制限
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 25564 -m set --match-set WHITELIST src -j ACCEPT
# 25565 を日本からに制限
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 25565 -m set --match-set WHITELIST src -j ACCEPT
# 25566 を日本からに制限
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 25566 -m set --match-set WHITELIST src -j ACCEPT
## 19132 を日本からに制限
iptables -A INPUT -m state --state NEW -m udp -p udp --dport 19132 -m set --match-set WHITELIST src -j ACCEPT
# 27は公開鍵だからOK
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 27 -j ACCEPT

# MyDNSへの通知
if $mydns_notify ; then
    # まずはmydnsに通知をする。(testサーバーでやるとまずい)
    if curl -s -u ${MYDNS_USERNAME}:${MYDNS_PASSWORD} https://ipv4.mydns.jp/login.html ;then
        MESSAGE+="MydnsNotifySuccess"
        echo "mydns の通知成功"
    else
        MESSAGE+="\nMydns\bNotify\bError"
        echo "mydns の通知エラー"
    fi
fi
