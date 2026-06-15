#!/bin/bash
set -e
. setdevkitpath.sh

export FREETYPE_DIR=$PWD/freetype-$BUILD_FREETYPE_VERSION/build_android-$TARGET_SHORT
export CUPS_DIR=$PWD/cups-2.2.4
export CFLAGS+=" -O3"

# Установка зависимостей для iOS, если это iOS-билд
if [[ "$BUILD_IOS" == "1" ]]; then
  ln -s -f /opt/X11/include/X11 $ANDROID_INCLUDE/
  export CFLAGS+=" -arch arm64 -DHEADLESS=1 -I$PWD/ios-missing-include"
  export LDFLAGS+="-arch arm64"
  HOMEBREW_NO_AUTO_UPDATE=1 brew install fontconfig ldid xquartz autoconf
fi

cd openjdk-${TARGET_VERSION}

# Отключаем применение патчей для 25-й версии, чтобы не было конфликтов
git reset --hard
echo "Skipping iOS patches for Java 25 experimental build"
desktop_mac=src/java.desktop/macosx
if [ -d "$desktop_mac" ]; then
  mv ${desktop_mac} ${desktop_mac}_NOTIOS
  mkdir -p ${desktop_mac}/native
  mv ${desktop_mac}_NOTIOS/native/libjsound ${desktop_mac}/native/
fi

# Генерация и запуск конфигурации
# Используем autoconf для создания скрипта configure из шаблонов
bash autogen.sh || autoconf

bash ./configure \
    --openjdk-target=aarch64-apple-darwin \
    --with-target-bits=64 \
    --with-jvm-variants=server \
    --with-jvm-features=-dtrace,-zero,-vm-structs,-epsilongc \
    --with-extra-cflags="$CFLAGS" \
    --with-extra-cxxflags="$CFLAGS" \
    --with-extra-ldflags="$LDFLAGS" \
    --enable-headless-only=yes \
    --with-debug-level=$JDK_DEBUG_LEVEL \
    --with-freetype=bundled \
    --with-toolchain-type=clang \
    --with-sysroot=$(xcrun --sdk iphoneos --show-sdk-path) \
    --with-boot-jdk=$(/usr/libexec/java_home -v $TARGET_VERSION)

# Запуск сборки
jobs=$(sysctl -n hw.ncpu)
make JOBS=$jobs images
