#!/bin/bash
# Build a library rpm set. 

set -x

# Relies on ~/.rpmmacros setting _topdir to what is here ($r, see below)

if [ -n "$1" ]
then
folder=$1
else
folder="."
fi

c=$PWD
o=libboost
d=/var/tmp/$USER
t=x86_64
if [ -d $d ] 
then
  chmod 777 -R $d
  rm -Rf  $d
fi

for i in $folder/*.rpm; do
  if [ -f $i ]; then
    rm $i 
  fi
done



mkdir $d

# clean out  /var/tmp/$USER/rpm
# and then recreates the basic redhat dirs, like SOURCES SPECS there.
r=$d/rpms/$o
spec=${o}.spec

mkdir $d/rpms
mkdir $r
mkdir $r/SOURCES
mkdir $r/SRPMS
mkdir $r/SPECS
mkdir $r/BUILD
mkdir $r/RPMS
mkdir $r/tmp


cp $folder/$spec $r/SPECS

# Now build the binaries and the rpms.
cd $r
rpmbuild -ba --target $t SPECS/$spec

cp $r/RPMS/$t/$o*.$t.rpm $c/$folder