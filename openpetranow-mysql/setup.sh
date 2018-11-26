#!/bin/bash

branch="master"
if [ ! -z "$1" ]; then
  branch=$1
fi

test=0
if [[ $branch =~ .*test ]]
then
  test=1
fi

# drop repositories that are installed by the docker image
# they become activated by yum-builddep, and then the mirrors might not work
rm -Rf /etc/yum.repos.d/CentOS-Sources.repo /etc/yum.repos.de/CentOS-Vault.repo

yum install -y wget

curl --silent --location https://rpm.nodesource.com/setup_8.x  | bash -
yum -y install nodejs
#node --version
#8.9.4
#npm --version
#5.6.0
npm install -g browserify
npm install -g uglify-es

if [ $test -eq 1 ]
then
  wget https://github.com/tbits/openpetra/archive/$branch.tar.gz -O sources.tar.gz || exit -1
  wget https://github.com/tbits/openpetra-client-js/archive/$branch.tar.gz -O sources-client.tar.gz || exit -1
else
  wget https://github.com/openpetra/openpetra/archive/$branch.tar.gz -O sources.tar.gz || exit -1
  wget https://github.com/openpetra/openpetra-client-js/archive/$branch.tar.gz -O sources-client.tar.gz || exit -1
fi

tar xzf sources-client.tar.gz
cd openpetra-client-js-$branch
npm install
sed -i "s/this.develop = 1;/this.develop = 0;/g" src/lib/navigation.js
sed -i "s/this.debug = 1;/this.debug = 0;/g" src/lib/navigation.js
cd -
tar czf sources-client.tar.gz openpetra-client-js-$branch

wget https://github.com/openpetra/openpetra-i18n/archive/master.tar.gz -O i18n.tar.gz || exit -1

version=`tar xzf sources.tar.gz openpetra-$branch/db/version.txt -O | awk -F- '{print $1}'`

sed -i "s#%{BRANCH}#$branch#g" openpetranow.spec
sed -i "s#%{VERSION}#$version#g" openpetranow.spec

# branding of the package
sed -i "s#%{ORGNAME}#by TBits.net#g" openpetranow.spec
sed -i "s#%{ORGNAMEWITHOUTSPACE}#TBitsNet#g" openpetranow.spec
sed -i "s#%{PUBLISHERURL}#http://www.tbits.net#g" openpetranow.spec
sed -i "s#%{PUBLISHERNAME}#TBits.net#g" openpetranow.spec

if [ $test -eq 1 ]
then
  mv openpetranow.spec openpetranow-mysql-test.spec
  sed -i "s#%{PKGNAME}#openpetranow-mysql-test#g" openpetranow-mysql-test.spec
else
  mv openpetranow.spec openpetranow-mysql.spec
  sed -i "s#%{PKGNAME}#openpetranow-mysql#g" openpetranow-mysql.spec
fi
