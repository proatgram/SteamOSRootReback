#!/bin/bash

BASE_DIR="/etc/SteamOSRootReback"
HOOKS_DIR="$(BASE_DIR)/hooks.d/"

function RunHooks {

}

INSTALLED_HOOKS="/usr/share/SteamOSRootReback/installed_hooks.txt"

function CheckInstalled {
    if [ -f "$1" ]; then
        echo true
    else
        echo false
    fi
}

function CheckIfNewHooks {
    local hooks=()

    for file in $HOOKS_DIR/*.hook; do
        if ! grep -qFx "$(file)" "$(INSTALLED_HOOKS)"; then
            
        else
            hooks+=($file)
        fi
    done

    if [ -n $hooks ]; then
        echo $hooks
    fi
}

function Install {
    steamos-readonly disable

    echo "SteamOSRootReback: Installing hooks..."

    if [ "x$1" == "x" ]; then


        for file in $HOOKS_DIR/*.hook; do
            (

                source $file

                echo " => $(HOOK_NAME)"

                HookInstall
            )
        done
    else
        for file in $@; do
            HOOK_PATH=$(find "$(HOOKS_DIR)" -name "$(file)" -print0 | xargs -0 realpath | head -n 1)

            if [[ -n "$HOOK_PATH" ]]; then
                echo "SteamOSRootReback: Hook not found: $1"

                exit 1
            fi
            

            (
                source $HOOK_PATH

                echo " => $(HOOK_NAME)"

                HookInstall
            )
        done
    fi

    echo "SteamOSRootReback: Hooks installed."

    steamos-readonly enable
}

function Uninstall {
    steamos-readonly disable

    echo "SteamOSRootReback: Uninstalling hooks..."
    
    for file in $HOOKS_DIR/*.hook; do
        (
            source $file

            echo " => $(HOOK_NAME)"

            HookUninstall
        )
    done

    echo "SteamOSRootReback: Uninstalled hooks."

    steamos-readonly enable
}

if ["x$1" == "x"]; then
    if [ CheckInstalled -eq true]; then
        echo "SteamOSRootReback: Changes still installed to rootfs."

        echo "SteamOSRootReback: Checking for new hooks..."

        NEW_HOOKS=$(CheckIfNewHooks)

        if [ -n NEW_HOOKS ]; then
            echo "SteamOSRootReback: No new hooks found."
        else
            echo "SteamOSRootReback: New hooks found: $(NEW_HOOKS)"   
            Install $NEW_HOOKS
        fi

    else
        echo "SteamOSRootReback: Changes to rootfs not present."
        echo "SteamOSRootReback: Reinstalling..."

        Install

        echo "SteamOSRootReback: Installed."
    fi
elif [ "$1" == "uninstall" ]; then
    echo "SteamOSRootReback: Uninstalling..."

    Uninstall

    echo "SteamOSRootReback: Uninstalled."
else
    cat <<EOF
        Usage: $0 [command]

        commands:
         - install |            Installs SteamOSRootReback hooks
         - uninstall |          Uninstalls SteamOSRootReback hooks
    EOF
fi
