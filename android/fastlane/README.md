fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android doctor

```sh
[bundle exec] fastlane android doctor
```

Validates the development environment and required dependencies

### android analyze

```sh
[bundle exec] fastlane android analyze
```

Runs static analysis (flutter analyze and custom_lint)

### android test

```sh
[bundle exec] fastlane android test
```

Runs unit and widget tests with coverage

### android arch

```sh
[bundle exec] fastlane android arch
```

Runs architecture rule tests

### android verify

```sh
[bundle exec] fastlane android verify
```

Runs complete pre-build verification (analyze, test, arch, coverage)

### android build_bundle

```sh
[bundle exec] fastlane android build_bundle
```

Builds signed Release Android App Bundle (AAB) with release keystore

### android build_apk

```sh
[bundle exec] fastlane android build_apk
```

Builds Release split APKs and validates that each APK does not exceed 60 MB (RNF-004)

### android validate_apk_size

```sh
[bundle exec] fastlane android validate_apk_size
```

Validates that each release split APK does not exceed the 60 MB limit (RNF-004)

### android deploy_internal

```sh
[bundle exec] fastlane android deploy_internal
```

Publishes Android App Bundle (AAB) to Internal Testing track on Google Play Console (RNF-012)

### android promote_to_production

```sh
[bundle exec] fastlane android promote_to_production
```

Promotes release from internal test track to Production with phased rollout support (RNF-012)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
