#!/bin/bash

set -x
set -e

start_dir=$(pwd)

cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)

SMALT_VERSION="0.7.6"
TABIX_VERSION="master"
SAMTOOLS_VERSION="1.6"

SMALT_DOWNLOAD_URL="http://downloads.sourceforge.net/project/smalt/smalt-${SMALT_VERSION}-bin.tar.gz"
TABIX_DOWNLOAD_URL="https://github.com/samtools/tabix/archive/${TABIX_VERSION}.tar.gz"
SAMTOOLS_DOWNLOAD_URL="https://github.com/samtools/samtools/releases/download/${SAMTOOLS_VERSION}/samtools-${SAMTOOLS_VERSION}.tar.bz2"

# Make an install location
if [ ! -d 'build' ]; then
  mkdir build
fi
cd build
build_dir=$(pwd)

# DOWNLOAD ALL THE THINGS
download () {
  url=$1
  download_location=$2

  if [ -e $download_location ]; then
    echo "Skipping download of $url, $download_location already exists"
  else
    echo "Downloading $url to $download_location"
    wget $url -O $download_location
  fi
}

download $SMALT_DOWNLOAD_URL "smalt-${SMALT_VERSION}.tgz"
download $TABIX_DOWNLOAD_URL "tabix-${TABIX_VERSION}.tgz"
download $SAMTOOLS_DOWNLOAD_URL "samtools-${SAMTOOLS_VERSION}.tbz"

# Update dependencies
if [ "$TRAVIS" = 'true' ]; then
  echo "Using Travis's apt plugin"
else
  sudo apt-get update -q
  sudo apt-get install -y -q zlib1g-dev
fi

# Build all the things
## smalt
cd $build_dir
smalt_dir=$(pwd)/"smalt-${SMALT_VERSION}-bin"
if [ ! -d $smalt_dir ]; then
  tar xzfv smalt-${SMALT_VERSION}.tgz
fi
cd $smalt_dir
if [ ! -e "$smalt_dir/smalt" ]; then
  ln "$smalt_dir/smalt_x86_64" "$smalt_dir/smalt" 
fi

## tabix
cd $build_dir
tabix_dir=$(pwd)/"tabix-$TABIX_VERSION"
if [ ! -d $tabix_dir ]; then
  tar xzfv "${build_dir}/tabix-${TABIX_VERSION}.tgz"
fi
cd $tabix_dir
if [ -e ${tabix_dir}/tabix ]; then
  echo "Already built tabix"
else
  echo "Building tabix"
  make
fi

## samtools
cd $build_dir
samtools_dir=$(pwd)/"samtools-$SAMTOOLS_VERSION"
if [ ! -d $samtools_dir ]; then
  tar xjfv "${build_dir}/samtools-${SAMTOOLS_VERSION}.tbz"
fi
cd $samtools_dir
if [ -e ${samtools_dir}/samtools ]; then
  echo "Already built samtools"
else
  echo "Building samtools"
  sed -i 's/^\(DFLAGS=.\+\)-D_CURSES_LIB=1/\1-D_CURSES_LIB=0/' Makefile
  sed -i 's/^\(LIBCURSES=\)/#\1/' Makefile
  make prefix=${samtools_dir} install
fi

# Setup environment variables
update_path () {
  new_dir=$1
  if [[ ! "$PATH" =~ (^|:)"${new_dir}"(:|$) ]]; then
    export PATH=${new_dir}:${PATH}
  fi
}

update_path ${smalt_dir}
update_path "${tabix_dir}"
update_path "${samtools_dir}"
update_path "${tradis_dir}/bin"

cd $start_dir

cpanm -f Bio::Tradis


set +x
set +e
