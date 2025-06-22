#!/usr/bin/env bash

if ! command -v yay > /dev/null 2>&1; then
	sudo bash -c 'echo [archlinuxcn] >> /etc/pacman.conf'
	sudo bash -c 'echo Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch >> /etc/pacman.conf'
	sudo pacman -Sy
	sudo pacman -S archlinuxcn-keyring
	sudo pacman -S yay
fi

packages=(
	"rsync"
	"vim"
	"git"
	"go"
	"rust"
	"cargo"
	"python"
	"lua"
	"nodejs"
	"npm"
	"gcc"
	"gdb"
	"tmux"
	"make"
	"net-tools"
	"sshpass"
	"protobuf"
	"tcpdump"
	"which"
	"fzf"
	"ripgrep"
	"unzip"
	"kubectl"
	"inetutils"
	"podman"
	"ripgrep"
)

package_list=$(echo "${packages[@]}" | tr ' ' ' ')

sudo pacman -Syu --noconfirm $package_list
