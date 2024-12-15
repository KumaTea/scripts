#!/bin/sh

# wget https://raw.githubusercontent.com/KumaTea/scripts/main/linux/init.sh && chmod +x init.sh && ./init.sh && rm ./init.sh

SSH_PUB_ROOT="AAAAC3NzaC1lZDI1NTE5AAAAINvrdbh3+SaWX5X12aRlPTrrx4ZDsOBvAo++cUKzwEUG"
SSH_PUB_KUMA="AAAAC3NzaC1lZDI1NTE5AAAAIMRcdADho8lDItb6+3Q4qIyxGlL4Y4PkhcK6Yn0NJyLN"

APT_PACKAGES="bash wget curl nano sudo resolvconf"

set -e

export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true

echo "Set ssh stuff"
mkdir -p /root/.ssh
echo "ssh-ed25519 $SSH_PUB_ROOT root" >> /root/.ssh/authorized_keys
touch /root/.hushlogin

read -p "Add user kuma (y/N): " selection
if [ "$selection" = "y" ]; then
  adduser --disabled-password --gecos "" kuma

  mkdir -p /home/kuma/.ssh
  echo "ssh-ed25519 $SSH_PUB_KUMA kuma" >> /home/kuma/.ssh/authorized_keys
  touch /home/kuma/.hushlogin

  # skip password
  echo "kuma ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/kuma
fi

echo "Configure APT"
mv /etc/apt/sources.list /etc/apt/sources.list.bak

cat << EOF >> /etc/apt/sources.list
deb https://mirrors.bfsu.edu.cn/debian bookworm main contrib
deb https://mirrors.bfsu.edu.cn/debian bookworm-updates main contrib
deb https://mirrors.bfsu.edu.cn/debian bookworm-backports main contrib
deb https://mirrors.bfsu.edu.cn/debian-security bookworm-security main contrib
EOF

cat << EOF >> /etc/apt/apt.conf.d/99norecommends
APT::Install-Recommends "0";
APT::Install-Suggests "0";
EOF

echo "Install packages"
# remember to clean up
apt update
apt install -y $APT_PACKAGES
apt clean

echo "Set timezone"
ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

echo "Set locales"
sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
echo 'LANG="en_US.UTF-8"'>/etc/default/locale
dpkg-reconfigure --frontend=noninteractive locales
update-locale LANG=en_US.UTF-8

echo "Done."
