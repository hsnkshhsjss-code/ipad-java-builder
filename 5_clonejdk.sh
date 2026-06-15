#!/bin/bash
set -e

if [[ $TARGET_VERSION -eq 21 ]]; then
    # Качаем Java 25, но маскируем папку под 21-ю для остальных скриптов
    git clone --depth 1 https://github.com/openjdk/jdk25u openjdk-21
else
    git clone --depth 1 https://github.com/openjdk/jdk17u openjdk-17
fi
