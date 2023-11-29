#!/bin/sh

# wget https://raw.githubusercontent.com/KumaTea/scripts/main/linux/init.sh && chmod +x init.sh && ./init.sh && rm ./init.sh

set -e

export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true

echo "Set ssh stuff"
mkdir -p /root/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINvrdbh3+SaWX5X12aRlPTrrx4ZDsOBvAo++cUKzwEUG root" >> /root/.ssh/authorized_keys
touch /root/.hushlogin

read -p "Add user kuma (y/N): " selection
if [ "$selection" = "y" ]; then
adduser --disabled-password --gecos "" kuma

mkdir -p /home/kuma/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMRcdADho8lDItb6+3Q4qIyxGlL4Y4PkhcK6Yn0NJyLN kuma" >> /home/kuma/.ssh/authorized_keys
touch /home/kuma/.hushlogin
fi

echo "Modify sources.list"
mv /etc/apt/sources.list /etc/apt/sources.list.bak

cat << EOF >> /etc/apt/sources.list
deb https://mirrors.tuna.tsinghua.edu.cn/debian bookworm main contrib
deb https://mirrors.tuna.tsinghua.edu.cn/debian bookworm-updates main contrib
deb https://mirrors.tuna.tsinghua.edu.cn/debian bookworm-backports main contrib
deb https://mirrors.tuna.tsinghua.edu.cn/debian-security bookworm-security main contrib
EOF

echo "Set timezone"
ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

echo "Set locales"
sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
echo 'LANG="en_US.UTF-8"'>/etc/default/locale
dpkg-reconfigure --frontend=noninteractive locales
update-locale LANG=en_US.UTF-8

echo "Done."
