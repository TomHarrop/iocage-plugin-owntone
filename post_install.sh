#!/bin/sh

export ARCH="-march=native"
export CFLAGS="${ARCH} -g -I/usr/local/include -I/usr/include"
export LDFLAGS="-L/usr/local/lib -L/usr/lib"
export INOTIFY_CFLAGS="-I/usr/local/include"
export INOTIFY_LIBS="-L/usr/local/lib -linotify"

export OWNTONE_VERSION="28.8"

# manually install libinotify release 20211018
mkdir /libinotify-build
wget \
	-O /libinotify.tar.gz \
	"https://github.com/libinotify-kqueue/libinotify-kqueue/releases/download/20211018/libinotify-20211018.tar.gz"

tar -zxf /libinotify.tar.gz \
	-C /libinotify-build \
	--strip-components 1

cd /libinotify-build || exit 1
autoreconf -fvi
./configure
make 
make install

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
rm -r /libinotify-build
rm /libinotify.tar.gz
rm -r /owntone-build
rm /owntone.tar.xz
rm -r /mpc-build
rm /mpc.tar.gz

# enable debugging and download a test mp3
sed -i '' 's/loglevel = log/loglevel = debug/' /usr/local/etc/owntone.conf
mkdir -p /srv/music
wget -O /srv/music/Free_Test_Data_1MB_MP3.mp3 \
	https://freetestdata.com/wp-content/uploads/2021/09/Free_Test_Data_1MB_MP3.mp3
chown -R owntone:owntone /srv/music

# start services
sysrc owntone_enable="YES"
sysrc dbus_enable="YES"
sysrc avahi_daemon_enable="YES"

exit 0

service dbus start
service avahi-daemon start
service owntone start
