#! /bin/bash

sudo apt-get update && sudo apt-get -y install tmux git vim ccze zsh curl

## Oh my ZSH
wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh
chmod +x install.sh
./install.sh --unattended
rm install.sh

## FZF
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all

## zsh-autosuggestion
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
echo "source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ~/.zshrc

## zsh shell par défaut (via sudo : pas de mot de passe demandé)
sudo chsh -s "$(command -v zsh)" "$USER"

echo "----------------------------------------------------------------------"
echo "Choisissez votre thème OhMyZsh et changez le dans votre fichier .zshrc"
echo "https://github.com/ohmyzsh/ohmyzsh/wiki/Themes"
echo "Session graphique ouverte : déconnectez-vous et reconnectez-vous pour avoir zsh partout"
echo "----------------------------------------------------------------------"

exec zsh
