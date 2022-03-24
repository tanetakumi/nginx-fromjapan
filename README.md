# nginx settings

ipを日本からに限定したnginx + iptables + ipset　の設定方法です。

## Update Upgrade
```
sudo apt-get update
sudo apt-get upgrade
```
## Create User
```
adduser minecraft
```

## Nginxの特性
server <server_ip>:19132; <server_ip>にDNSを使用するとUDPの接続がうまくできなくなる。

digコマンドを使ってipaddressを取得し、書き込んでnginx を再起動させるのが良い。

自宅のサーバーが半固定IPの場合、mydnsに通知してからこちらでnginx の更新という順番をとるべきであるので、確認してから設定すべきである。

デフォルト設定であると　自宅 4:00再起動　Proxy 5:00再起動
        


### Change Login Shell
現状確認
```
grep minecraft /etc/passwd
```
```
usermod -s /bin/bash minecraft
```