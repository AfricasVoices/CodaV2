# CodaV2

[![CircleCI](https://circleci.com/gh/AfricasVoices/CodaV2/tree/master.svg?style=svg)](https://circleci.com/gh/AfricasVoices/CodaV2/tree/master)

CodaV2 the second version of [Coda](https://github.com/AfricasVoices/coda), an interactive tool that helps you label short text datasets.

## Developer Setup

CodaV2's source code is written in [Dart 2.0](https://www.dartlang.org/dart-2). In order to install Dart, you should follow the instructions from the [dartlang website](https://webdev.dartlang.org/guides/get-started#2-install-dart).

After you have installed Dart, you can run the project locally using the `webdev` command line tool, which needs to be activated first:

```
$ pub global activate webdev
```

Before the first run and if any new packages are added, the Dart package manager needs to be run as well:

```
CodaV2/webapp$ pub get
```

You can now run the `CodaV2/webapp/` project with `run_dev_local.sh`. This copies the developer firebase constants into 
the `web/assets` directory, then starts a development server via `webdev serve`:

```
CodaV2/webapp$ ./run_dev_local.sh
```

When you're ready for deployment, the code needs to be converted from Dart to JavaScript:

```
CodaV2/webapp$ webdev build
```

This will create a `CodaV2/webapp/build/` folder which you can copy onto the HTTP serving server (you can skip the `packages/` folder, as that's not needed).

You can run the tests with the following command:

```
CodaV2/webapp$ pub run test -p chrome
```

There are two scripts that run the build steps and deploy to the right place on Firebase serving. For development deployment:

```
CodaV2/deploy_dev.sh
```

and for production use
```
CodaV2/deploy_prod.sh
```
