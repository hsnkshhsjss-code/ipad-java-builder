# Конфигурация сборки с маскировкой под macOS
bash ./configure \
    --openjdk-target=aarch64-apple-darwin \
    --with-target-bits=64 \
    --with-extra-cflags="$CFLAGS" \
    --with-extra-cxxflags="$CFLAGS" \
    --with-extra-ldflags="$LDFLAGS" \
    --enable-headless-only=yes \
    --with-debug-level=$JDK_DEBUG_LEVEL \
    --with-jvm-variants=server \
    --with-jvm-features=-dtrace,-zero,-vm-structs,-epsilongc \
    $platform_args
