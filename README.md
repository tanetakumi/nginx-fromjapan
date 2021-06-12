# nginx settings

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

## Nginx

```
apt-get -y install nginx && apt-get -y install ipset && apt-get -y install iptables
```
