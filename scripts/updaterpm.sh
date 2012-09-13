#!/bin/sh

#==============================================================================+
# File name   : updaterpm.sh
# Begin       : 2012-06-11
# Last Update : 2012-09-13
# Version     : 2.0.0
#
# Description : This script rebuilds some RPM packages used on CatN Lab.
#               To run this script you need a Virtual Machine (or physical 
#               server) with a minimal CentOS 6 installation and your ssh key on
#               the /root/.ssh/authorized_keys file.
#               This script:
#                - updates the remote CentOS machine;
#                - install all the required packages;
#                - build the RPM packages;
#                - transfer the RPMs on the GIT repository in your PC;
#                - push the modifications to the GitHub repository
#                  https://github.com/fubralimited/CatN-Repo.
#
# Installation : Install a local GIT repository on your machine
#                ~/DATA/GIT/CatN-Repo
#                and initialize it with the remote GIT repository
#                https://github.com/fubralimited/CatN-Repo
#                Update the IP of the building host machine (with CentOS 6 and 
#                your ssh key on the /root/.ssh/authorized_keys file).
#                Update the configuration parameters below to fit your case.
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

# --- CONFIGURATION ---

# target host (minimal CentOS 6 with your public key in /root/.ssh/authorized_keys file)
RPMHOST=127.0.0.1

# SystemTap version (update also the systemtap.spec file - extract it from src.rpm fedora build)
#SYSTEMTAPVER=1.8

# SystemTap release (update also the systemtap.spec file - extract it from src.rpm fedora build)
#SYSTEMTAPREL=4

# SQLite version (update also the sqlite.spec file)
SQLITEVER=3.7.13

# SQLite autoconf source file version
SQLITEFILEVER=3071300

# reboot time
REBOOTTIME=40

# GIT root
GITROOT=~/DATA/GIT

echo "*** CatN RPM Builder (Nicola Asuni - 20120-06-28) ***"

# general 
echo "general update"
ssh root@$RPMHOST 'yum -y update'

# reboot the host (required in case of new kernel)
echo "reboot the host"
ssh root@$RPMHOST 'reboot'

# wait the machine to reboot
echo "waiting for reboot to complete"
sleep $REBOOTTIME

# set MariaDB repository
if ssh root@$RPMHOST 'ls /etc/yum.repos.d/MariaDB.repo >/dev/null'; then
	echo "MariaDB repository already installed"
else
	ssh root@$RPMHOST 'rpm --import http://yum.mariadb.org/RPM-GPG-KEY-MariaDB'
	ssh root@$RPMHOST 'touch /etc/yum.repos.d/MariaDB.repo'
	ssh root@$RPMHOST 'echo "[mariadb]" >> /etc/yum.repos.d/MariaDB.repo'
	ssh root@$RPMHOST 'echo "name = MariaDB" >> /etc/yum.repos.d/MariaDB.repo'
	ssh root@$RPMHOST 'echo "baseurl = http://yum.mariadb.org/5.5/centos6-amd64/" >> /etc/yum.repos.d/MariaDB.repo'
	ssh root@$RPMHOST 'echo "gpgcheck=1" >> /etc/yum.repos.d/MariaDB.repo'
fi

# install EPEL repository
echo "install various packages (if missing)"
ssh root@$RPMHOST 'rpm -Uvh http://download.fedoraproject.org/pub/epel/6/$(uname -m)/epel-release-6-7.noarch.rpm'

# Install additional packages
ssh root@$RPMHOST "yum -y groupinstall 'Development Tools'"
ssh root@$RPMHOST 'yum -y install nano fedora-packager elfutils-devel kernel-devel dkms ncurses-devel readline-devel glibc-devel crash-devel rpm-devel nss-devel avahi-devel latex2html xmlto xmlto-tex publican publican-fedora gtkmm24-devel libglademm24-devel boost-devel dejagnu prelink nc socat glibc-devel glibc-devel.i686 php-devel openssl-devel MariaDB-devel python2-devel'

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

# *** store latest versions on a text file ***

ssh root@$RPMHOST "rm -rf /home/makerpm/CatNRepoLatestVersions.yml"
ssh root@$RPMHOST "touch /home/makerpm/CatNRepoLatestVersions.yml"
ssh root@$RPMHOST "echo '##' >> /home/makerpm/CatNRepoLatestVersions.yml"
ssh root@$RPMHOST "echo '# Latest versions (Ansible format)' >> /home/makerpm/CatNRepoLatestVersions.yml"
ssh root@$RPMHOST "echo '#' >> /home/makerpm/CatNRepoLatestVersions.yml"
ssh root@$RPMHOST "echo '' >> /home/makerpm/CatNRepoLatestVersions.yml"
ssh root@$RPMHOST "echo 'catnrepo:' >> /home/makerpm/CatNRepoLatestVersions.yml"

# get the kernel version
KVER=$(ssh root@$RPMHOST 'echo $(uname -r)')
MVER=$(ssh root@$RPMHOST 'echo $(uname -m)')
FVER="1.el6.$MVER.rpm"
RDIR="https://github.com/fubralimited/CatN-Repo/blob/master/CentOS/$KVER/"

ssh root@$RPMHOST "echo '    repo_dir: '$RDIR'' >> /home/makerpm/CatNRepoLatestVersions.yml"
ssh root@$RPMHOST "echo '    ver_kernel: '$KVER'' >> /home/makerpm/CatNRepoLatestVersions.yml"
ssh root@$RPMHOST "echo '    ver_machine: '$MVER'' >> /home/makerpm/CatNRepoLatestVersions.yml"
ssh root@$RPMHOST "echo '    ver_ext: '$FVER'' >> /home/makerpm/CatNRepoLatestVersions.yml"

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

ssh root@$RPMHOST "echo '    ver_sqlite: '$SQLITEVER'' >> /home/makerpm/CatNRepoLatestVersions.yml"
ssh root@$RPMHOST "echo '    rpmurl_sqlite: '$RDIR'sqlite-'$SQLITEVER'-'$FVER'?raw=true' >> /home/makerpm/CatNRepoLatestVersions.yml"
ssh root@$RPMHOST "echo '    rpm_sqlite: sqlite-'$SQLITEVER'-'$FVER'' >> /home/makerpm/CatNRepoLatestVersions.yml"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

# *** SystemTap ***

echo "\n* SystemTap ...\n"
# download source
#ssh root@$RPMHOST "su -c 'wget -O /home/makerpm/rpmbuild/SOURCES/systemtap-$SYSTEMTAPVER.tar.gz http://sourceware.org/systemtap/ftp/releases/systemtap-$SYSTEMTAPVER.tar.gz' makerpm"
# upload spec file
#scp systemtap.spec root@$RPMHOST:/home/makerpm/rpmbuild/SPECS/systemtap.spec
# patches !!!
#scp PR14348.patch root@$RPMHOST:/home/makerpm/rpmbuild/SOURCES/PR14348.patch
#scp bz837641-staprun-no-linux-types.patch root@$RPMHOST:/home/makerpm/rpmbuild/SOURCES/bz837641-staprun-no-linux-types.patch
# build the RPM packages
#ssh root@$RPMHOST "su -c 'cd /home/makerpm/rpmbuild/SPECS && rpmbuild -ba systemtap.spec' makerpm"
#ssh root@$RPMHOST 'rpm -U --force /home/makerpm/rpmbuild/RPMS/x86_64/systemtap-$SYSTEMTAPVER-$SYSTEMTAPREL.el6.$(uname -m).rpm /home/makerpm/rpmbuild/RPMS/x86_64/systemtap-client-$SYSTEMTAPVER-$SYSTEMTAPREL.el6.$(uname -m).rpm /home/makerpm/rpmbuild/RPMS/x86_64/systemtap-debuginfo-$SYSTEMTAPVER-$SYSTEMTAPREL.el6.$(uname -m).rpm /home/makerpm/rpmbuild/RPMS/x86_64/systemtap-devel-$SYSTEMTAPVER-$SYSTEMTAPREL.el6.$(uname -m).rpm /home/makerpm/rpmbuild/RPMS/x86_64/systemtap-initscript-$SYSTEMTAPVER-$SYSTEMTAPREL.el6.$(uname -m).rpm /home/makerpm/rpmbuild/RPMS/x86_64/systemtap-runtime-$SYSTEMTAPVER-$SYSTEMTAPREL.el6.$(uname -m).rpm /home/makerpm/rpmbuild/RPMS/x86_64/systemtap-sdt-devel-$SYSTEMTAPVER-$SYSTEMTAPREL.el6.$(uname -m).rpm /home/makerpm/rpmbuild/RPMS/x86_64/systemtap-server-$SYSTEMTAPVER-$SYSTEMTAPREL.el6.$(uname -m).rpm /home/makerpm/rpmbuild/RPMS/x86_64/systemtap-testsuite-$SYSTEMTAPVER-$SYSTEMTAPREL.el6.$(uname -m).rpm'

# install SystemTap from default repositories
ssh root@$RPMHOST 'yum -y install systemtap systemtap-client systemtap-devel systemtap-runtime systemtap-initscript systemtap-grapher systemtap-sdt-devel systemtap-server systemtap-testsuite'

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
# download the source code from GitHub
ssh root@$RPMHOST "su -c 'cd /home/makerpm && git clone git://github.com/fubralimited/ServerUsage.git' makerpm"
ssh root@$RPMHOST 'cp -uf /home/makerpm/ServerUsage/server/serverusage_server.spec /home/makerpm/rpmbuild/SPECS/'
ssh root@$RPMHOST 'export SUVER=$(cat /home/makerpm/ServerUsage/VERSION) && cd /home/makerpm/ServerUsage/server && tar -zcvf /home/makerpm/rpmbuild/SOURCES/serverusage_server-$SUVER.tar.gz *'
ssh root@$RPMHOST 'cp -uf /home/makerpm/ServerUsage/client/serverusage_client.spec /home/makerpm/rpmbuild/SPECS/'
ssh root@$RPMHOST 'export SUVER=$(cat /home/makerpm/ServerUsage/VERSION) && cd /home/makerpm/ServerUsage/client && tar -zcvf /home/makerpm/rpmbuild/SOURCES/serverusage_client-$SUVER.tar.gz *'
ssh root@$RPMHOST 'cp -uf /home/makerpm/ServerUsage/client_mdb/serverusage_client_mdb.spec /home/makerpm/rpmbuild/SPECS/'
ssh root@$RPMHOST 'cp -uf /home/makerpm/ServerUsage/client/serverusage_tcpsender.c /home/makerpm/ServerUsage/client_mdb/'
ssh root@$RPMHOST 'export SUVER=$(cat /home/makerpm/ServerUsage/VERSION) && cd /home/makerpm/ServerUsage/client_mdb && tar -zcvf /home/makerpm/rpmbuild/SOURCES/serverusage_client_mdb-$SUVER.tar.gz *'
ssh root@$RPMHOST "su -c 'cd /home/makerpm/rpmbuild/SPECS/ && rpmbuild -ba serverusage_server.spec' makerpm"
ssh root@$RPMHOST "su -c 'cd /home/makerpm/rpmbuild/SPECS/ && rpmbuild -ba serverusage_client.spec' makerpm"
ssh root@$RPMHOST "su -c 'cd /home/makerpm/rpmbuild/SPECS/ && rpmbuild -ba serverusage_client_mdb.spec' makerpm"

# get the version
SUVER=$(ssh root@$RPMHOST 'echo $(cat /home/makerpm/ServerUsage/VERSION)')
ssh root@$RPMHOST "echo '    ver_serverusage: '$SUVER'' >> /home/makerpm/CatNRepoLatestVersions.yml"
ssh root@$RPMHOST "echo '    rpmurl_serverusage_server: '$RDIR'serverusage_server-'$SUVER'-'$FVER'?raw=true' >> /home/makerpm/CatNRepoLatestVersions.yml"
ssh root@$RPMHOST "echo '    rpm_serverusage_server: serverusage_server-'$SUVER'-'$FVER'' >> /home/makerpm/CatNRepoLatestVersions.yml"
ssh root@$RPMHOST "echo '    rpmurl_serverusage_client: '$RDIR'serverusage_client-'$SUVER'-'$FVER'?raw=true' >> /home/makerpm/CatNRepoLatestVersions.yml"
ssh root@$RPMHOST "echo '    rpm_serverusage_client: serverusage_client-'$SUVER'-'$FVER'' >> /home/makerpm/CatNRepoLatestVersions.yml"
ssh root@$RPMHOST "echo '    rpmurl_serverusage_client_mdb: '$RDIR'serverusage_client_mdb-'$SUVER'-'$FVER'?raw=true' >> /home/makerpm/CatNRepoLatestVersions.yml"
ssh root@$RPMHOST "echo '    rpm_serverusage_client_mdb: serverusage_client_mdb-'$SUVER'-'$FVER'' >> /home/makerpm/CatNRepoLatestVersions.yml"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

# *** TCPWebLog ***

echo "\n* TCPWebLog ...\n"

# delete old project (if any)
if ssh root@$RPMHOST 'ls /home/makerpm/TCPWebLog >/dev/null'; then
	# delete old dir
	ssh root@$RPMHOST "rm -rf /home/makerpm/TCPWebLog"
fi
# download the source code from GitHub
ssh root@$RPMHOST "su -c 'cd /home/makerpm && git clone git://github.com/fubralimited/TCPWebLog.git' makerpm"
ssh root@$RPMHOST 'cp -uf /home/makerpm/TCPWebLog/server/tcpweblog_server.spec /home/makerpm/rpmbuild/SPECS/'
ssh root@$RPMHOST 'export SUVER=$(cat /home/makerpm/TCPWebLog/VERSION) && cd /home/makerpm/TCPWebLog/server && tar -zcvf /home/makerpm/rpmbuild/SOURCES/tcpweblog_server-$SUVER.tar.gz *'
ssh root@$RPMHOST 'cp -uf /home/makerpm/TCPWebLog/client/tcpweblog_client.spec /home/makerpm/rpmbuild/SPECS/'
ssh root@$RPMHOST 'export SUVER=$(cat /home/makerpm/TCPWebLog/VERSION) && cd /home/makerpm/TCPWebLog/client && tar -zcvf /home/makerpm/rpmbuild/SOURCES/tcpweblog_client-$SUVER.tar.gz *'
ssh root@$RPMHOST "su -c 'cd /home/makerpm/rpmbuild/SPECS/ && rpmbuild -ba tcpweblog_server.spec' makerpm"
ssh root@$RPMHOST "su -c 'cd /home/makerpm/rpmbuild/SPECS/ && rpmbuild -ba tcpweblog_client.spec' makerpm"

# get the version
TLVER=$(ssh root@$RPMHOST 'echo $(cat /home/makerpm/TCPWebLog/VERSION)')
ssh root@$RPMHOST "echo '    ver_tcpweblog: '$TLVER'' >> /home/makerpm/CatNRepoLatestVersions.yml"
ssh root@$RPMHOST "echo '    rpmurl_tcpweblog_server: '$RDIR'tcpweblog_server-'$TLVER'-'$FVER'?raw=true' >> /home/makerpm/CatNRepoLatestVersions.yml"
ssh root@$RPMHOST "echo '    rpm_tcpweblog_server: tcpweblog_server-'$TLVER'-'$FVER'' >> /home/makerpm/CatNRepoLatestVersions.yml"
ssh root@$RPMHOST "echo '    rpmurl_tcpweblog_client: '$RDIR'tcpweblog_client-'$TLVER'-'$FVER'?raw=true' >> /home/makerpm/CatNRepoLatestVersions.yml"
ssh root@$RPMHOST "echo '    rpm_tcpweblog_client: tcpweblog_client-'$TLVER'-'$FVER'' >> /home/makerpm/CatNRepoLatestVersions.yml"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

# *** LogPipe ***

echo "\n* LogPipe ...\n"

# delete old project (if any)
if ssh root@$RPMHOST 'ls /home/makerpm/LogPipe >/dev/null'; then
	# delete old dir
	ssh root@$RPMHOST "rm -rf /home/makerpm/LogPipe"
fi
# download the source code from GitHub
ssh root@$RPMHOST "su -c 'cd /home/makerpm && git clone git://github.com/fubralimited/LogPipe.git' makerpm"
ssh root@$RPMHOST 'cp -uf /home/makerpm/LogPipe/logpipe.spec /home/makerpm/rpmbuild/SPECS/'
ssh root@$RPMHOST 'export SUVER=$(cat /home/makerpm/LogPipe/VERSION) && cd /home/makerpm/LogPipe && tar -zcvf /home/makerpm/rpmbuild/SOURCES/logpipe-$SUVER.tar.gz *'
ssh root@$RPMHOST "su -c 'cd /home/makerpm/rpmbuild/SPECS/ && rpmbuild -ba logpipe.spec' makerpm"

# get the version
LPVER=$(ssh root@$RPMHOST 'echo $(cat /home/makerpm/LogPipe/VERSION)')
ssh root@$RPMHOST "echo '    ver_logpipe: '$LPVER'' >> /home/makerpm/CatNRepoLatestVersions.yml"
ssh root@$RPMHOST "echo '    rpmurl_logpipe: '$RDIR'logpipe-'$LPVER'-'$FVER'?raw=true' >> /home/makerpm/CatNRepoLatestVersions.yml"
ssh root@$RPMHOST "echo '    rpm_logpipe: logpipe-'$LPVER'-'$FVER'' >> /home/makerpm/CatNRepoLatestVersions.yml"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

# *** Ansible ***

ssh root@$RPMHOST "su -c 'cd /home/makerpm && git clone git://github.com/dhozac/ansible.git yum-install-rpm' makerpm"
#ssh root@$RPMHOST "su -c 'cd /home/makerpm && git clone git://github.com/ansible/ansible.git' makerpm"
ssh root@$RPMHOST "cd /home/makerpm/ansible"
ssh root@$RPMHOST "su -c 'make rpm' makerpm"

# ..............................................................................
# ..............................................................................

echo "\n* Download files and update GIT ...\n"

# create dir if not exist
mkdir -p $GITROOT/CatN-Repo/CentOS/$KVER

# copy the file containing the latest versions
scp root@$RPMHOST:/home/makerpm/CatNRepoLatestVersions.yml $GITROOT/CatN-Repo/CentOS/

scp root@$RPMHOST:/home/makerpm/ansible/rpm-build/ansible-*.noarch.rpm $GITROOT/CatN-Repo/CentOS/$KVER

# get the files
scp root@$RPMHOST:/home/makerpm/rpmbuild/RPMS/x86_64/* $GITROOT/CatN-Repo/CentOS/$KVER

# remove local files
ssh root@$RPMHOST 'rm -rf /home/makerpm/rpmbuild/RPMS/x86_64/*'

# update git
cd $GITROOT/CatN-Repo
git add .
git commit -a -m "'CentOS $KVER'"
git push -u origin master

ssh root@$RPMHOST "shutdown -h now"

#==============================================================================+
# END OF FILE
#==============================================================================+
