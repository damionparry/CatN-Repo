%define realver 3071300
%define docver 3071300
%define rpmver 3.7.13
 
Summary:        Library that implements an embeddable SQL database engine
Name:           sqlite
Version:        %{rpmver}
Release:        1%{?dist}
License:        Public Domain
Group:          Applications/Databases
URL:            http://www.sqlite.org/
Source0:        sqlite-autoconf-%{realver}.tar.gz
 
BuildRequires:  ncurses-devel readline-devel glibc-devel
 
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
 
%description
SQLite is a C library that implements an SQL database engine. A large
subset of SQL92 is supported. A complete database is stored in a
single disk file. The API is designed for convenience and ease of use.
Applications that link against SQLite can enjoy the power and
flexibility of an SQL database without the administrative hassles of
supporting a separate database server.  Version 2 and version 3 binaries
are named to permit each to be installed on a single host
 
%package devel
Summary: Development tools for the sqlite3 embeddable SQL database engine
Group: Development/Libraries
Requires: %{name} = %{version}-%{release}
Requires: pkgconfig
 
%description devel
This package contains the header files and development documentation
for %{name}. If you like to develop programs using %{name}, you will need
to install %{name}-devel.
 
%prep
%setup -n %{name}-autoconf-%{realver}
 
%build
%configure
make
 
%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT
 
%clean
rm -rf $RPM_BUILD_ROOT
make clean
 
%files
%defattr(-, root, root)
%doc README
%{_bindir}/sqlite3
%{_libdir}/*.so.*
%{_mandir}/man?/*
 
%files devel
%defattr(-, root, root)
%{_includedir}/*.h
%{_libdir}/*.so
%{_libdir}/pkgconfig/*.pc
%{_libdir}/*.a
%exclude %{_libdir}/*.la
 
%changelog
* Thu May 17 2012 Nicola Asuni - 3.7.12-1
- First version or autoconf.
