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
