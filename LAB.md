# 🧰 Le lab Vagrant

Toutes les VM de la formation sont créées avec **Vagrant + VirtualBox** à partir du dépôt
[VagrantLab](https://github.com/OPS-NC/VagrantLab).

---

## 📋 Sur le poste

- VirtualBox 7 et Vagrant installés
- ~8 Go de RAM libres (3 VM de 2 Go au maximum en même temps)

```bash
git clone https://github.com/OPS-NC/VagrantLab.git
cd VagrantLab

# Le dépôt de la formation DANS le dossier VagrantLab :
# il est ainsi visible dans chaque VM sous /vagrant/FormationLinux-lvl2
git clone https://github.com/OPS-NC/FormationLinux-lvl2.git
```

---

## 🖥️ Les VM

| Machine | IP | Usage |
|---|---|---|
| Poste | `192.168.56.1` | Lance `vagrant`, teste les accès réseau (`curl`) |
| `box01` | `192.168.56.10` | La plupart des TP, recréée à chaque TP. Master Salt |
| `box02` | `192.168.56.20` | TP2 (RAID) puis TP6 — **conservée** entre les deux. Minion Salt |
| `box03` | `192.168.56.30` | Minion Salt |
| `rocky` | `192.168.56.40` | TP8, avec son propre `Vagrantfile` dans `TP8-RedHat/` |

Debian 13 (`bento/debian-13`), 2 vCPU, 2 Go de RAM. Compte `vagrant` / `vagrant`, avec
`sudo` sans mot de passe. Le compte `root` est verrouillé.

Toutes les commandes `vagrant` se lancent **depuis le dossier `VagrantLab`** :

```bash
vagrant up box01                          # créer / démarrer
vagrant ssh box01                         # se connecter
sudo -i                                   # puis passer root dans la VM
vagrant reload box01                      # redémarrer
vagrant destroy -f box01 && vagrant up box01   # repartir d'une VM neuve
vagrant status
```

💡 Le provisionnement (`bootstrap.sh`, profil `base`) ajoute quelques outils, les noms
`box01`…`box04` dans `/etc/hosts` et désactive le swap. Comptez quelques minutes par VM.

---

## 📸 Snapshots

Avant un TP destructif :

```bash
vagrant snapshot save box01 tp5           # prendre
vagrant snapshot list box01
vagrant snapshot restore box01 tp5        # revenir en arrière
vagrant snapshot delete box01 tp5
```

---

## 💾 Disques du TP2

Le TP2 a besoin de **deux disques vierges de 2 Go** sur `box02`. On les ajoute à la main dans
VirtualBox, **VM éteinte** :

```bash
vagrant up box02          # première création (provisionnement)
vagrant halt box02
```

Dans VirtualBox : `box02` → **Configuration** → **Stockage** → contrôleur **SATA Controller**
→ icône « Ajouter un disque dur » → **Créer** → VDI, 2 Go → **Choisir**. Recommencez pour le
second disque, puis :

```bash
vagrant up box02
vagrant ssh box02 -c lsblk               # ✅ sdb et sdc, 2G chacun
```

---

## 🆘 Dépannage

| Symptôme | Piste |
|---|---|
| `vagrant up` refuse le réseau host-only | Autoriser `192.168.56.0/24` dans `/etc/vbox/networks.conf` |
| `curl http://192.168.56.10` timeout depuis le poste, OK depuis une VM | Un VPN (Tailscale…) capture `192.168.56.0/24` : `ip route get 192.168.56.10` doit sortir par `vboxnet0` |
| VM figée au boot (`rcu … stall`, `blocked for more than 120 seconds`), `vagrant up` en timeout | `VBoxManage controlvm BOX poweroff`, `VBoxManage modifyvm BOX --paravirt-provider none`, puis `vagrant up BOX` |
| Plus de place sur le poste | `vagrant destroy -f` sur les VM inutiles |
