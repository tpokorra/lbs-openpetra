#!/bin/bash

# get the key for the OpenPetra packages
rpm --import "http://keyserver.ubuntu.com/pks/lookup?op=get&fingerprint=on&search=0x4796B710919684AC"
dnf -y install mono-core mono-devel libgdiplus-devel nant wget tar sqlite doxygen openssh-clients || exit -1

wget https://github.com/openpetra/openpetra/archive/master.tar.gz
tar xzf master.tar.gz
cd openpetra-master

cat > OpenPetra.build.config << EOF
<?xml version="1.0"?>
<project name="OpenPetra-userconfig">
    <property name="DBMS.Type" value="sqlite"/>
    <property name="DBMS.Password" value=""/>
</project>
EOF

nant quickClean deleteBakFiles minimalGenerateSolution errorCodeDoc apiDoc || exit -1

cd delivery/API-Doc/

#upload to codedoc.openpetra.org
if [ -f ~/.ssh/id_rsa_cronjob ]
then
  localmachine=1
  rsync -avz --delete -e "ssh -o 'StrictHostKeyChecking no' -i ~/.ssh/id_rsa_cronjob" html/ upload@10.0.3.110:codedoc || localmachine=0
  if [ $localmachine -eq 0 ]
  then
    rsync -avz --delete -e "ssh -p 3110 -o 'StrictHostKeyChecking no' -i ~/.ssh/id_rsa_cronjob" html/ upload@codedoc.openpetra.org:codedoc
  fi
fi
