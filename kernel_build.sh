export TZ='Europe/Kyiv'

KERNNAME="Atlas"
KERNVER="B1"
BUILDDATE=$(date +%Y%m%d)
# BUILDTIME=$(date +%H%M)

# Install dependencies
# sudo apt update && sudo apt install -y bc cpio nano bison ca-certificates curl flex gcc git libc6-dev libssl-dev openssl python-is-python3 ssh wget zip zstd sudo make clang gcc-arm-linux-gnueabi software-properties-common build-essential libarchive-tools gcc-aarch64-linux-gnu

# clone clang and gcc
# AOSP clang
# git clone --depth=1 https://gitlab.com/anandhan07/aosp-clang.git clang-llvm
# use weebX clang now lol
wget "$(curl -s https://raw.githubusercontent.com/XSans0/WeebX-Clang/main/main/link.txt)" -O "weebx-clang.tar.gz"
mkdir clang-llvm && tar -xf weebx-clang.tar.gz -C clang-llvm && rm -rf weebx-clang.tar.gz

# Set variable
export KBUILD_BUILD_USER=rootd
export KBUILD_BUILD_HOST=cutiepatootie

# Build
# Prepare
make -j$(nproc --all) O=out ARCH=arm64 CC=$(pwd)/clang-llvm/bin/clang CROSS_COMPILE=aarch64-linux-gnu- CLANG_TRIPLE=aarch64-linux-gnu- LLVM_IAS=1 vendor/fog-perf_defconfig
# Execute
make -j$(nproc --all) O=out ARCH=arm64 CC=$(pwd)/clang-llvm/bin/clang CROSS_COMPILE=aarch64-linux-gnu- CLANG_TRIPLE=aarch64-linux-gnu- LLVM_IAS=1

# Package
git clone --depth=1 https://github.com/r0ddty/AnyKernel3-680 -b master AnyKernel3
cp -R out/arch/arm64/boot/Image.gz AnyKernel3/Image.gz
# Zip it and upload it
cd AnyKernel3
zip -r9 "$KERNNAME"-"$KERNVER"-"$BUILDDATE" . -x ".git*" -x "README.md" -x "*.zip"

# Will use go-pd as direct upload requires API key which i dont have ╮(─▽─)╭
# curl -T Atlas-B1-"$BUILDDATE".zip https://pixeldrain.com/api/file/

# Lemme move kernel zip to the root of source

mv "$KERNNAME"-"$KERNVER"-"$BUILDDATE".zip ../
cd ..

rm go-pd*
wget https://github.com/ManuelReschke/go-pd/releases/download/v1.5.0/go-pd_1.5.0_linux_amd64.tar.gz
mv go-pd_1.5.0_linux_amd64.tar.gz go-pd.tar.gz
tar -xf go-pd.tar.gz
rm go-pd.tar.gz

echo "Please, input your PixelDrain API key below"
# Dayum, go-pd now requires API key as well ヽ(。_°)ノ
echo "If you dont have one - just press Enter key, kernel $KERNNAME-$KERNVER-$BUILDDATE.zip is located on the root of your source"
read KEY
if [ -z "${KEY}" ];
then
	echo "The key is empty, passing"
else
	echo "Your key is $KEY"
	echo "Uploading kernel to PixelDrain"
	./go-pd upload "$KERNNAME"-"$KERNVER"-"$BUILDDATE".zip -k $KEY -v	
fi

echo "Cleaning up..."

read -p "Would you like to remove out/ directory? (Yy/Nn)" yn

case $yn in
	[yY] ) echo "Removing out/ directory";
		rm -rf out;;
	[nN] ) echo "Proceeding without removing out/ directory";; 

	* ) echo "invalid response";;
esac

read -p "Would you like to remove clang directory? (Yy/Nn)" yn

case $yn in
	[yY] ) echo "Removing clang directory";
		rm -rf clang-llvm;;
	[nN] ) echo "Proceeding without removing clang directory";; 

	* ) echo "invalid response";;
esac

rm -rf AnyKernel3/
echo "Build finished"
