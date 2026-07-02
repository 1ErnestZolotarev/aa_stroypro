FROM ghcr.io/cirruslabs/flutter:3.22.3

# Устанавливаем JDK 11 и необходимые пакеты
RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends \
    openjdk-11-jdk-headless \
    && sudo rm -rf /var/lib/apt/lists/*

ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools

WORKDIR /app
COPY . .

# Принимаем лицензии и загружаем зависимости
RUN yes | flutter doctor --android-licenses
RUN flutter pub get

# Собираем релизный APK
CMD ["flutter", "build", "apk", "--release"]
