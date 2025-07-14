# SteamOSRootReback
A set of user and system systemd services and scripts to manage and reinstall user changes to the SteamOS read-only rootfs.

## How it works

The systemd service will execute the `SteamOSRootReback.sh` script, which will manage the immutable rootfs by changing it to read-write, running hooks that modify the rootfs, and then changing the rootfs back to read-only. This script will run anytime the system updates, and whenever a new hook is added to the hooks.d directory in /etc/SteamOSRootReback/hooks.d/. Additionally, it can uninstall hooks, but currently this is only used when uninstalling SteamOSRootReback itself.

## Installing

First, make sure you have a sudo password set for your deck (skip this step if you already do):
```bash
passwd YOUR_PASSWORD
```

Once you have a password set, just run the `install.sh` script:

```bash
sudo ./install.sh
```

Then you are all set!

## Adding hooks

### Preface
Hooks, are simply shell/bash scripts that are named like `myhookfile.sh.hook` and have two functions defined in them:
 - `HookInstall`
 - `HookUninstall`

Additionaly, it must have a `HOOK_NAME` variable defined as well.

Hook files are meant to modify the immutable rootfs that a vanilla SteamOS install has, and each SteamOS update they will be re-run to keep those changes persistent.

However, it is ***important*** that, ***only*** things that can be easily re-created, re-generated, or re-downloaded should have a hook for them.

Configuration files you write yourself, files that you modify consistently or that other programs modify consistently, or anything of the likes should be stored in the locations SteamOS provides that are kept persistent between SteamOS updates (e.g. /var, /etc (an overlay from /var), /home).

### The hook file
This is an example hook file, we'll name it `10-install-aur-helper.sh.hook`:

```bash
# Hook to install paru AUR helper

HOOK_NAME="Install AUR Helper"

function HookInstall {
    pacman --noconfirm --needed -S rustup
    rustup default stable
    git clone https://aur.archlinux.org/paru.git
    cd paru
    su nobody - -c 'makepkg --needed --noconfirm --syncdeps'
    pacman --no-confirm -U *.tar.zst
}

function HookUninstall {
    pacman -Rns paru rustup
}
```

#### `HookInstall`
The `HookInstall` function handles the installation of the modifications.
In this case, we are installing an AUR helper called `paru`, so we install the needed dependencies, clone the AUR package, and call `makepkg` on it.

Notice: The hook is executed as root, so if you require a command to be run as non-root or a different user, you can use `su`.

Then, we install the package with `pacman`.

As stated before, all hooks are run as root (through the system systemd service), and in addition the read-only rootfs is disabled so the hook can make modifications.

#### `HookUninstall`
In the case that you need to uninstall a hooks modification, the `HookUninstall` can handle this. In this function, you place what needs to be done to undo what was done in `HookInstall`.
