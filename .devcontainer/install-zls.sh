#!/bin/ash

TEMP_DIR=$1
ZLS_ARCH=$2
ZLS_VERSION=$3
ZLS_MINISIGN_PUBLIC_KEY='RWR+9B91GBZ0zOjh6Lr17+zKf5BoSuFvrx2xSeDE57uIYvnKBGmMjOex'

cd $TEMP_DIR
wget https://builds.zigtools.org/zls-linux-$ZIG_ARCH-$ZIG_VERSION.tar.xz
wget https://builds.zigtools.org/zls-linux-$ZIG_ARCH-$ZIG_VERSION.tar.xz.minisig
minisign -Vm zig-linux-$ZIG_ARCH-$ZIG_VERSION.tar.xz -P "$ZIG_MINISIGN_PUBLIC_KEY"
if [ ! $? ]; then
    echo "Zls download verification failed"
    echo "Check that zls public key is correct"
    echo "script got: $ZLS_MINISIGN_PUBLIC_KEY"
    echo "check it from: https://zigtools.org/zls/install/?zig_version=$ZIG_VERSION&compatibility=full"
    exit 1
fi

tar -xf zls-linux-$ZIG_ARCH-$ZIG_VERSION.tar.xz -C /usr/local/bin