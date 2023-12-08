#!/bin/sh

export CFLAGS="-march=native -g -I/usr/local/include -I/usr/include"
export LDFLAGS="-L/usr/local/lib -L/usr/lib"

export OWNTONE_VERSION="28.8"

# add owntone user
pw adduser \
	owntone \
	-d /nonexistent \
	-s /usr/sbin/nologin \
	-c "owntone user"

# download owntone
mkdir /owntone-build
wget \
	-O /owntone.tar.xz \
	"https://github.com/owntone/owntone-server/releases/download/${OWNTONE_VERSION}/owntone-${OWNTONE_VERSION}.tar.xz"

tar -Jxf /owntone.tar.xz \
	-C /owntone-build \
	--strip-components 1

cd /owntone-build || exit 1

# build owntone
autoreconf -vi
./configure --disable-install-systemd

gmake

# install owntone
gmake install

# disable ipv6
sed -i '' 's/ipv6 = yes/ipv6 = no/' /usr/local/etc/owntone.conf

# get the startup script from github
wget -O /usr/local/etc/rc.d/owntone \
	"https://raw.githubusercontent.com/owntone/owntone-server/${OWNTONE_VERSION}/scripts/freebsd_start.sh"
chmod 755 /usr/local/etc/rc.d/owntone

# set permissions
chown -R owntone:owntone /usr/local/var/cache/owntone

# install mpc
(
# these are used for owntone but interfere with mpc
unset CFLAGS
unset LDFLAGS
wget -O /mpc.tar.gz https://github.com/MusicPlayerDaemon/mpc/archive/refs/tags/v0.34.tar.gz
mkdir /mpc-build
tar -zxf /mpc.tar.gz -C /mpc-build --strip-components 1
cd /mpc-build || exit 1
meson . output
ninja -C output
ninja -C output install
)

# tidy up
cd / || exit 1
rm -r /owntone-build
rm /owntone.tar.xz
rm -r /mpc-build
rm /mpc.tar.gz

# enable debugging and download a test mp3
# sed -i '' 's/loglevel = log/loglevel = debug/' /usr/local/etc/owntone.conf
# mkdir -p /srv/music
# wget -O /srv/music/Free_Test_Data_1MB_MP3.mp3 \
# 	https://freetestdata.com/wp-content/uploads/2021/09/Free_Test_Data_1MB_MP3.mp3
# chown -R owntone:owntone /srv/music

# start services
sysrc owntone_enable="YES"
sysrc dbus_enable="YES"
sysrc avahi_daemon_enable="YES"

service dbus start
service avahi-daemon start
service owntone restart
