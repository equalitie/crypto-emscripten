#!/bin/bash

#library versions
LIBGPG_ERROR_VERSION="1.12"
LIBGCRYPT_VERSION="1.6.2"
LIBOTR_VERSION="4.1.0"

#equalit.ie git
EQ_GIT_HOME=http://github.com/equalitie
LIBGCRYPT_SRC=$(EQ_GIT_HOME)/libgrypt
LIBGCRYPT_EQ_BRANCH=vmon-eddh

#commandline argument
EMSCRIPTEN=$1
if [ "${EMSCRIPTEN}" == "" ]
then
    #environment variable EMSCRIPTEN_ROOT
    EMSCRIPTEN=${EMSCRIPTEN_ROOT}
    if [ "${EMSCRIPTEN}" == "" ]
    then
        #EMSCRIPTEN_ROOT from ~/.emscripten python config file
        EMSCRIPTEN=`./find-emcc.py`
    fi
fi

if [ ! -e "${EMSCRIPTEN}/emcc" ]
then
  echo "emscripten not found at ${EMSCRIPTEN}"
  exit 1
fi

mkdir -p build
mkdir -p build/patches
cp src/patches/* build/patches/

pushd build

# download libgpg-error
if [ ! -e "libgpg-error-${LIBGPG_ERROR_VERSION}.tar.bz2" ]
then
  echo "Downloding libgpg-error-${LIBGPG_ERROR_VERSION}.tar.bz2"
fi

# download libgcrypt
if [ ! -e "libgcrypt-${LIBGCRYPT_VERSION}.tar.bz2" ]
then
  echo "Downloading libgcrypt-${LIBGCRYPT_VERSION}.tar.bz2"
  git clone "$(LIBGCRYPT_SRC)"
fi

# download libotr
# if [ ! -e "libotr-${LIBOTR_VERSION}.tar.gz" ]
# then
#   echo "Downloading libotr-${LIBOTR_VERSION}.tar.gz"
#   curl -O "https://otr.cypherpunks.ca/libotr-${LIBOTR_VERSION}.tar.gz"
# fi

# tar xjf "libgpg-error-${LIBGPG_ERROR_VERSION}.tar.bz2"
# tar xjf "libgcrypt-${LIBGCRYPT_VERSION}.tar.bz2"
# tar xzf "libotr-${LIBOTR_VERSION}.tar.gz"

#configure and build libgpg-error
pushd "libgpg-error-${LIBGPG_ERROR_VERSION}"
BASEDIR=$(dirname $(pwd))
${EMSCRIPTEN}/emconfigure ./configure --prefix=${BASEDIR} --enable-static --disable-shared --disable-nls --build=x86-unknown-linux --host=x86-unknown-linux --disable-threads --disable-optimization "CFLAGS=-m32"
mv src/Makefile src/Makefile.original
sed -e 's:\$(CC_FOR_BUILD) -I\. -I\$(srcdir) -o $@:\$(CC_FOR_BUILD) -I. -I\$(srcdir) -o $@.js:' \
    -e 's:\./mkerrcodes:node ./mkerrcodes.js:' src/Makefile.original > src/Makefile
make clean
make
make install
popd

#patch ec_powm function to use multiplication instead of exponentiation
patch "libgcrypt-${LIBGCRYPT_VERSION}/mpi/ec.c" patches/ec_powm.patch

#override powm, mulpowm, and invmod
cp patches/mpi-pow.c "libgcrypt-${LIBGCRYPT_VERSION}/mpi/"
cp patches/mpi-mpow.c "libgcrypt-${LIBGCRYPT_VERSION}/mpi/"
cp patches/mpi-inv.c "libgcrypt-${LIBGCRYPT_VERSION}/mpi/"

#configure and build-libgcrypt
pushd "libgcrypt-${LIBGCRYPT_VERSION}"
BASEDIR=$(dirname $(pwd))
${EMSCRIPTEN}/emconfigure ./configure --prefix=${BASEDIR} --with-gpg-error-prefix=${BASEDIR} --disable-asm --enable-static --disable-shared --build=x86-unknown-linux --host=x86-unknown-linux "CFLAGS=-m32"
mv config.h config.h.original
sed -e "s:#define HAVE_SYSLOG 1::" \
    -e "s:#define HAVE_SYS_SELECT_H 1::" config.h.original > config.h

mv doc/Makefile doc/Makefile.original
sed -e 's:\$(CC_FOR_BUILD) -o $@ \$(srcdir)/yat2m.c:\gcc -o $@ \$(srcdir)/yat2m.c:' doc/Makefile.original > doc/Makefile

make clean
make
make install
popd

  cd libgrypt && 
  ./configure && make

#configure and build libotr
pushd "libotr-${LIBOTR_VERSION}"
BASEDIR=$(dirname $(pwd))
${EMSCRIPTEN}/emconfigure ./configure --prefix=${BASEDIR} --with-libgcrypt-prefix=${BASEDIR} --disable-static --enable-shared --disable-gcc-hardening --build=x86-linux --host=x86-unknown-linux "CFLAGS=-m32"
make clean
make
make install
popd

popd
