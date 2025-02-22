#!/bin/ash

# Install Zig and Zls from ziglang because alpine:3.21 is not in devcontainer (yet)
# also install a specific version of Zig for reproducibility

ZIG_ARCH='x86_64'
ZIG_VERSION='0.13.0'

TEMP_DIR=/tmp/post-create
mkdir -p $TEMP_DIR

ash .devcontainer/install-requirements.sh

# Download Zig and verify the download
ash .devcontainer/install-zig.sh $TEMP_DIR $ZIG_ARCH $ZIG_VERSION

# Download Zls and verify it
ash .devcontainer/install-zls.sh $TEMP_DIR $ZIG_ARCH $ZIG_VERSION

sudo rm -rf $TEMP_DIR

