export TZ='Europe/Kyiv'

KERNNAME="Andromeda"
KERNVER="Checkmate"
BUILDDATE=$(date +%Y%m%d)
# BUILDTIME=$(date +%H%M)
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

# Install dependencies
# sudo apt update && sudo apt install -y bc cpio nano bison ca-certificates curl flex gcc git libc6-dev libssl-dev openssl python-is-python3 ssh wget zip zstd sudo make clang gcc-arm-linux-gnueabi software-properties-common build-essential libarchive-tools gcc-aarch64-linux-gnu

# clone clang and gcc
# AOSP clang
# git clone --depth=1 https://gitlab.com/anandhan07/aosp-clang.git clang-llvm
# use weebX clang now lol
# no weebx, use azure clang now

if [ ! -e clang-llvm ]
then
    echo -e "${GREEN}clang not found, cloning Azure clang...${NC}"
    git clone --depth 1 -b main https://gitlab.com/Panchajanya1999/azure-clang clang-llvm
else
    echo -e "${GREEN}clang already present, proceeding...${NC}"
fi

# Set variable
export KBUILD_BUILD_USER=rootd
export KBUILD_BUILD_HOST=cutiepatootie

# Build

# Prepare
read -p "Would you like to configure the kernel with nconfig? " yn
tput bel
case $yn in
    [yY] )
	echo "Starting nconfig...";
        make -j$(nproc --all) O=out ARCH=arm64 CC=$(pwd)/clang-llvm/bin/clang CROSS_COMPILE=aarch64-linux-gnu- CLANG_TRIPLE=aarch64-linux-gnu- LLVM_IAS=1 vendor/fog-perf_defconfig nconfig
    ;;

    [nN] )
    	echo "Proceeding without menuconfig...";
	make -j$(nproc --all) O=out ARCH=arm64 CC=$(pwd)/clang-llvm/bin/clang CROSS_COMPILE=aarch64-linux-gnu- CLANG_TRIPLE=aarch64-linux-gnu- LLVM_IAS=1 vendor/fog-perf_defconfig
    ;;

    * )
    	echo "invalid response"
    ;;
esac

# Execute
if make -j$(nproc --all) O=out ARCH=arm64 CC=$(pwd)/clang-llvm/bin/clang CROSS_COMPILE=aarch64-linux-gnu- CLANG_TRIPLE=aarch64-linux-gnu- LLVM_IAS=1
then
    echo -e "${GREEN}Build successful${NC}"
    tput bel
else
    echo -e "${RED}Build failed, exiting...${NC}"
    tput bel
    exit 1
fi

# Package
git clone --depth=1 https://github.com/r0ddty/AnyKernel3-680 -b andro AnyKernel3
cp -R out/arch/arm64/boot/Image.gz AnyKernel3/Image.gz
# Zip it and upload it
cd AnyKernel3
zip -r9 "$KERNNAME"-"$KERNVER"-"$BUILDDATE" . -x ".git*" -x "README.md" -x "*.zip"

# Move kernel zip to the output folder
mkdir ../output
mv "$KERNNAME"-"$KERNVER"-"$BUILDDATE".zip ../output/
mv Image.gz ../output/
cd ..

echo "Cleaning up..."

read -p "Would you like to remove out directory? [y/n]" yn

case $yn in
	[yY] ) echo "Removing out directory";
		rm -rf out;;
	[nN] ) echo "Proceeding without removing out directory";; 

	* ) echo "invalid response";;
esac

read -p "Would you like to remove clang directory? [y/n]" yn

case $yn in
	[yY] ) echo "Removing clang directory";
		rm -rf clang-llvm;;
	[nN] ) echo "Proceeding without removing clang directory";; 

	* ) echo "invalid response";;
esac

rm -rf AnyKernel3/
echo -e "${GREEN}Build finished${NC}"
echo -e "File: ${PURPLE}$(pwd)/output/$KERNNAME-$KERNVER-$BUILDDATE.zip${NC}"

