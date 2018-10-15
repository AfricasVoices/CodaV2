# CodaV2

[![CircleCI](https://circleci.com/gh/AfricasVoices/CodaV2/tree/master.svg?style=svg)](https://circleci.com/gh/AfricasVoices/CodaV2/tree/master)

CodaV2 the second version of [Coda](https://github.com/AfricasVoices/coda), an interactive tool that helps you label short text datasets.

## Developer Setup

CodaV2's source code is written in [Dart 2.0](https://www.dartlang.org/dart-2). In order to install Dart, you should follow the instructions from the [dartlang website](https://webdev.dartlang.org/guides/get-started#2-install-dart).

After you have installed Dart, you can run the project locally using the `webdev` command line tool, which needs to be activated first:

```
$ pub global activate webdev
```

You can now run the `CodaV2/webapp/` project with `webdev serve`:

```
CodaV2/webapp$ webdev serve
```

Before the first run and if any new packages are added, the Dart package manager needs to be run as well:

```
CodaV2/webapp$ pub get
```

When you're ready for deployment, the code needs to be converted from Dart to JavaScript:

```
CodaV2/webapp$ webdev build
```
