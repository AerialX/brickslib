brickslib
=========

This small script builds open source autoconf-based libraries for various
platforms with cross-platform toolchains. Most of these libraries are
dependencies of [libbricks](http://github.com/AerialX/libbricks).
Built libraries go in $PWD/build by default


Supported Target Platforms
==========================

* Native (builds the library natively for the current platform)
* iOS (builds for armv6, armv7, and simulator/i386 on OS X, and armv6 on Linux)
* Android (builds for armv5, armv7a, and x86 with the Android NDK on Linux and OS X)
* PSL1GHT


Libraries
=========

* libpng
* freetype2
* libzip


Configuration
=============

The following environment variables are used to determine the paths of toolchains:

* $IOS\_SDK\_BINPATH - The directory containing the Apple iOS toolchain gcc binaries. Ignored on OS X.
* $IOS\_SDK\_ROOT - The SDKs/ directory containing iPhoneOS SDK directories. Ignored on OS X.
* $ANDROID\_NDK - The path to the root of the Android NDK. Assumed to be /opt/android-ndk if not set.
* $PSL1GHT and $PS3DEV - The path to a fully set up PSL1GHT toolchain.

The $BRICKSLIB\_NONATIVE, $BRICKSLIB\_NOANDROID, $BRICKSLIB\_NOIOS,
$BRICKSLIB\_NOPSL1GHT environment variables may be used to inhibit the
libraries from being built for the given platform. If a toolchain for a
platform isn't detected, it will be ignored.
