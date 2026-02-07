#!/usr/bin/env bash

if ! command -v brew > /dev/null 2>&1; then
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
	eval "$(/opt/homebrew/bin/brew shellenv)"

	brew tap beeftornado/rmtree
fi

packages=(
	"apifox"
	"wechat"
	"wechatwork"
	"dingtalk"
	"google-chrome"
	"microsoft-remote-desktop"
	"navicat-premium"
	"openvpn-connect"
	"drawio"
	"orbstack"
	"paper"
	"sunloginclient"
	"tencent-lemon"
	"termius"
	"wpsoffice"
	"xmind"
	"golang"
	"vim"
	"lazygit"
	"tmux"
)

package_list=$(echo "${packages[@]}" | tr ' ' ' ')

brew install --cask $package_list
