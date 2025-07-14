#!/bin/bash

ROOT_DIR="/etc/SteamOSRootReback"
PWD=$(pwd)

function Install() {
    mkdir -p $ROOT_DIR

    mkdir -p "/usr/share/SteamOSRootReback"
    touch "/usr/share/SteamOSRootReback/installed_hooks.txt"

    cp "$PWD/SteamOSRootReback.sh" "$ROOT_DIR/"
    ln -s "$ROOT_DIR/SteamOSRootReback.sh" "/usr/bin/SteamOSRootReback"
    cp "$PWD/SteamOSRootReback.service" "/etc/systemd/system/"
    cp "$PWD/SteamOSRootReback-watcher.service" "/etc/systemd/system/"
    cp "$PWD/SteamOSRootReback-watcher.path" "/etc/systemd/system/"

    systemctl daemon-reload
    systemctl enable --now SteamOSRootReback.service
    systemctl enable --now SteamOSRootReback-watcher.service
    systemctl enable --now SteamOSRootReback-watcher.path
}

function Uninstall() {
    systemctl disable --now SteamOSRootReback.service
    systemctl disable --now SteamOSRootReback-watcher.path
    systemctl disable --now SteamOSRootReback-watcher.service

    rm "/etc/systemd/system/SteamOSRootReback.service"
    rm "/etc/systemd/system/SteamOSRootReback-watcher.path"
    rm "/etc/systemd/system/SteamOSRootReback-watcher.service"

    systemctl daemon-reload

    $ROOT_DIR/SteamOSRootReback.sh uninstall

    rm /usr/share/SteamOSRootReback/installed_hooks.txt
    rmdir /usr/share/SteamOSRootReback

    rm "/usr/bin/SteamOSRootReback"
    rm "$ROOT_DIR/SteamOSRootReback.sh"
}

if [ "x$1" == "x" ]; then
    echo "What?"
    echo "Options are \"install\" and \"uninstall\""
elif [ "$1" == "install" ]; then
    Install
elif [ "$1" == "uninstall" ]; then
    Uninstall
fi
