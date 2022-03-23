# nginx settings

ipを日本からに限定したnginx + iptables + ipset　の設定方法です。

## Create User

```
adduser minecraft
```

## Change Login Shell
現状確認
```
grep minecraft /etc/passwd
```
```
usermod -s /bin/bash minecraft
```

## Update Upgrade
```
sudo apt-get update
sudo apt-get upgrade
```

## Nginx + ipset + iptables

```
apt-get -y install nginx && apt-get -y install ipset && apt-get -y install iptables
```
## ファイルのコピー
```
git clone 
cp nginx/* /etc/nginx
cp system/* /etc/systemd/system
cp -r ipset /etc
chmod 755 /etc/ipset/iptables.sh
```

## systemのファイルをコピーした後
```
systemctl enable nginx-reboot.timer
systemctl start nginx-reboot.timer
systemctl enable nginx-start.service
systemctl start nginx-start.service
```
# 鯖さんに説明

簡単にできるように　
1. ufwの設定 port開放するソフト
2. nginxの設定 パケットを自鯖に流す
3. mydnsの設定　ドメインを登録する

## もし自鯖のルータが初期化されたとき

-> nginx の再起動だけすればよい (Linodeの再起動でもOK)
