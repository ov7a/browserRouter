#!/bin/bash
set -eu
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

if [ $SUDO_USER ]; then
    real_user=$SUDO_USER
else
    real_user=$(whoami)
fi

target="/opt/browserRouter"
appName="browserRouter"
executable="$target/$appName"

mkdir -p "$target"
cp "./zig-out/bin/$appName" "$target"
cp config.cfg "$target"

update-alternatives --install /usr/bin/x-www-browser x-www-browser "$executable" 10
update-alternatives --set x-www-browser "$executable"

menu="browser-router.desktop"

cat >"/usr/share/applications/$menu" << EOF
[Desktop Entry]
Name=Browser Router
GenericName=Web Browser
Comment=Route between browsers
Exec=/opt/browserRouter/browserRouter %U
Terminal=false
X-MultipleArgs=false
Type=Application
Categories=Network;WebBrowser;
StartupNotify=false
MimeType=x-scheme-handler/http;x-scheme-handler/https;

EOF

xdg-mime default "$menu" "x-scheme-handler/http"
xdg-mime default "$menu" "x-scheme-handler/https"
sudo -u "$real_user" xdg-settings set default-web-browser "$menu"

