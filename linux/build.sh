#!/bin/sh

PATH=/usr/local/sbin:/usr/local/bin:/usr/bin
MB_VERSION=13.0.7
MB_ROOT=https://dist.torproject.org/mullvadbrowser/$MB_VERSION
MB_FILE=mullvad-browser-linux-x86_64-$MB_VERSION.tar.xz
MB_URL=$MB_ROOT/$MB_FILE

if [ $(id -u) -eq 0 ] && [ "$IGNORE_ROOT" != "true" ]; then
	echo "You are running this script as root. This is a security risk, and can cause breakage with the installation."
	echo "Override this by setting IGNORE_ROOT=true"
	exit 1
fi

if [ "$(uname -m)" != "x86_64" ] && [ "$IGNORE_ARCH" != "true" ]; then
	echo "Unfortunately, Mullvad Browser only supports x86_64 systems. Ingore this check by setting IGNORE_ARCH=true"
	exit 1
fi

clean(){
	rm /tmp/tor.keyring /tmp/mullvad-browser-linux-x86_64-$MB_VERSION.tar.{xz,xz.asc}
}

install(){
	clean
	echo "This script compiles i2pd from source, and downloads Mullvad Browser from dist[.]torproject[.]org"
	echo "Take this time to install the required dependencies to do so, and take any precautions if accessing dist[.]torproject[.]org is unsafe in your location."
	echo "Press Enter to continue, or Ctrl+C to exit without making any changes."
	read -rs
	if [ "$SIGVERIFY" = "true" ]; then
		gpg --import 0xEF6E286DDA85EA2A4BA7DE684E2C6E8793298290.asc
		gpg --output /tmp/tor.keyring --export 0xEF6E286DDA85EA2A4BA7DE684E2C6E8793298290
	else
		echo "Not verifying signatures \(dangerous\)..."
	fi
	
	if [ "$WGET" = "true" ]; then
		echo "Using Wget..."
		wget -O /tmp/$MB_FILE $MB_URL
		wget -O /tmp/$MB_FILE.asc $MB_URL.asc
		wget -O /tmp/sha256sums-signed-build.txt $MB_ROOT/sha256sums-signed-build.txt
		wget -O /tmp/sha256sums-signed-build.txt.asc $MB_ROOT/sha256sums-signed-build.txt.asc
	else
		echo "Using cURL..."
		curl -o /tmp/$MB_FILE $MB_URL
		curl -o /tmp/$MB_FILE.asc $MB_URL.asc
		curl -o /tmp/sha256sums-signed-build.txt $MB_ROOT/sha256sums-signed-build.txt
		curl -o /tmp/sha256sums-signed-build.txt.asc $MB_ROOT/sha256sums-signed-build.txt.asc
	fi
}


$1
if [ -z "$1" ]; then
	echo "\`sh linux/build.sh clean\` - remove any possible conflicts from a previous install \(will delete settings\)"
	echo "\`sh linux/build.sh install\` - install Revvy's i2pd-browser, runs \`clean\` by default"
	echo "Environment variables:"
	echo "\`WGET\` - use Wget for downloads instead of cURL, boolean"
	echo "\`SIGVERIFY\` - verify PGP signatures for Mullvad Browser \(highly recommended\), boolean"
	echo "\`IGNORE_ARCH\` - ignore check for system architecture, boolean"
	echo "\`IGNORE_ROOT\` - allow running install script as root \(please don't\), boolean"
fi
