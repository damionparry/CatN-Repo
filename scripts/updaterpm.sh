#!/bin/sh

#==============================================================================+
# File name   : updaterpm.sh
# Begin       : 2012-06-11
# Last Update : 2012-06-28
# Version     : 1.0.0
#
# Description : Update the RPM build host and rebuild all RPM packages.
#
# Author: Nicola Asuni
#
# (c) Copyright:
#               Fubra Limited
#               Manor Coach House
#               Church Hill
#               Aldershot
#               Hampshire
#               GU12 4RQ
#				 UK
#               http://www.fubra.com
#               support@fubra.com
#
# License:
#    Copyright (C) 2012-2012 Fubra Limited
#==============================================================================+

# target host (minimal CentOS 6 with your public key in /root/.ssh/authorized_keys file)
RPMHOST=87.124.34.164

# SystemTap version (update also the systemtap.spec file - extract it from src.rpm fedora build)
SYSTEMTAPVER=1.8

# SQLite version (update also the sqlite.spec file)
SQLITEVER=3.7.13

# SQLite autoconf source file version
SQLITEFILEVER=3071300

# reboot time
REBOOTTIME=60

echo "*** CatN RPM Builder (Nicola Asuni - 20120-06-28) ***"

# general 
echo "general update"
ssh root@$RPMHOST 'yum update'

# reboot the host (required in case of new kernel)
echo "reboot the host"
ssh root@$RPMHOST 'reboot'

# wait the machine to reboot
echo "waiting for reboot to complete"
sleep $REBOOTTIME

# install EPEL repository
echo "install various packages (if missing)"
ssh root@$RPMHOST 'rpm -Uvh http://download.fedoraproject.org/pub/epel/6/$(uname -m)/epel-release-6-7.noarch.rpm'

# Install additional packages
ssh root@$RPMHOST "yum -y groupinstall 'Development Tools'"
ssh root@$RPMHOST 'yum -y install nano fedora-packager elfutils-devel kernel-devel dkms ncurses-devel readline-devel glibc-devel crash-devel rpm-devel nss-devel avahi-devel latex2html xmlto xmlto-tex publican publican-fedora gtkmm24-devel libglademm24-devel boost-devel dejagnu prelink nc socat glibc-devel glibc-devel.i686'
 
# download and install the latest debug modules for the current kernel
if ssh root@$RPMHOST 'ls kernel-debug-debuginfo-$(uname -r).rpm >/dev/null'; then
	# kernel debug modules are alredy updated
	echo "kernel debug modules already updated"
else
	echo "install kernel debug modules"
	ssh root@$RPMHOST 'wget http://debuginfo.centos.org/6/$(uname -m)/kernel-debug-debuginfo-$(uname -r).rpm'
	ssh root@$RPMHOST 'wget http://debuginfo.centos.org/6/$(uname -m)/kernel-debuginfo-$(uname -r).rpm'
	ssh root@$RPMHOST 'wget http://debuginfo.centos.org/6/$(uname -m)/kernel-debuginfo-common-$(uname -m)-$(uname -r).rpm'
	ssh root@$RPMHOST 'rpm -U --force kernel-debug-debuginfo-$(uname -r).rpm kernel-debuginfo-$(uname -r).rpm kernel-debuginfo-common-$(uname -m)-$(uname -r).rpm'
fi

# reboot the host (required in case of new kernel)
echo "reboot the host"
ssh root@$RPMHOST 'reboot'

# wait the machine to reboot
echo "waiting for reboot to complete"
sleep $REBOOTTIME

# user and directory structure to build RPM packages
if ssh root@$RPMHOST 'ls /home/makerpm >/dev/null'; then
	# makerpm user already exist
	echo "makerpm user already exist"
else
	# create a new user to build RPM packages
	echo "create makerpm user and RPM build infrastructure"
	ssh root@$RPMHOST 'useradd makerpm'
	# create the RPM directories
	ssh root@$RPMHOST "su -c 'rpmdev-setuptree' makerpm"
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

# *** SQLite ***

echo "\n* SQLite ...\n"
# download source
ssh root@$RPMHOST "su -c 'wget -O /home/makerpm/rpmbuild/SOURCES/sqlite-autoconf-$SQLITEFILEVER.tar.gz http://www.sqlite.org/sqlite-autoconf-$SQLITEFILEVER.tar.gz' makerpm"
# upload spec file
scp sqlite.spec root@$RPMHOST:/home/makerpm/rpmbuild/SPECS/sqlite.spec
# build the RPM packages
ssh root@$RPMHOST "su -c 'cd /home/makerpm/rpmbuild/SPECS && QA_RPATHS=$[ 0x0001|0x0010 ] rpmbuild -ba sqlite.spec' makerpm"
ssh root@$RPMHOST "rpm -U --force /home/makerpm/rpmbuild/RPMS/x86_64/sqlite-$SQLITEVER-1.el6.x86_64.rpm /home/makerpm/rpmbuild/RPMS/x86_64/sqlite-devel-$SQLITEVER-1.el6.x86_64.rpm"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

# *** SystemTap ***

echo "\n* SystemTap ...\n"
# download source
ssh root@$RPMHOST "su -c 'wget -O /home/makerpm/rpmbuild/SOURCES/systemtap-$SYSTEMTAPVER.tar.gz http://sourceware.org/systemtap/ftp/releases/systemtap-$SYSTEMTAPVER.tar.gz' makerpm"
# upload spec file
scp systemtap.spec root@$RPMHOST:/home/makerpm/rpmbuild/SPECS/systemtap.spec
# build the RPM packages
ssh root@$RPMHOST "su -c 'cd /home/makerpm/rpmbuild/SPECS && rpmbuild -ba systemtap.spec' makerpm"
ssh root@$RPMHOST 'rpm -U --force /home/makerpm/rpmbuild/RPMS/x86_64/systemtap-$SYSTEMTAPVER-1.el6.$(uname -m).rpm /home/makerpm/rpmbuild/RPMS/x86_64/systemtap-client-$SYSTEMTAPVER-1.el6.$(uname -m).rpm /home/makerpm/rpmbuild/RPMS/x86_64/systemtap-debuginfo-$SYSTEMTAPVER-1.el6.$(uname -m).rpm /home/makerpm/rpmbuild/RPMS/x86_64/systemtap-devel-$SYSTEMTAPVER-1.el6.$(uname -m).rpm /home/makerpm/rpmbuild/RPMS/x86_64/systemtap-initscript-$SYSTEMTAPVER-1.el6.$(uname -m).rpm /home/makerpm/rpmbuild/RPMS/x86_64/systemtap-runtime-$SYSTEMTAPVER-1.el6.$(uname -m).rpm /home/makerpm/rpmbuild/RPMS/x86_64/systemtap-sdt-devel-$SYSTEMTAPVER-1.el6.$(uname -m).rpm /home/makerpm/rpmbuild/RPMS/x86_64/systemtap-server-$SYSTEMTAPVER-1.el6.$(uname -m).rpm /home/makerpm/rpmbuild/RPMS/x86_64/systemtap-testsuite-$SYSTEMTAPVER-1.el6.$(uname -m).rpm'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

# reboot the host (required in case of new kernel)
echo "reboot the host"
ssh root@$RPMHOST 'reboot'

# wait the machine to reboot
echo "waiting for reboot to complete"
sleep $REBOOTTIME

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

# *** ServerUsage ***

echo "\n* ServerUsage ...\n"

# delete old project (if any)
if ssh root@$RPMHOST 'ls /home/makerpm/ServerUsage >/dev/null'; then
	# delete old dir
	ssh root@$RPMHOST 'rm -rf /home/makerpm/ServerUsage'
fi
#download the source code from GitHub
ssh root@$RPMHOST "su -c 'cd /home/makerpm && git clone git://github.com/fubralimited/ServerUsage.git' makerpm"
ssh root@$RPMHOST 'cp /home/makerpm/ServerUsage/client/serverusage_client.spec /home/makerpm/rpmbuild/SPECS/'
ssh root@$RPMHOST 'export SUVER=$(cat /home/makerpm/ServerUsage/VERSION) && cd /home/makerpm/ServerUsage/client && tar -zcvf /home/makerpm/rpmbuild/SOURCES/serverusage_client-$SUVER.tar.gz *'
ssh root@$RPMHOST 'cp /home/makerpm/ServerUsage/server/serverusage_server.spec /home/makerpm/rpmbuild/SPECS/'
ssh root@$RPMHOST 'export SUVER=$(cat /home/makerpm/ServerUsage/VERSION) && cd /home/makerpm/ServerUsage/server && tar -zcvf /home/makerpm/rpmbuild/SOURCES/serverusage_server-$SUVER.tar.gz *'
ssh root@$RPMHOST "su -c 'cd /home/makerpm/rpmbuild/SPECS/ && rpmbuild -ba serverusage_client.spec' makerpm"
ssh root@$RPMHOST "su -c 'cd /home/makerpm/rpmbuild/SPECS/ && rpmbuild -ba serverusage_server.spec' makerpm"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

# *** TCPWebLog ***

echo "\n* TCPWebLog ...\n"

# delete old project (if any)
if ssh root@$RPMHOST 'ls /home/makerpm/TCPWebLog >/dev/null'; then
	# delete old dir
	ssh root@$RPMHOST "rm -rf /home/makerpm/TCPWebLog"
fi
#download the source code from GitHub
ssh root@$RPMHOST "su -c 'cd /home/makerpm && git clone git://github.com/fubralimited/TCPWebLog.git' makerpm"
ssh root@$RPMHOST 'cp /home/makerpm/TCPWebLog/client/tcpweblog_client.spec /home/makerpm/rpmbuild/SPECS/'
ssh root@$RPMHOST 'export SUVER=$(cat /home/makerpm/TCPWebLog/VERSION) && cd /home/makerpm/TCPWebLog/client && tar -zcvf /home/makerpm/rpmbuild/SOURCES/tcpweblog_client-$SUVER.tar.gz *'
ssh root@$RPMHOST 'cp /home/makerpm/TCPWebLog/server/tcpweblog_server.spec /home/makerpm/rpmbuild/SPECS/'
ssh root@$RPMHOST 'export SUVER=$(cat /home/makerpm/TCPWebLog/VERSION) && cd /home/makerpm/TCPWebLog/server && tar -zcvf /home/makerpm/rpmbuild/SOURCES/tcpweblog_server-$SUVER.tar.gz *'
ssh root@$RPMHOST "su -c 'cd /home/makerpm/rpmbuild/SPECS/ && rpmbuild -ba tcpweblog_client.spec' makerpm"
ssh root@$RPMHOST "su -c 'cd /home/makerpm/rpmbuild/SPECS/ && rpmbuild -ba tcpweblog_server.spec' makerpm"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

# ..............................................................................
# ..............................................................................

echo "\n* Download files and update GIT ...\n"

# get the kernel version
KVER=$(ssh root@$RPMHOST 'echo $(uname -r)')

# create dir if not exist
mkdir -p /home/nick/DATA/GIT/CatN-Repo/CentOS/$KVER

# get the files
scp root@$RPMHOST:/home/makerpm/rpmbuild/RPMS/x86_64/* /home/nick/DATA/GIT/CatN-Repo/CentOS/$KVER

# remove local files
ssh root@$RPMHOST 'rm -rf /home/makerpm/rpmbuild/RPMS/x86_64/*'

# update git
cd /home/nick/DATA/GIT/CatN-Repo
git add .
git commit -a -m "'CentOS $KVER'"
git push -u origin master

#==============================================================================+
# END OF FILE
#==============================================================================+
