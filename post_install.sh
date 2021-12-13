#!/bin/sh

git clone https://github.com/owntone/owntone-server.git \
	/owntone-build

exit 0

cd /owntone-build || exit 1

pw adduser \
	owntone \
	-d /nonexistent \
	-s /usr/sbin/nologin \
	-c "owntone user"

