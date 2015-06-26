#!/bin/bash

#library versions
LIBGPG_ERROR_VERSION="1.12"
LIBGCRYPT_VERSION="vmon-eddh"
LIBOTR_VERSION="4.1.0"

#equalit.ie git
EQ_GIT_HOME="git@github.com:/equalitie"
LIBGCRYPT_SRC=$EQ_GIT_HOME/libgcrypt
LIBGCRYPT_EQ_BRANCH=vmon-eddh
LIBNP1SEC_SRC=$EQ_GIT_HOME/np1sec

export LIBRARY_PATH=$/usr/lib/gcc/x86_64-unknown-linux-gnu/4.9.2
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
  curl -O "ftp://ftp.gnupg.org/gcrypt/libgpg-error/libgpg-error-${LIBGPG_ERROR_VERSION}.tar.bz2"
  tar xjf "libgpg-error-${LIBGPG_ERROR_VERSION}.tar.bz2"
fi

# download libgcrypt
if [ ! -e "libgcrypt-${LIBGCRYPT_VERSION}" ]
then
  echo "Downloading libgcrypt-${LIBGCRYPT_VERSION}"
  #curl -O "ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-${LIBGCRYPT_VERSION}.tar.bz2"
  echo $LIBGCRYPT_SRC
  git clone "$LIBGCRYPT_SRC" "libgcrypt-${LIBGCRYPT_VERSION}"
fi

# download libotr
# if [ ! -e "libotr-${LIBOTR_VERSION}.tar.gz" ]
# then
#   echo "Downloading libotr-${LIBOTR_VERSION}.tar.gz"
#   curl -O "https://otr.cypherpunks.ca/libotr-${LIBOTR_VERSION}.tar.gz"
# fi

if [ ! -e "libnp1sec" ]
then
  echo "Downloading lnp1sec"
  git clone "$LIBNP1SEC_SRC" "libnp1sec"
fi

#tar xjf "libgcrypt-${LIBGCRYPT_VERSION}.tar.bz2"
#tar xzf "libotr-${LIBOTR_VERSION}.tar.gz"

#configure and build libgpg-error
# pushd "libgpg-error-${LIBGPG_ERROR_VERSION}"
# BASEDIR=$(dirname $(pwd))
# ${EMSCRIPTEN}/emconfigure ./configure --prefix=${BASEDIR} --enable-static --disable-shared --disable-nls --build=x86-unknown-linux --host=x86-unknown-linux --disable-threads --disable-optimization "CFLAGS=-m32"
# mv src/Makefile src/Makefile.original
# sed -e 's:\$(CC_FOR_BUILD) -I\. -I\$(srcdir) -o $@:\$(CC_FOR_BUILD) -I. -I\$(srcdir) -o $@.js:' \
#     -e 's:\./mkerrcodes:node ./mkerrcodes.js:' src/Makefile.original > src/Makefile
# make clean
# make
# make install
# popd

#patch ec_powm function to use multiplication instead of exponentiation
# patch "libgcrypt-${LIBGCRYPT_VERSION}/mpi/ec.c" patches/ec_powm.patch

# #override powm, mulpowm, and invmod
# cp patches/mpi-pow.c "libgcrypt-${LIBGCRYPT_VERSION}/mpi/"
# cp patches/mpi-mpow.c "libgcrypt-${LIBGCRYPT_VERSION}/mpi/"
# cp patches/mpi-inv.c "libgcrypt-${LIBGCRYPT_VERSION}/mpi/"

#configure and build-libgcrypt
pushd "libgcrypt-${LIBGCRYPT_VERSION}"
git checkout "$LIBGCRYPT_EQ_BRANCH"
./autogen.sh
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

#configure and build libotr
# pushd "libotr-${LIBOTR_VERSION}"
# BASEDIR=$(dirname $(pwd))
# ${EMSCRIPTEN}/emconfigure ./configure --prefix=${BASEDIR} --with-libgcrypt-prefix=${BASEDIR} --disable-static --enable-shared --disable-gcc-hardening --build=x86-linux --host=x86-unknown-linux "CFLAGS=-m32"
# make clean
# make
# make install
# popd

#configure and build libnp1sec
pushd "libnp1sec"
#get rid of libpurple and libevent
mv Makefile.am Makefile.am.original
mv configure.ac configure.ac.original
mv Makefile.am.emscripten Makefile.am
mv configure.ac.emscripten configure.ac
./autogen.sh
BASEDIR=$(dirname $(pwd))
${EMSCRIPTEN}/emconfigure ./configure --prefix=${BASEDIR} --with-libgcrypt-prefix=${BASEDIR} --disable-static --enable-shared --disable-gcc-hardening --build=x86-linux --host=x86-unknown-linux "CFLAGS=-m32" "CXXFLAGS=-I/usr/lib/emscripten/system/lib/libcxxabi/include/ -I${BASEDIR}/libgcrypt-${LIBGCRYPT_VERSION}/src/ -I${BASEDIR}/libgpg-error-${LIBGPG_ERROR_VERSION}/src/"
#make clean
make
make install

#now make the javascript for the google tests
/usr/lib/emscripten/em++ -I/usr/lib/emscripten/system/lib/libcxxabi/include/ -I/home/vmon/doc/code/crypto-emscripten/build/libgcrypt-vmon-eddh/src/ -I/home/vmon/doc/code/crypto-emscripten/build/libgpg-error-1.12/src/ -std=c++11 -Wall -Wextra -Wno-error -s DEMANGLE_SUPPORT=1 -o libnp1sec_test.js contrib/gtest/src/libnp1sec_test-gtest_main.o contrib/gtest/src/libnp1sec_test-gtest-all.o test/libnp1sec_test-crypt_test.o test/libnp1sec_test-test_logger.o test/libnp1sec_test-chat_mocker.o test/libnp1sec_test-chat_mocker_np1sec_plugin.o test/libnp1sec_test-test_message.o test/libnp1sec_test-session_test.o  ./.libs/libnp1sec.so -L/home/vmon/doc/code/crypto-emscripten/build/lib -lgcrypt -lgpg-error

mv Makefile.am Makefile.am.emscripten
mv configure.ac configure.ac.emscripten
mv Makefile.am.original Makefile.am
mv configure.ac.original configure.ac

popd

popd
