<h1 align="center">
  <img src="https://raw.githubusercontent.com/JappeOS/JappeOS/dev/Icons/jappeos-logo-banner-white-512.png" width="120"><br>
  jappeos_greeter
</h1>

<p align="center">
  <strong>The login screen for JappeOS.</strong>
</p>

<p align="center">
  <a href="./issues"><img src="https://img.shields.io/github/issues/JappeOS/jappeos_greeter?style=plastic&color=edda09"></a>
  <a href="./pulls"><img src="https://img.shields.io/github/issues-pr/JappeOS/jappeos_greeter?style=plastic&color=40a842"></a>
  <a href="./blob/main/LICENSE"><img src="https://img.shields.io/github/license/JappeOS/jappeos_greeter?style=plastic&color=9d09ed"></a>
  <img src="https://img.shields.io/badge/arch-x86__64-blue?style=plastic">
  <img src="https://img.shields.io/badge/status-experimental-orange?style=plastic">
  <a href="https://discord.gg/dRtU4HR"><img src="https://img.shields.io/discord/716673375946407972?style=plastic&color=3250a8"></a>
</p>

---

## Overview

The login screen for JappeOS, written in Flutter.

## Features

* Initial user creation
* User selection
* User login
* Power management

## Role in the OS

Usually the first UI the user sees after booting their system.

## Building

### Prerequisites

- Flutter SDK 3.38.0 or later (with desktop support enabled)
- Dart SDK (included with Flutter)

Verify Flutter desktop setup:

```bash
$ flutter doctor
```

### Setup

Clone the repository and fetch dependencies:
```bash
$ git clone https://github.com/JappeOS/jappeos_greeter.git
$ cd jappeos_greeter
$ flutter pub get
```

### Build

#### Linux

```bash
$ flutter build linux
```

This produces a binary in:
```
build/linux/x64/release/bundle/
```

Run locally:
```bash
$ flutter run -d linux
```

#### Other platforms

While running on Linux is recommended, you can still build and run on other platforms.
Just use the above instructions, and replace `linux` with the platform name (e.g. `windows` or `macos`).

#### Build Modes

* `debug` - default for development
* `profile` - performance testing
* `release` - production build

Example:
```bash
$ flutter build linux --release
```

#### Troubleshooting

If the build fails after dependency changes:
```bash
$ flutter clean
$ flutter pub get
```
Check `flutter doctor` for missing desktop dependencies.

## Contributing

Contributions of all kinds are welcome and appreciated. You can help the project by:

- ⭐ Starring the repository to show your support
- 💖 Sponsoring the project (if available)
- 🐞 Reporting bugs via [GitHub Issues](./issues)
- 💡 Requesting or discussing new features

For code contributions, please see [`CONTRIBUTING.md`](./CONTRIBUTING.md) for guidelines.

## License

This repository is part of the JappeOS project and is licensed under the terms described in the [`LICENSE`](./LICENSE) file.