#!/bin/sh

export CLASSPATH=$CLASSPATH:/usr/local/share/java:/usr/local/share/java/classes/antlr-3.5.2-complete.jar
export CFLAGS="-march=native -g -I/usr/local/include -I/usr/include"
export LDFLAGS="-L/usr/local/lib -L/usr/lib"

# add owntone user
pw adduser \
	owntone \
	-d /nonexistent \
	-s /usr/sbin/nologin \
	-c "owntone user"

# download owntone
git clone https://github.com/owntone/owntone-server.git \
	/owntone-build

cd /owntone-build || exit 1

# build owntone
gmake clean || true
git clean -f

autoreconf -vi
./configure --disable-install-systemd

gmake

# install owntone
gmake install
install -m 755 scripts/freebsd_start.sh /usr/local/etc/rc.d/owntone

# set permissions
chown -R owntone:owntone /usr/local/var/cache/owntone

# tidy up
cd / || exit 1
rm -r /owntone-build

# start services
sysrc owntone_enable="YES"
sysrc dbus_enable="YES"
sysrc avahi_daemon_enable="YES"

service dbus start
service avahi-daemon start
service owntone restart
