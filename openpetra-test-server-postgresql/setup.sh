#!/bin/bash

branch=master
if [ ! -z "$1" ]; then
  branch=$1
fi

yum install -y epel
#install the key from Xamarin
#rpm --import "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF"
yum install -y wget sudo mono-devel mono-mvc mono-winfx mono-wcf libgdiplus-devel liberation-mono-fonts nant NUnit xsp postgresql-server lsb libsodium

# on CentOS7, there is libsodium.so.13
cd /usr/lib64
ln -s libsodium.so.13 libsodium.so
cd -

if [[ "$branch" == "master" ]]
then
  wget https://github.com/openpetra/openpetra/archive/$branch.tar.gz -O sources.tar.gz || exit -1
else
  wget https://github.com/tbits/openpetra/archive/$branch.tar.gz -O sources.tar.gz || exit -1
fi

tar xzf sources.tar.gz || exit -1
dir=$(find . -type d -name openpetra-*)
cd $dir

postgresql-setup initdb
PGHBAFILE=/var/lib/pgsql/data/pg_hba.conf
echo "local all petraserver md5
host all petraserver ::1/128 md5
host all petraserver 127.0.0.1/32 md5" | cat - $PGHBAFILE > /tmp/out && mv -f /tmp/out $PGHBAFILE
/sbin/restorecon -v /var/lib/pgsql/data/pg_hba.conf
systemctl start postgresql
systemctl enable postgresql

# avoid error during createDatabaseUser: sudo: sorry, you must have a tty to run sudo
sed -i "s/Defaults    requiretty/#Defaults    requiretty/g" /etc/sudoers

nant generateTools || exit -1
nant generateORM || exit -1
nant createDatabaseUser || exit -1
nant recreateDatabase resetDatabase || exit -1
nant generateSolution || exit -1

# need this for the tests
wget https://github.com/openpetra/demo-databases/raw/UsedForNUnitTests/demoWith1ledger.yml.gz || exit -1

nant test-without-display || exit -1