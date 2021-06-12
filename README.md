# nginx settings

ipを日本からに限定したnginx + iptables + ipset　の設定方法です。

/etc/nginx/
/etc/systemd/system/
/etc/ipset/
上の3つのフォルダにそれぞれを導入してください

## Create User

```
useradd -m minecraft
passwd minecraft
```

## Change Login Shell

```
usermod -s /bin/bash minecraft
```
現状確認
```
grep minecraft /etc/passwd
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
