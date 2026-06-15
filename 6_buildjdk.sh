#!/bin/bash
set -e
. setdevkitpath.sh

export FREETYPE_DIR=$PWD/freetype-$BUILD_FREETYPE_VERSION/build_android-$TARGET_SHORT
export CUPS_DIR=$PWD/cups-2.2.4
export CFLAGS+=" -O3"

if [[ "$BUILD_IOS" != "1" ]]; then
  chmod +x android-wrapped-clang
  chmod +x android-wrapped-clang++
  platform_args="--with-toolchain-type=gcc"
else
  ln -s -f /opt/X11/include/X11 $ANDROID_INCLUDE/
  platform_args="--with-toolchain-type=clang --with-sysroot=$(xcrun --sdk iphoneos --show-sdk-path) \
    --with-boot-jdk=$(/usr/libexec/java_home -v $TARGET_VERSION) \
    --with-freetype=bundled"
  export CFLAGS+=" -arch arm64 -DHEADLESS=1 -I$PWD/ios-missing-include"
  export LDFLAGS+="-arch arm64"
  HOMEBREW_NO_AUTO_UPDATE=1 brew install fontconfig ldid xquartz autoconf
fi

cd openjdk-${TARGET_VERSION}

# Блок с патчами (отключен для iOS, чтобы не ломался билд Java 25)
git reset --hard
if [[ "$BUILD_IOS" != "1" ]]; then
  find ../patches/jre_${TARGET_VERSION}/android -name "*.diff" -print0 | xargs -0 -I {} sh -c 'echo "Applying {}" && git apply --reject --whitespace=fix {}'
else
  echo "Skipping iOS patches for Java 25"
  desktop_mac=src/java.desktop/macosx
  if [ -d "$desktop_mac" ]; then
    mv ${desktop_mac} ${desktop_mac}_NOTIOS
    mkdir -p ${desktop_mac}/native
    mv ${desktop_mac}_NOTIOS/native/libjsound ${desktop_mac}/native/
  fi
fi

# Конфигурация сборки
bash ./configure \
    --openjdk-target=$TARGET \
    --with-extra-cflags="$CFLAGS" \
    --with-extra-cxxflags="$CFLAGS" \
    --with-extra-ldflags="$LDFLAGS" \
    --enable-headless-only=yes \
    --with-debug-level=$JDK_DEBUG_LEVEL \
    $platform_args

# Запуск сборки
jobs=$(sysctl -n hw.ncpu)
make JOBS=$jobs images
