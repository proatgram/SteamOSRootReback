#!/bin/bash

BASE_DIR="/etc/SteamOSRootReback"
HOOKS_DIR="$BASE_DIR/hooks.d"

INSTALLED_HOOKS="/usr/share/SteamOSRootReback/installed_hooks.txt"

function CheckInstalled {
    if [ -f "$INSTALLED_HOOKS" ]; then
        echo "true"
    else
        echo "false"
    fi
}

function CheckIfNewHooks {
    local hooks=()

    shopt -s nullglob
    for file in "$HOOKS_DIR"/*.hook; do
        if ! grep -qFx "$file" "$INSTALLED_HOOKS"; then
            hooks+=("$file")
        fi
    done
    shopt -u nullglob

    if (( ${#hooks[@]} > 0 )); then
        echo "${hooks[@]}"
    fi
}

function Install {
    steamos-readonly disable

    echo "SteamOSRootReback: Installing hooks..."

    if [[ $# -eq 0 ]]; then
        shopt -s nullglob
        for file in $HOOKS_DIR/*.hook; do
            if grep -qFx "$HOOK_PATH" "$INSTALLED_HOOKS"; then
                continue
            fi

            (
                source "$HOOK_PATH" || {
                    echo "SteamOSRootReback: Failed to source $HOOK_PATH" >&2
                    exit 1
                }

                echo " => ${HOOK_NAME:-Unknown Hook}"

                if ! HookInstall; then
                    echo "SteamOSRootReback: HookInstall failed for $HOOK_PATH" >&2
                    exit 1
                fi
            )

            mkdir -p /usr/share/SteamOSRootReback
            echo -e "$file\n" >> $INSTALLED_HOOKS
        done
        shopt -u nullglob
    else
        for file in "$@"; do
            HOOK_PATH=$(
                if [[ "$file" == */* ]]; then
                    realpath -- "$file"
                else
                    realpath -- "$HOOKS_DIR/$file"
                fi
            )

            if [[ ! -f "$HOOK_PATH" ]]; then
                echo "SteamOSRootReback: Hook not found: $file" >&2
                continue
            fi

            if grep -qFx "$HOOK_PATH" "$INSTALLED_HOOKS"; then
                continue
            fi

            (
                source "$HOOK_PATH" || {
                    echo "SteamOSRootReback: Failed to source $HOOK_PATH" >&2
                }

                echo " => ${HOOK_NAME:-Unknown Hook}"

                if ! HookInstall; then
                    echo "SteamOSRootReback: HookInstall failed for $HOOK_PATH" >&2
                fi
            )

            mkdir -p /usr/share/SteamOSRootReback
            echo -e "$HOOK_PATH\n" >> "$INSTALLED_HOOKS"
        done
    fi

    echo "SteamOSRootReback: Hooks installed."

    steamos-readonly enable
}

function Uninstall {
    steamos-readonly disable

    echo "SteamOSRootReback: Uninstalling hooks..."

    function RemoveFromInstalled {
        local hook_path=$1
        if [[ -f "$INSTALLED_HOOKS" ]]; then
            grep -vFx "$hook_path" "$INSTALLED_HOOKS" > "$INSTALLED_HOOKS.tmp" && \
            mv "$INSTALLED_HOOKS.tmp" "$INSTALLED_HOOKS"
        fi
    }

    if [[ $# -eq 0 ]]; then
        shopt -s nullglob
        for file in $HOOKS_DIR/*.hook; do
            (
                source "$HOOK_PATH" || {
                    echo "SteamOSRootReback: Failed to source $HOOK_PATH" >&2
                }

                echo " => ${HOOK_NAME:-Unknown Hook}"

                if ! HookUninstall; then
                    echo "SteamOSRootReback: HookUninstall failed for $HOOK_PATH" >&2
                fi
            )
        done
        shopt -u nullglob

        RemoveFromInstalled "$file"
        mv "$file" "$file.uninstalled"
    else
        for file in "$@"; do
            HOOK_PATH=$(
                if [[ "$file" == */* ]]; then
                    realpath -- "$file"
                else
                    realpath -- "$HOOKS_DIR/$file"
                fi
            )

            if [[ ! -f "$HOOK_PATH" ]]; then
                echo "SteamOSRootReback: Hook not found: $file" >&2
                continue
            fi

            (
                source "$HOOK_PATH" || {
                    echo "SteamOSRootReback: Failed to source $HOOK_PATH" >&2
                }

                echo " => ${HOOK_NAME:-Unknown Hook}"

                if ! HookUninstall; then
                    echo "SteamOSRootReback: HookUninstall failed for $HOOK_PATH" >&2
                fi
            )

            RemoveFromInstalled "$HOOK_PATH"
            mv "$file" "$file.uninstalled"
        done

    fi
    
    echo "SteamOSRootReback: Uninstalled hooks."

    steamos-readonly enable
}

if [ "x$1" == "x" ]; then
    if [ "$(CheckInstalled)" == "true" ]; then
        echo "SteamOSRootReback: Changes still installed to rootfs."

        echo "SteamOSRootReback: Checking for new hooks..."

        NEW_HOOKS=$(CheckIfNewHooks)

        if [[ -n "$NEW_HOOKS" ]]; then
            echo "SteamOSRootReback: New hooks found: $NEW_HOOKS"   
            Install $NEW_HOOKS
        else
            echo "SteamOSRootReback: No new hooks found."
        fi

    else
        echo "SteamOSRootReback: Changes to rootfs not present."
        echo "SteamOSRootReback: Reinstalling..."

        steamos-readonly disable
        mkdir -p "/usr/share/SteamOSRootReback/"
        touch $INSTALLED_HOOKS

        ln -s "$BASE_DIR/SteamOSRootReback.sh" "/usr/bin/SteamOSRootReback"

        Install

        echo "SteamOSRootReback: Installed."
    fi
elif [ "$1" == "uninstall" ]; then
    args=("${@:2}")

    echo "SteamOSRootReback: Uninstalling hook(s) ${args[@]}..."

    if [ ${#args[@]} -eq 0 ]; then
        Uninstall
    else
        Uninstall "${args[@]}"
    fi

    echo "SteamOSRootReback: Hook(s) uninstalled."
elif [ "$1" == "install" ]; then
    args=("${@:2}")
    
    echo "SteamOSRootReback: Installing hook(s) ${args[@]}..."

    if [ ${#args[@]} -eq 0 ]; then
        Install
    else
        Install "${args[@]}"
    fi

    echo "SteamOSRootReback: Hook(s) installed."
else
    cat <<EOF
        Usage: $0 [command]

        commands:
        - install (hook(s)) |            Installs SteamOSRootReback hooks
        - uninstall (hook(s)) |          Uninstalls SteamOSRootReback hooks
EOF
fi

exit 0
