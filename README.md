# 🐧 Formation Linux — Niveau 2

> Travaux pratiques d'administration système Linux avancée, sur **Debian 13 « Trixie »** (noyau 6.12 LTS).

Cette formation part du principe que les bases (navigation shell, `apt`, permissions, éditeur de texte, SSH)
sont acquises. On attaque ici les droits, le stockage, le noyau, la construction de systèmes, le diagnostic,
la supervision et l'environnement de travail.

---

## 🎯 Ce que vous allez apprendre

- 👥 Déléguer des droits proprement : utilisateurs, groupes, `sudo` en liste blanche, ACL
- 💾 Construire un stockage résilient : RAID logiciel, LVM, systèmes de fichiers modernes
- 🧩 Écrire, compiler et charger un module du noyau, et exposer un périphérique dans `/dev`
- 📦 Créer un système Linux minimaliste avec `debootstrap`, l'isoler en `chroot`, piloter un parc avec SaltStack
- 🔎 Diagnostiquer méthodiquement une panne (logs, ressources, services, réseau, firewall, droits)
- 📊 Superviser un serveur et mettre en place une stratégie de sauvegarde incrémentale et chiffrée
- 🖥️ Monter un environnement de travail graphique et un shell productif
- 🎩 Administrer une distribution Red Hat : `dnf`, firewalld, SELinux

---

## 🧰 Le lab

Les TP se jouent dans des VM Debian 13 démarrées avec **Vagrant + VirtualBox**, depuis le dépôt
[**VagrantLab**](https://github.com/OPS-NC/VagrantLab). Mise en route, plan d'adressage, snapshots
et ajout des disques du TP2 : [**LAB.md**](LAB.md).

### Connaissances attendues

- Se déplacer et manipuler des fichiers en ligne de commande
- Comprendre les permissions Unix (`chmod`, `chown`, utilisateur / groupe / autres)
- Installer un paquet avec `apt`, lire un fichier de configuration
- Utiliser `vim` ou `nano` (un `vimtutor` en français est fourni dans le TP7)

---

## 🗺️ Parcours des TP

| # | TP | Thème | VM |
|---|---|---|---|
| 1 | [**TP1-Users**](TP1-Users/) 👥 | Utilisateurs, groupes, `sudo` restreint, `chmod`/`chown`, setgid, ACL | `box01` |
| 2 | [**TP2-FS**](TP2-FS/) 💾 | RAID 1 logiciel (`mdadm`), LVM, BTRFS, simulation de panne disque | `box02` + 2 disques |
| 3 | [**TP3-Kernel**](TP3-Kernel/) 🧩 | Modules noyau en C, périphérique caractère dans `/dev`, paramètres de module | `box01` |
| 4 | [**TP4-Installation**](TP4-Installation/) 📦 | `debootstrap`, `chroot`, exécuter un service dans un système invité | `box01` |
| — | [**Saltstack**](TP4-Installation/Saltstack.md) 🧂 | Master / minions, clés, grains, states YAML, ciblage par grain | `box01` → `box02`, `box03` |
| 5 | [**TP5-Analyse**](TP5-Analyse/) 🔎 | Diagnostic de panne : le système est cassé, à vous de le réparer | `box01` |
| 6 | [**TP6-Supervision**](TP6-Supervision/) 📊 | Netdata, Monit, sauvegardes `rsnapshot` et `restic` | `box02` (celle du TP2) |
| 7 | [**TP7-TerminalX11**](TP7-TerminalX11/) 🖥️ | X11, i3wm, tmux, zsh, fzf — l'environnement de l'admin sys | `box01` |
| 8 | [**TP8-RedHat**](TP8-RedHat/) 🎩 | Rocky Linux 10 : `dnf` / `rpm`, firewalld, SELinux | `rocky` |
| 9 | [**TP9-Proxmox**](TP9-Proxmox/) 🧱 | Image cloud Debian 13, template Proxmox, clones cloud-init | Hyperviseur Proxmox |

On repart d'une `box01` neuve à chaque TP (`vagrant destroy -f box01 && vagrant up box01`).
**`box02` est conservée du TP2 au TP6** : le TP6 sauvegarde sur le volume RAID du TP2.

> ⚠️ **Le TP9 ne se joue pas dans le lab Vagrant** : il s'exécute en `root` **sur un
> hyperviseur Proxmox** (PVE 8 ou 9), avec le bridge `vmbr0` et le stockage `local-lvm`.

---

## 📁 Structure du dépôt

```
FormationLinux-lvl2/
├── README.md                  # Ce fichier
├── LAB.md                     # 🧰 Lab Vagrant : démarrage, snapshots, disques RAID
├── RESSOURCES.md              # 🔗 Liens, antisèches et documentation externe
│
├── TP1-Users/                 # 👥 Utilisateurs, groupes, sudo, permissions
│   └── setup-users.sh         #    Mise en place / vérification / nettoyage
├── TP2-FS/                    # 💾 RAID + LVM + BTRFS
├── TP3-Kernel/                # 🧩 Modules noyau
│   ├── Module1/               #    « Hello World » noyau
│   └── Module2/               #    Périphérique caractère /dev
├── TP4-Installation/          # 📦 debootstrap + chroot
│   └── Saltstack.md           # 🧂 Gestion de configuration master / minions
├── TP5-Analyse/               # 🔎 Diagnostic
│   └── install.sh             #    Script qui « casse » le système
├── TP6-Supervision/           # 📊 Monitoring + backup
├── TP7-TerminalX11/           # 🖥️  Bureau et shell
│   ├── crazy-shell.sh         #    Installation zsh + oh-my-zsh + fzf
│   └── vimtutor.fr            #    Tutoriel vim en français
├── TP8-RedHat/                # 🎩 Rocky Linux 10
│   └── Vagrantfile            #    VM rocky (192.168.56.40)
└── TP9-Proxmox/               # 🧱 Template Proxmox + cloud-init
    ├── build-template.sh      #    Création automatisée du template
    └── user-data-exemple.yaml #    user-data cloud-init commenté
```

---

## 📖 Conventions de lecture

| Symbole | Signification |
|---|---|
| 🎯 | Objectif de l'exercice |
| 📋 | Prérequis / étape préparatoire |
| ✅ | Point de vérification — ne passez pas à la suite si ça échoue |
| 💡 | Explication ou astuce |
| ⚠️ | Opération destructive ou piège classique |
| 🏋️ | À vous de jouer — exercice sans corrigé |

Les blocs de commandes sont **à exécuter en root dans la VM** (`sudo -i`) sauf mention contraire.
Les valeurs à adapter sont en `MAJUSCULES`.

---

## 🔗 Ressources

Antisèches et documentation externe : [**RESSOURCES.md**](RESSOURCES.md).
