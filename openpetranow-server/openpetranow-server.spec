%define name openpetranow-server
%define version 2014.11.0
%define trunkversion Release2014_11
%define MonoPath /opt/mono
%define OpenPetraServerPath /usr/local/openpetraorg

Summary: server of OpenPetra using Postgresql as database backend
Name: %{name}
Version: %{version}
Release: %{release}
Packager: Timotheus Pokorra <timotheus.pokorra@solidcharity.com>
License: GPL
Group: Office Suite and Productivity
BuildRequires: mono-nant-opt dos2unix nsis gettext
Requires: mono-xsp-opt mono-opt postgresql-server = 9.2 lighttpd lighttpd-fastcgi lsb
BuildRoot: /tmp/buildroot
Source: %{trunkversion}.tar.gz
Source1: base.yml.gz
Source2: plugin_bankimport.tar.gz
Source3: plugin_bankimport_csv.tar.gz
Source4: plugin_bankimport_mt940.tar.gz
Patch1: uinavigation_plugins.patch
Patch2: setup_withremoteclient.patch

%description
Server of OpenPetra using Postgresql as database backend

%prep
[ -d $RPM_BUILD_ROOT ] && [ "/" != "$RPM_BUILD_ROOT" ] && rm -rf $RPM_BUILD_ROOT
%setup  -q -n OpenPetraNow-%{trunkversion}
dos2unix csharp/ICT/Petra/Definitions/UINavigation.yml
%patch1 -p1
dos2unix setup/setup.build
%patch2 -p1
tar xzf ../../SOURCES/plugin_bankimport.tar.gz && mv OpenPetraPlugin_Bankimport-master csharp/ICT/Petra/Plugins/Bankimport
tar xzf ../../SOURCES/plugin_bankimport_csv.tar.gz && mv OpenPetraPlugin_BankimportCSV-master csharp/ICT/Petra/Plugins/BankimportCSV
tar xzf ../../SOURCES/plugin_bankimport_mt940.tar.gz && mv OpenPetraPlugin_BankimportMT940-master csharp/ICT/Petra/Plugins/BankimportMT940

%build
. %{MonoPath}/env.sh
# TODO initdb
#nant nanttasks createDatabaseUser
export NSISDIR=/usr/local/nsis/
export PATH=$NSISDIR:$PATH
nant buildServerCentOSPostgresqlOBS -D:ReleaseID=%{version}.%{release}

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/%{OpenPetraServerPath}
cp -R `pwd`/delivery/bin/tmp/openpetraorg-%{version}.%{release}/* $RPM_BUILD_ROOT/%{OpenPetraServerPath}
mkdir -p $RPM_BUILD_ROOT/%{OpenPetraServerPath}/client
cp `pwd`/delivery/*.exe $RPM_BUILD_ROOT/%{OpenPetraServerPath}/client
cp `pwd`/delivery/Patch-win_%{version}.0_%{version}.%{release}.exe $RPM_BUILD_ROOT/%{OpenPetraServerPath}/client
mkdir -p $RPM_BUILD_ROOT/var/www
ln -s ../../%{OpenPetraServerPath}/asmx $RPM_BUILD_ROOT/var/www/openpetra
ln -s ../bin30 $RPM_BUILD_ROOT/%{OpenPetraServerPath}/asmx/bin
ln -s ../client $RPM_BUILD_ROOT/%{OpenPetraServerPath}/asmx/client
cd $RPM_BUILD_ROOT/%{OpenPetraServerPath}/asmx; ln -s ../js30/* .; cd -
mkdir -p $RPM_BUILD_ROOT/etc/init.d
mv $RPM_BUILD_ROOT/%{OpenPetraServerPath}/openpetraorg-server.sh $RPM_BUILD_ROOT/etc/init.d/openpetra-server
chmod a+x $RPM_BUILD_ROOT/etc/init.d/openpetra-server
dos2unix $RPM_BUILD_ROOT/etc/init.d/openpetra-server
cp ../../SOURCES/base.yml.gz $RPM_BUILD_ROOT/%{OpenPetraServerPath}/db30

%clean
# Clean up after ourselves, but be careful in case someone sets a bad buildroot
[ -d $RPM_BUILD_ROOT ] && [ "/" != "$RPM_BUILD_ROOT" ] && rm -rf $RPM_BUILD_ROOT

%files
%{OpenPetraServerPath}
/etc/init.d/openpetra-server
/var/www/openpetra

%post
echo "For the first install, now run:"
echo "  service openpetra-server init"
echo "  service openpetra-server start"

%changelog
* Mon Nov 17 2014 Timotheus Pokorra <timotheus.pokorra@solidcharity.com>
- release 2014-11
* Wed Jul 30 2014 Timotheus Pokorra <timotheus.pokorra@solidcharity.com>
- release 2014-07
* Sat May 31 2014 Timotheus Pokorra <timotheus.pokorra@solidcharity.com>
- release 2014-05
* Thu Aug 01 2013 Timotheus Pokorra <timotheus.pokorra@solidcharity.com>
- build from github
* Sat Jul 04 2013 Timotheus Pokorra <timotheus.pokorra@solidcharity.com>
- First build
