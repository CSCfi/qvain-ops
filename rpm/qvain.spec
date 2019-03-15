# -wvh- spec file for Qvain
#
#       This builds qvain-api and qvain-js packages:
#         - the API backend depends on postgresql 9.6, redis and systemd;
#         - the Javascript backend depends on nothing.
#
#       The packages are built from their respective git repos without the
#       common "create tarball" step in between.
#
#       On upgrade, qvain-api will restart the service if it is running.
#

%global debug_package    %{nil}
%global provider         github.com
%global project          NatLibFi

%define semMajorMinor()  %(echo "%1" | sed 's/^[^0-9]*\\([0-9]*\\)\\.\\([0-9]*\\).*$/\\1.\\2/')

# package version = major.minor, no patch
#%global version          %{?apiVersion:%semMajorMinor %{apiVersion}}%{!?apiVersion:0.0.1}
%global version          %{?apiVersion:%semMajorMinor %{apiVersion}}%{!?apiVersion:0.0.1}

%global api_repo         qvain-api
%global api_version      %{?apiVersion}%{!?apiVersion:%{version}}
%global api_commit       %{?apiCommit}
%global api_shortcommit  %(c=%{api_commit}; echo ${c:0:7})
%global api_release      %{?apiBuild}%{!?apiBuild:1}
%global import_path      %{provider}/%{project}/%{api_repo}

%global js_repo          qvain-js
%global js_version       %{?jsVersion}%{!?jsVersion:%{version}}
%global js_commit        %{?jsCommit}
%global js_shortcommit   %(c=%{js_commit}; echo %{c:0:7})
%global js_release      %{?jsBuild}%{!?jsBuild:1}
%global js_url           %{provider}/%{project}/%{js_repo}

%global app_user         qvain
%global app_group        qvain
%global app_path         /srv/qvain

%global app_description  Qvain is the dataset description service for the Fairdata project.

# commit: git rev-parse --short HEAD 2>/dev/null
# tag:    git describe --always 2>/dev/null
# repo:   git ls-remote --get-url 2>/dev/null
# user:   git config user.name
# email:  git config user.email

Name:       qvain
Version:    %{version}
Release:    1%{?dist}
Summary:    Qvain backend service for the Fairdata project
License:    MIT
Source:     https://%{import_path}/archive/%{api_commit}/%{api_repo}-%{api_shortcommit}.tar.gz
URL:        https://%{import_path}
Provides:   qvain = %{version}
#Provides:   qvain = %{version}-%{release}
#%if 0%{?centos} || 0%{?fedora}
#ExclusiveArch:  %{?go_arches:%{go_arches}}%{!?go_arches:%{ix86} x86_64 %{arm} aarch64 ppc64le s390x}
#%else
#ExclusiveArch:  %{?go_arches:%{go_arches}}%{!?go_arches:x86_64 %{arm} aarch64 ppc64le s390x}
#%endif
Requires(pre): shadow-utils

%description
This package contains Qvain, the dataset description service for the Fairdata project.

%package api
Summary:          Qvain backend service
URL:              https://%{import_path}
Version:          %{api_version}
Release:          %{api_release}%{?dist}
#Provides:         %{api_repo} = %{api_version}-%{release}
Provides:         %{api_repo} = %{api_version}
BuildRequires:    golang >= 1.9.0
#Requires:         %{js_repo} = %{version}-%{release}
Requires:         postgresql >= 9.6, postgresql-server >= 9.6, redis > 3.2
Requires(post):   systemd
Requires(preun):  systemd
Requires(postun): systemd
%description api
%{app_description}

This package contains the backend service binaries.

%package js
Summary:    Qvain frontend application
URL:        https://%{js_url}
Version:    %{js_version}
Release:    %{js_release}%{?dist}
#Requires:   %{api_repo} = %{api_version}-%{release}
Requires:   %{api_repo} = %{api_version}
BuildArch:  noarch
%description js
%{app_description}

This package contains the Javascript frontend code.


%dump
exit 1

%prep
mkdir -p _godeps
mkdir -p _gobuild/src/%{provider}/%{project}
#ln -sf ./_gobuild/src/%{import_path} %{api_repo}-%{api_shortcommit}
ln -sf ./_gobuild/src/%{import_path} %{api_repo}
export GOPATH=$(pwd)/_godeps:$(pwd)/_gobuild
pushd .
cd _gobuild/src/%{provider}/%{project}
if [ -d %{api_repo} ]; then
	cd %{api_repo}
	git pull -v
else
	git clone https://%{import_path} %{api_repo}
	cd %{api_repo}
fi
if [ "%{api_version}" != "v0.0.1" ]; then
	git checkout %{api_version}
fi
go get -v ./cmd/...
popd

if [ -d %{js_repo} ]; then
	cd %{js_repo}
	git pull -v
else
	git clone https://%{js_url} %{js_repo}
	cd %{js_repo}
fi
if [ "%{js_version}" != "v0.0.1" ]; then
	git checkout %{js_version}
fi


%build
export GOPATH=$(pwd)/_godeps:$(pwd)/_gobuild
cd _gobuild/src/%{import_path}
GOBIN=./bin make install

%install
mkdir -p %{buildroot}/%{app_path}/{bin,doc,log,web}
cp -a %{api_repo}/bin/* %{buildroot}/%{app_path}/bin/
cp -a %{api_repo}/doc/* %{buildroot}/%{app_path}/doc/
cp -a %{js_repo}/dist/ %{buildroot}/%{app_path}/web/

%clean
go clean

%files api
%defattr(-,root,root)
%{app_path}/bin/*
%{app_path}/doc/*
%attr(-,%{app_user},%{app_group}) %{app_path}/log/

%files js
%attr(-,%{app_user},%{app_group}) %{app_path}/web/

%pre
getent group %{app_group} >/dev/null || groupadd -r %{app_group}
getent passwd %{app_user} >/dev/null || useradd -r -g %{app_group} -d %{app_home} -s /sbin/nologin -c "Qvain service user" %{app_user}
exit 0

# https://github.com/systemd/systemd/blob/master/src/core/macros.systemd.in

%post
if [ $1 -eq 1 ]; then
	# initial installation
	systemctl --no-reload preset %{?*} &>/dev/null || :

%preun
if [ $1 -eq 0 ]; then
	# removal
	systemctl --no-reload disable --now %{?*} &>/dev/null || : \
fi

%postun
if [ $1 -eq 0 ]; then
	# uninstall
fi
if [ $1 -eq 1 ]; then
        # upgrade
        systemctl try-restart %{?*} &>/dev/null || :
fi


%changelog
* Fri Jun 22 2018 %(echo 'Jbhgre Ina Urzry <jbhgre.ina.urzry@uryfvaxv.sv>' | tr 'A-Za-z' 'N-ZA-Mn-za-m') 0.3.0
- add frontend package
- add systemd logic

* Fri Jun 22 2018 %(echo 'Jbhgre Ina Urzry <jbhgre.ina.urzry@uryfvaxv.sv>' | tr 'A-Za-z' 'N-ZA-Mn-za-m') 0.2.0
- build from git

* Wed Jun 13 2018 %(echo 'Jbhgre Ina Urzry <jbhgre.ina.urzry@uryfvaxv.sv>' | tr 'A-Za-z' 'N-ZA-Mn-za-m') 0.1.0
- initial version
