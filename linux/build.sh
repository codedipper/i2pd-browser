#!/bin/sh

PATH=/usr/local/sbin:/usr/local/bin:/usr/bin
MB_VERSION=13.0.13
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
	rm /tmp/tor.keyring /tmp/$MB_FILE /tmp/$MB_FILE.asc
}

install(){
	clean
	echo "This script compiles i2pd from source, and downloads Mullvad Browser from dist[.]torproject[.]org"
	echo "Take this time to install the required dependencies to do so, and take any precautions if accessing dist[.]torproject[.]org is unsafe in your location."
	echo "Press Enter to continue, or Ctrl+C to exit without making any changes."
	read -r out
	if [ "$SIGVERIFY" != "false" ]; then
		gpg --import 0xEF6E286DDA85EA2A4BA7DE684E2C6E8793298290.gpg
		gpg --output /tmp/tor.keyring --export 0xEF6E286DDA85EA2A4BA7DE684E2C6E8793298290
	else
		echo "Not verifying signatures \(dangerous\)..."
	fi

	if [ "$WGET" = "true" ]; then
		echo "Using Wget..."
		wget -O /tmp/$MB_FILE $MB_URL
		wget -O /tmp/sha256sums-signed-build.txt $MB_ROOT/sha256sums-signed-build.txt

		if [ "$SIGVERIFY" != "false" ]; then
			wget -O /tmp/$MB_FILE.asc $MB_URL.asc
			wget -O /tmp/sha256sums-signed-build.txt.asc $MB_ROOT/sha256sums-signed-build.txt.asc
		fi
	else
		echo "Using cURL..."
		curl -o /tmp/$MB_FILE $MB_URL
		curl -o /tmp/sha256sums-signed-build.txt $MB_ROOT/sha256sums-signed-build.txt

		if [ "$SIGVERIFY" != "false" ]; then
			curl -o /tmp/$MB_FILE.asc $MB_URL.asc
			curl -o /tmp/sha256sums-signed-build.txt.asc $MB_ROOT/sha256sums-signed-build.txt.asc
		fi
	fi

	if [ "$SIGVERIFY" != "false" ]; then
		v1=$(gpgv --status-fd 1 --keyring /tmp/tor.keyring /tmp/$MB_FILE.asc /tmp/$MB_FILE)
		v2=$(gpgv --status-fd 1 --keyring /tmp/tor.keyring /tmp/sha256sums-signed-build.txt.asc /tmp/sha256sums-signed-build.txt)
		if $(echo "$v1" | grep -q "^\[GNUPG:\] KEY_CONSIDERED EF6E286DDA85EA2A4BA7DE684E2C6E8793298290") && 
		   $(echo "$v1" | grep -q "^\[GNUPG:\] VALIDSIG 613188FC5BE2176E3ED54901E53D989A9E2D47BF") &&
		   $(echo "$v2" | grep -q "^\[GNUPG:\] KEY_CONSIDERED EF6E286DDA85EA2A4BA7DE684E2C6E8793298290") && 
		   $(echo "$v2" | grep -q "^\[GNUPG:\] VALIDSIG 613188FC5BE2176E3ED54901E53D989A9E2D47BF"); then
			echo "All PGP signatures verified correctly"
		else
			echo "PGP signatures failed! See files in /tmp to investigate."
			exit 1
		fi
	fi

	cd /tmp
	if $(cat /tmp/sha256sums-signed-build.txt | grep -q "$(sha256sum $MB_FILE)"); then
		echo "SHA256 checksums correct"
	else
		echo "SHA256 checksums failed! See files in /tmp to investigate."
		exit 1
	fi
}

$1
if [ -z "$1" ]; then
	echo "\`sh linux/build.sh clean\` - remove any possible conflicts from a previous install"
	echo "\`sh linux/build.sh install\` - install Revvy's i2pd-browser, runs \`clean\` by default"
	echo "Environment variables:"
	echo "\`WGET\` - use Wget for downloads instead of cURL, boolean"
	echo "\`SIGVERIFY\` - verify PGP signatures for Mullvad Browser \(highly recommended\), boolean"
	echo "\`IGNORE_ARCH\` - ignore check for system architecture, boolean"
	echo "\`IGNORE_ROOT\` - allow running install script as root \(please don't\), boolean"
fi
