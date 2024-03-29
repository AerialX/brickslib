#!/bin/bash

outdir="$1"
if [ -z "$outdir" ]; then
	outdir="`dirname $0`"
fi
mkdir -p "$outdir"
outdir="`cd $outdir; pwd`/build"

builddir="$TMPDIR"
if [ -z "$builddir" ]; then
	builddir="/tmp"
fi
builddir="$builddir/brickslib"

apiver="8"

if [ "$OSTYPE" == "linux-gnu" ]; then
	iosversion="3.2"
else
	iosversion="5.0"
fi

if [ -z "$ANDROID_NDK" ]; then
	ANDROID_NDK="/opt/android-ndk"
fi

bindir="$IOS_SDK_BINPATH"
sdkroot="$IOS_SDK_ROOT/iPhoneOS$iosversion.sdk"
targetversion="4.2.1"

if [ "$OSTYPE" == "linux-gnu" ]; then
	target="arm-apple-darwin9"
	binname="linux-x86"
else
	target="arm-apple-darwin10"
	binname="darwin-x86"
	bindir="/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin"
	sdkroot="/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$iosversion.sdk"
	sdkrootsim="/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator$iosversion.sdk"
	bindirsim="/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/bin"
fi

#arguments: libname, outdir
function universalpackage() {

pushd "$2"

OUT_ARCH="ios-universal"
MERGE_ARCH="ios-armv6 ios-armv7 ios-i386"
mkdir -p "$OUT_ARCH/lib"
MERGE_LIBS=""
for arch in $MERGE_ARCH; do
	if [ -e "$arch/lib/$1" ]; then
		MERGE_LIBS="$MERGE_LIBS $arch/lib/$1"
	fi
done

lipo -create -output $OUT_ARCH/lib/$1 $MERGE_LIBS

popd

}

function universalheaders() {

pushd "$1"

OUT_ARCH="ios-universal"
SIM_ARCH="ios-i386"
SIM_PATH="iPhoneSimulator.platform"
ARM_ARCH="ios-armv7"
ARM_PATH="iPhoneOS.platform"
SDK_PATH="Developer/Platforms"
mkdir -p "$OUT_ARCH/$SDK_PATH/$SIM_PATH"
cp -r "$SIM_ARCH/include" "$OUT_ARCH/$SDK_PATH/$SIM_PATH/"
mkdir -p "$OUT_ARCH/$SDK_PATH/$ARM_PATH"
cp -r "$ARM_ARCH/include" "$OUT_ARCH/$SDK_PATH/$ARM_PATH/"

popd

}

#arguments: url, dirname, outdir, extractcommand
function compilepackage() {

CFLAGS_i386="-isysroot $sdkrootsim"
LDFLAGS_i386="-isysroot $sdkrootsim"
CFLAGS_x86_64="-isysroot $sdkrootsim"
LDFLAGS_x86_64="-isysroot $sdkrootsim"
CPPFLAGS_x86="--sysroot=$sdkrootsim"
CFLAGS_common="-I$sdkroot/usr/lib/gcc/$target/$targetversion/include -isysroot $sdkroot -O3"
CFLAGS_armv6="$CFLAGS_common -march=armv6 -mthumb"
CFLAGS_armv7="$CFLAGS_common -march=armv7a -mfpu=neon -mthumb"
LDFLAGS_common="-isysroot $sdkroot -L$sdkroot/usr/lib/system -L$sdkroot/usr/lib/gcc/$target/$targetvesion"
LDFLAGS_armv6="$LDFLAGS_common"
LDFLAGS_armv7="$LDFLAGS_common"
CPPFLAGS_armv="--sysroot=$sdkroot"
CPPFLAGS_armv6="--sysroot=$sdkroot -arch armv6"
CPPFLAGS_armv7="--sysroot=$sdkroot -arch armv7"

mkdir -p "$builddir"
pushd "$builddir"

wget -O - "$1" | $4
pushd $2

if [ -z "$BRICKSLIB_NONATIVE" ]; then
	PKG_CONFIG_DIR="$3/$OSTYPE/lib/pkgconfig" ./configure --without-bzip2 --enable-static=yes --enable-shared=no --prefix "$3/$OSTYPE" CFLAGS="-I$3/$OSTYPE/include" LDFLAGS="-L$3/$OSTYPE/lib" && make $MAKEFLAGS && make install
	make clean
fi

if [ -d "$ANDROID_NDK" -a -z "$BRICKSLIB_NOANDROID" ]; then
	aprefix="arm-linux-androideabi"
	arch="arm"
	abindir="$ANDROID_NDK/toolchains/$aprefix-4.4.3/prebuilt/$binname/bin"
	sysroot="$ANDROID_NDK/platforms/android-$apiver/arch-$arch"
	CFLAGS_aarmv5="--sysroot=$sysroot -O3 -march=armv5te -fPIC -fsigned-char -mthumb -D__STDC_INT64__"
	LDFLAGS_aarmv5="--sysroot=$sysroot -Wl,--fix-cortex-a8"
	CFLAGS_aarmv7="--sysroot=$sysroot -O3 -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3 -mthumb -D__STDC_INT64__"
	LDFLAGS_aarmv7="--sysroot=$sysroot -Wl,--fix-cortex-a8"

	PKG_CONFIG_DIR="$3/android-armv5/lib/pkgconfig" ./configure --without-bzip2 --host=arm-eabi --enable-static=yes --enable-shared=no CFLAGS="$CFLAGS_aarmv5 -I$3/android-armv5/include" CC="$abindir/$aprefix-gcc" RANLIB="$abindir/$aprefix-ranlib" AR="$abindir/$aprefix-ar" CPP="$abindir/$aprefix-cpp" CPPFLAGS="--sysroot=$sysroot" LDFLAGS="$LDFLAGS_aarmv5 -L$3/android-armv5/lib" --prefix "$3/android-armv5" $5 && make $MAKEFLAGS && make install
	make clean

	PKG_CONFIG_DIR="$3/android-armv7/lib/pkgconfig" ./configure --without-bzip2 --host=arm-eabi --enable-static=yes --enable-shared=no CFLAGS="$CFLAGS_aarmv7 -I$3/android-armv7/include" CC="$abindir/$aprefix-gcc" RANLIB="$abindir/$aprefix-ranlib" AR="$abindir/$aprefix-ar" CPP="$abindir/$aprefix-cpp" CPPFLAGS="--sysroot=$sysroot" LDFLAGS="$LDFLAGS_aarmv7 -L$3/android-armv7/lib" --prefix "$3/android-armv7" $5 && make $MAKEFLAGS && make install
	make clean

	apiver="9"
	aprefix="i686-android-linux"
	arch="x86"
	abindir="$ANDROID_NDK/toolchains/$arch-4.4.3/prebuilt/$binname/bin"
	sysroot="$ANDROID_NDK/platforms/android-$apiver/arch-$arch"
	CFLAGS_x86="--sysroot=$sysroot -O3 -fsigned-char -D__STDC_INT64__"
	LDFLAGS_x86="--sysroot=$sysroot"

	PKG_CONFIG_DIR="$3/android-x86/lib/pkgconfig" ./configure --without-bzip2 --host=i686-linux --enable-static=yes --enable-shared=no CFLAGS="$CFLAGS_x86 -I$3/android-x86/include" CC="$abindir/$aprefix-gcc" RANLIB="$abindir/$aprefix-ranlib" AR="$abindir/$aprefix-ar" CPP="$abindir/$aprefix-cpp" CPPFLAGS="--sysroot=$sysroot" LDFLAGS="$LDFLAGS_x86 -L$sysroot/usr/lib -L$3/android-x86/lib" --prefix "$3/android-x86" $5 && make $MAKEFLAGS && make install
	make clean
fi

if [ -d "$bindir" -a -z "$BRICKSLIB_NOIOS" ]; then
	if [ "$OSTYPE" == "linux-gnu" ]; then
		PKG_CONFIG_DIR="$3/ios-armv6/lib/pkgconfig" ./configure --without-bzip2 --host=arm-apple-darwin --enable-static=yes --enable-shared=no CFLAGS="$CFLAGS_armv6 -I$3/ios-armv6/include" CC="$bindir/$target-gcc" CPP="$bindir/$target-cpp" CPPFLAGS="$CPPFLAGS_arm" LDFLAGS="$LDFLAGS_armv6 -L$3/ios-armv6/lib" --prefix "$3/ios-armv6" $5 && make $MAKEFLAGS && make install
		make clean
	else
		PKG_CONFIG_DIR="$3/ios-i386/lib/pkgconfig" ./configure --without-bzip2 --enable-static=yes --enable-shared=no CFLAGS="-arch i386 $CFLAGS_i386 -I$3/ios-i386/include" CC="$bindirsim/gcc" CPP="$bindirsim/cpp" CPPFLAGS="$CPPFLAGS_x86" LDFLAGS="-arch i386 $LDFLAGS_i386 -L$3/ios-i386/lib" --prefix "$3/ios-i386" $5 && make $MAKEFLAGS && make install
		make clean

		#PKG_CONFIG_DIR="$3/ios-x86_64/lib/pkgconfig" ./configure --enable-static=yes --enable-shared=no CFLAGS="-arch x86_64 $CFLAGS_x86_64 -I$3/ios-x86_64/include" CC="$bindirsim/gcc" CPP="$bindirsim/cpp" CPPFLAGS="$CPPFLAGS_x86" LDFLAGS="-arch x86_64 $LDFLAGS_x86_64 -L$3/ios-x86_64/lib" --prefix "$3/ios-x86_64" $5 && make $MAKEFLAGS && make install
		#make clean

		PKG_CONFIG_DIR="$3/ios-armv7/lib/pkgconfig" ./configure --without-bzip2 --host=arm-apple-darwin --enable-static=yes --enable-shared=no CFLAGS="-arch armv7 $CFLAGS_armv7 -I$3/ios-armv7/include" CC="$bindir/llvm-gcc-4.2" CPP="$bindir/llvm-cpp-4.2" CPPFLAGS="$CPPFLAGS_arm6" LDFLAGS="-arch armv7 $LDFLAGS_armv7 -L$3/ios-armv7/lib" --prefix "$3/ios-armv7" $5 && make $MAKEFLAGS && make install
		make clean

		PKG_CONFIG_DIR="$3/ios-armv6/lib/pkgconfig" ./configure --without-bzip2 --host=arm-apple-darwin --enable-static=yes --enable-shared=no CFLAGS="-arch armv6 $CFLAGS_armv6 -I$3/ios-armv6/include" CC="$bindir/llvm-gcc-4.2" CPP="$bindir/llvm-cpp-4.2" CPPFLAGS="$CPPFLAGS_arm7" LDFLAGS="-arch armv6 $LDFLAGS_armv6 -L$3/ios-armv6/lib" --prefix "$3/ios-armv6" $5 && make $MAKEFLAGS && make install
		make clean
	fi
fi

if [ -d "$PSL1GHT" -a -z "$BRICKSLIB_NOPSL1GHT" ]; then
	PKG_CONFIG_PATH="$PS3DEV/portlibs/ppu/lib/pkgconfig:$3/psl1ght/lib/pkgconfig" ./configure --without-bzip2 --host=powerpc64-ps3-elf --enable-static=yes --enable-shared=no CFLAGS="-I$PS3DEV/portlibs/ppu/include -I$3/psl1ght/include" LDFLAGS="-L$PSL1GHT/ppu/lib -L$PS3DEV/portlibs/ppu/lib -L$3/psl1ght/lib -lrt -llv2" CPPFLAGS="-I$PS3DEV/portlibs/ppu/include" CC="$PS3DEV/ppu/bin/ppu-gcc" CPP="$PS3DEV/ppu/bin/ppu-cpp" AR="$PS3DEV/ppu/bin/ppu-ar" RANLIB="$PS3DEV/ppu/bin/ppu-ranlib" --prefix "$3/psl1ght" $5 && make $MAKEFLAGS && make install
	make clean
fi

popd

popd

}

pngver=1.5.6
freetypever=2.4.6
zipver=0.10
eigenver=3.0.2

compilepackage "http://sourceforge.net/projects/libpng/files/libpng15/$pngver/libpng-$pngver.tar.gz/download" libpng-$pngver "$outdir" "tar -xz"
universalpackage libpng.a "$outdir"
compilepackage "http://sourceforge.net/projects/freetype/files/freetype2/$freetypever/freetype-$freetypever.tar.bz2/download" freetype-$freetypever "$outdir" "tar -xj"
universalpackage libfreetype.a "$outdir"
compilepackage "http://www.nih.at/libzip/libzip-$zipver.tar.bz2" libzip-$zipver "$outdir" "tar -xj"
universalpackage libzip.a "$outdir"

universalheaders "$outdir"

rm -rf "$builddir"
