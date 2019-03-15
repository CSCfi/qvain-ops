#!/bin/sh
#
# -wvh- (re)build Go on CentOS
#
#       Note that all `yum` and `rpm` commands should be run as root,
#       and the build commands as a non-privileged user.
#

# install rpm-build
yum -y install rpm-build

# get latest source RPM either from the  CentOS build service or, if that's too old, Fedora Rawhide
# CentOS build service:
#   https://cbs.centos.org/koji/packageinfo?packageID=16
# Rawhide mirror:
#   http://www.nic.funet.fi/pub/mirrors/fedora.redhat.com/pub/fedora/linux/development/rawhide/Everything/SRPMS/Packages/g/golang-1.11-0.rc2.1.fc30.src.rpm
curl -O http://www.nic.funet.fi/pub/mirrors/fedora.redhat.com/pub/fedora/linux/development/rawhide/Everything/SRPMS/Packages/g/golang-1.11-0.rc2.1.fc30.src.rpm
curl -O http://www.nic.funet.fi/pub/mirrors/fedora.redhat.com/pub/fedora/linux/development/rawhide/Everything/SRPMS/Packages/g/go-srpm-macros-2-18.fc29.src.rpm

# unpack source RPM so we've got the spec file and any patches
rpm -i golang-1.11-0.rc2.1.fc30.src.rpm
rpm -i go-srpm-macros-2-18.fc29.src.rpm

# edit golang.spec:
# - make sure CentOS required changes are there (diff)
# - point to latest Go if the included source is slightly out of date (e.g. 1.11rc2 --> 1.11)
# - pre-download latest Go source from website https://golang.org/dl/ into rpmbuild/sources
cd rpmbuild/SOURCES && curl -O https://dl.google.com/go/go1.11.src.tar.gz; cd

# install build dependencies
yum-builddep rpmbuild/SPECS/golang.spec

# compile spec file
rpmbuild -ba rpmbuild/SPECS/golang.spec
rpmbuild -ba rpmbuild/SPECS/go-srpm-macros.spec

# remove old Go version if installed
yum remove golang*

# golang apparently needs `mercurial` installed
yum install mercurial

# install the new Go version
rpm -i RPMS/x86_64/golang-* RPMS/noarch/golang-* RPMS/noarch/go-srpm-macros*

# check version
go version
# go version go1.11 linux/amd64

# yay!
