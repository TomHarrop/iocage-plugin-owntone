#!/bin/sh

# FIXME!!! change the start script back after testing is finished

export CLASSPATH=$CLASSPATH:/usr/local/share/java:/usr/local/share/java/classes/antlr-3.5.2-complete.jar
export CFLAGS="-march=native -g -I/usr/local/include -I/usr/include"
export LDFLAGS="-L/usr/local/lib -L/usr/lib"
export OWNTONE_VERSION="28.3"

# add owntone user
pw adduser \
	owntone \
	-d /nonexistent \
	-s /usr/sbin/nologin \
	-c "owntone user"

# download owntone
git clone https://github.com/owntone/owntone-server /owntone-build

# mkdir /owntone-build
# wget \
# 	-O /owntone.tar.xz \
# 	"https://github.com/owntone/owntone-server/releases/download/${OWNTONE_VERSION}/owntone-${OWNTONE_VERSION}.tar.xz"

# tar -Jxf /owntone.tar.xz \
# 	-C /owntone-build \
# 	--strip-components 1

cd /owntone-build || exit 1
git checkout 5efe0eeb

# build owntone
autoreconf -vi
./configure --disable-install-systemd

gmake

# install owntone
gmake install

# get the startup script from github
wget -O /usr/local/etc/rc.d/owntone \
	"https://raw.githubusercontent.com/owntone/owntone-server/28.8/scripts/freebsd_start.sh"
chmod 755 /usr/local/etc/rc.d/owntone

# set permissions
chown -R owntone:owntone /usr/local/var/cache/owntone

# tidy up
cd / || exit 1
rm -r /owntone-build
# rm /owntone.tar.xz

# start services
sysrc owntone_enable="YES"
sysrc dbus_enable="YES"
sysrc avahi_daemon_enable="YES"

service dbus start
service avahi-daemon start
service owntone restart
