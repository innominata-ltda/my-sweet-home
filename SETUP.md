# Environment Setup

This guide walks through setting up a development environment for **My Sweet Home** on Linux or WSL2 (Ubuntu).

## 1. Prerequisites

Install base system packages:

```bash
sudo apt update
sudo apt install -y build-essential curl git unzip xz-utils zip libglu1-mesa
```

`build-essential` provides `make`, used by the project's `Makefile`.

## 2. Java (JDK 17)

Gradle and Android builds require Java 17:

```bash
sudo apt install -y openjdk-17-jdk
java -version        # Verify OpenJDK 17.x
```

## 3. Flutter SDK

Flutter is pinned via `.fvmrc`:

```bash
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
flutter --version
```

Alternatively, use [FVM](https://fvm.app):

```bash
dart pub global activate fvm
fvm install
```

## 4. Android SDK

Command-line tools setup without Android Studio:

```bash
mkdir -p ~/android/cmdline-tools && cd ~/android/cmdline-tools
curl -o tools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip tools.zip && mv cmdline-tools latest && rm tools.zip
echo 'export ANDROID_HOME="$HOME/android"' >> ~/.bashrc
echo 'export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"' >> ~/.bashrc
source ~/.bashrc
sdkmanager --install "platform-tools" "platforms;android-35" "build-tools;35.0.0"
flutter doctor --android-licenses     # Accept licenses
flutter doctor -v
```

## 5. Physical Devices on WSL2

WSL2 does not expose USB directly. The recommended method is **Wireless Debugging**:

```bash
# On device: Developer options > Wireless debugging > Pair device with pairing code
adb pair <ip>:<pairing-port>
adb connect <ip>:<port>
flutter devices
```

> If ADB conflicts occur between WSL2 and Windows, stop `adb.exe` on the Windows host before reconnecting.

## 6. Fastlane & Release Build Automation

For local Fastlane execution and release artifact builds (see [docs/infra/fastlane-deploy.md](docs/infra/fastlane-deploy.md)):

```bash
sudo apt install -y ruby-full
gem install bundler
bundle install
cd android && bundle exec fastlane doctor
```

## 7. Verification

Verify that your development environment is fully operational:

```bash
make check           # Run format, analyze, codegen check, unit/widget tests, coverage
flutter doctor -v    # Check Flutter toolchain status
flutter devices      # Confirm connected devices
```

## What is NOT Required

- **Android Studio**: Optional; command-line tools are sufficient.
- **Xcode / macOS**: Not required for Android builds.
- **Cloud accounts / API keys / Backend servers**: The MVP is completely offline-first.
