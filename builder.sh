#!/bin/bash
echo "Welcome to Velvet Kernel Builder!"
LC_ALL=C date +%Y-%m-%d
toolchain="/root/velvet/toolchains/arm-cortex_a15-linux-gnueabihf-linaro_4.9.1-2014.04/bin/arm-gnueabi-"
build=/root/out
kernel="velvet"
version=".R1"
rom="cm"
vendor="yu"
device="tomato"
date=`date +%Y%m%d`
ramdisk=ramdisk
config="tomato_defconfig"
kerneltype="zImage"
jobcount="-j$(grep -c ^processor /proc/cpuinfo)"
ps=2048
base=0x80000000
ramdisk_offset=0x01000000
cmdline="androidboot.console=ttyHSL0 androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x3F ehci-hcd.park=3 androidboot.bootdevice=7824900.sdhci sched_enable_hmp=1"
export KBUILD_USER=arnavgosain
export KBUILD_HOST=velvet

rm -rf out
mkdir out
mkdir out/tmp
echo "Checking for build..."
if [ -f zip/boot.img ]; then
	read -p "Previous build found, clean working directory..(y/n)? : " cchoice
	case "$cchoice" in
		y|Y )
			export ARCH=arm
			export CROSS_COMPILE=$toolchain
			echo "  CLEAN zip"
			rm -rf zip/boot.img
			rm -rf arch/arm/boot/"$kerneltype"
			rm -rf zip/system
			mkdir -p zip/system/lib/modules
			make clean && make mrproper
			echo "Working directory cleaned...";;
		n|N )
			exit 0;;
		* )
			echo "Invalid...";;
	esac
	read -p "Begin build now..(y/n)? : " dchoice
	case "$dchoice" in
		y|Y)
			make "$config"
			make "$jobcount"
			exit 0;;
		n|N )
			exit 0;;
		* )
			echo "Invalid...";;
	esac
fi
echo "Extracting files..."
if [ -f arch/arm/boot/"$kerneltype" ]; then
	cp arch/arm/boot/"$kerneltype" out
else
	echo "Nothing has been made..."
	read -p "Clean working directory..(y/n)? : " achoice
	case "$achoice" in
		y|Y )
			export ARCH=arm
                        export CROSS_COMPILE=$toolchain
                        echo "  CLEAN zip"
                        rm -rf zip/boot.img
                        rm -rf arch/arm/boot/"$kerneltype"
			rm -rf zip/system
                        mkdir -p zip/system/lib/modules
                        make clean && make mrproper
                        echo "Working directory cleaned...";;
		n|N )
			exit 0;;
		* )
			echo "Invalid...";;
	esac
	read -p "Begin build now..(y/n)? : " bchoice
	case "$bchoice" in
		y|Y)
			make "$config"
			make "$jobcount"
			exit 0;;
		n|N )
			exit 0;;
		* )
			echo "Invalid...";;
	esac
fi

echo "Making ramdisk..."
if [ -d $ramdisk ]; then
	boot_tools/mkbootfs $ramdisk | gzip > out/ramdisk.gz
else
	echo "No ramdisk found..."
	exit 0;
fi

echo "Making dt.img..."
./boot_tools/dtbToolCM --force-v2 -o out/dt.img -s 2048 -p ./scripts/dtc/ ./arch/arm/boot/dts/

echo "Making boot.img..."
if [ -f out/"$kerneltype" ]; then
	boot_tools/mkbootimg --kernel out/"$kerneltype" --ramdisk out/ramdisk.gz --dt out/dt.img --cmdline $cmdline --base $base --pagesize $ps --ramdisk_offset $ramdisk_offset --output zip/boot.img
else
	echo "No $kerneltype found..."
	exit 0;
fi

echo "Zipping..."
if [ -f arch/arm/boot/"$kerneltype" ]; then
	cd zip
	zip -r ../"$kernel"-$version-"$rom"_"$vendor"_"$device"_"$date".zip .
	mv ../"$kernel"-$version-"$rom"_"$vendor"_"$device"_"$date".zip $build
	cd ..
	echo "Done..."
	exit 0;
else
	echo "No $kerneltype found..."
	exit 0;
fi
# Export script by Savoca
# Thank You Savoca!
