#!/bin/bash

ROOT_DIR="/etc/SteamOSRootReback"

function Install() {
    mkdir "$(ROOT_DIR)"

    cp "$(PWD)/SteamOSRootReback.sh" "$(ROOT_DIR)/"
    cp "$(PWD)/SteamOSRootReback.service" "/etc/systemd/system/"
    cp "$(PWD)/SteamOSRootReback.path" "/etc/systemd/system"

    systemctl daemon-reload
    systemctl enable --now SteamOSRootReback.service
    systemctl enable --now SteamOSRootReback.path
}

function Uninstall() {
    systemctl disable --now SteamOSRootReback.service
    systemctl disable --now SteamOSRootReback.path

    rm "/etc/systemd/system/SteamOSRootReback.service"
    rm "/etc/systemd/system/SteamOSRootReback.path"

    $ROOT_DIR/SteamOSRootReback.sh uninstall

    rm "etc/SteamOSRootReback/SteamOSRootReback.sh"
}

if [ "x$1" == "x" ]; then

elif [ "$1" == "install" ]; then
    Install
elif [ "$1" == "uninstall" ]; then
    Uninstall
fi
