#!/usr/bin/env bash

# wget https://raw.githubusercontent.com/KumaTea/scripts/main/linux/init.sh && chmod +x init.sh && ./init.sh && rm ./init.sh
# bash -c "$(wget -qLO - https://gh.kmtea.eu/https://github.com/KumaTea/scripts/raw/refs/heads/main/linux/init.sh)"

set -e  # exit on error

SSH_PUB_ROOT="AAAAC3NzaC1lZDI1NTE5AAAAINvrdbh3+SaWX5X12aRlPTrrx4ZDsOBvAo++cUKzwEUG"
SSH_PUB_KUMA="AAAAC3NzaC1lZDI1NTE5AAAAIMRcdADho8lDItb6+3Q4qIyxGlL4Y4PkhcK6Yn0NJyLN"

APT_PACKAGES="bash wget curl nano sudo"  # resolvconf
APT_MIRROR="mirrors.bfsu.edu.cn"


# try if lsb_release exists
if ! command -v lsb_release >/dev/null 2>&1; then
  source /etc/os-release
  # DISTRO=$(lsb_release -is)
  # CODENAME=$(lsb_release -cs)
  # echo $NAME | awk '{print $1}'
  DISTRO=$(echo $NAME | cut -d' ' -f1)
  CODENAME=$VERSION_CODENAME
else
  DISTRO=$(lsb_release -is)
  CODENAME=$(lsb_release -cs)
fi

export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true

case $CODENAME in
  trixie)
    echo "Configure IPv4 for Trixie"

    touch /etc/network/.pve-ignore.interfaces
    mv /etc/network/interfaces /etc/network/interfaces.bak
    cat << EOF >> /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF
    systemctl restart networking
    sleep 10
    ;;
  *)
    ;;
esac

echo "Set ssh stuff"
mkdir -p /root/.ssh
echo "ssh-ed25519 $SSH_PUB_ROOT root" >> /root/.ssh/authorized_keys
touch /root/.hushlogin

echo "Configure APT"

# DEB822 format
case $CODENAME in
  trixie)
    mv /etc/apt/sources.list.d/debian.sources /etc/apt/sources.list.d/debian.sources.bak
    cat << EOF >> /etc/apt/sources.list.d/debian.sources
Types: deb
URIs: https://$APT_MIRROR/debian
Suites: trixie trixie-updates trixie-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: https://$APT_MIRROR/debian-security
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
    ;;
  *)
    mv /etc/apt/sources.list /etc/apt/sources.list.bak

    case "$DISTRO" in
      Debian)
        cat << EOF >> /etc/apt/sources.list
deb https://$APT_MIRROR/debian/ $CODENAME main contrib non-free
deb https://$APT_MIRROR/debian/ $CODENAME-updates main contrib non-free
deb https://$APT_MIRROR/debian/ $CODENAME-backports main contrib non-free
deb https://$APT_MIRROR/debian-security $CODENAME-security main contrib non-free
EOF
        ;;
      Ubuntu)
        cat << EOF >> /etc/apt/sources.list
deb https://$APT_MIRROR/ubuntu/ $CODENAME main restricted universe multiverse
deb https://$APT_MIRROR/ubuntu/ $CODENAME-security main restricted universe multiverse
deb https://$APT_MIRROR/ubuntu/ $CODENAME-updates main restricted universe multiverse
deb https://$APT_MIRROR/ubuntu/ $CODENAME-backports main restricted universe multiverse
EOF
        ;;
      *)
        echo "UNSUPPORTED: $DISTRO"
        exit 1
        ;;
    esac
    ;;
esac

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
echo 'LANG="en_US.UTF-8"' > /etc/default/locale
dpkg-reconfigure --frontend=noninteractive locales
update-locale LANG=en_US.UTF-8

read -p "Add user kuma (y/N): " selection
if [ "$selection" = "y" ]; then
  adduser --disabled-password --gecos "" kuma

  mkdir -p /home/kuma/.ssh
  echo "ssh-ed25519 $SSH_PUB_KUMA kuma" >> /home/kuma/.ssh/authorized_keys
  touch /home/kuma/.hushlogin

  # skip password
  mkdir -p /etc/sudoers.d
  echo "kuma ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/kuma
  usermod -aG sudo kuma

  read -p "Set password for user kuma (y/N): " setpass
  if [ "$setpass" = "y" ]; then
    passwd kuma
  fi
fi

echo "Done."
