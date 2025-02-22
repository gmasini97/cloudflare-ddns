#!/bin/ash

TEMP_DIR=$1
ZIG_ARCH=$2
ZIG_VERSION=$3
ZIG_MINISIGN_PUBLIC_KEY='RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U'

cd $TEMP_DIR
wget https://ziglang.org/download/$ZIG_VERSION/zig-linux-$ZIG_ARCH-$ZIG_VERSION.tar.xz
wget https://ziglang.org/download/$ZIG_VERSION/zig-linux-$ZIG_ARCH-$ZIG_VERSION.tar.xz.minisig
minisign -Vm zig-linux-$ZIG_ARCH-$ZIG_VERSION.tar.xz -P "$ZIG_MINISIGN_PUBLIC_KEY"
if [ ! $? ]; then
    echo "Zig download verification failed"
    echo "Check that zig public key is correct"
    echo "script got: $ZIG_MINISIGN_PUBLIC_KEY"
    echo "check it from: https://ziglang.org/download/"
    exit 1
fi

tar -xf zig-linux-$ZIG_ARCH-$ZIG_VERSION.tar.xz -C /usr/local
ln -s /usr/local/zig-linux-$ZIG_ARCH-$ZIG_VERSION/zig /usr/local/bin/zig