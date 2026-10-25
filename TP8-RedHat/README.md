# 🎩 TP8 — Base Red Hat : Rocky Linux 10

## 🎯 Objectif

Prendre en main une distribution de la famille **Red Hat** (RHEL, Rocky, Alma, CentOS Stream,
Fedora) et ce qui la distingue de Debian :

| Volet | Ce que vous apprenez |
|---|---|
| 📦 **Paquets** | `dnf` / `rpm`, dépôts BaseOS / AppStream / EPEL, historique et annulation |
| 🧱 **firewalld** | Zones, services, ports, règles *runtime* vs *permanent* |
| 🛡️ **SELinux** | Contextes, ce qu'il bloque, `restorecon`, `semanage`, booléens |

| | Debian 13 | Rocky Linux 10 |
|---|---|---|
| Paquets | `.deb`, `apt` / `dpkg` | `.rpm`, `dnf` / `rpm` |
| Un service installé est… | démarré et activé | **ni démarré, ni activé** |
| Pare-feu par défaut | aucun | **firewalld actif** |
| Contrôle d'accès obligatoire | AppArmor | **SELinux en `enforcing`** |
| Groupe des administrateurs | `sudo` | `wheel` |
| Réglages des services | `/etc/default/` | `/etc/sysconfig/` |
| Cycle de vie | ~5 ans | ~10 ans |

---

## 📋 Prérequis

La VM Rocky n'est pas dans VagrantLab : elle a son propre `Vagrantfile`, dans ce dossier.
Sur le poste :

```bash
cd VagrantLab/FormationLinux-lvl2/TP8-RedHat
vagrant up
vagrant ssh
sudo -i
```

| Machine | IP | OS |
|---|---|---|
| `rocky` | `192.168.56.40` | Rocky Linux 10 (`bento/rockylinux-10`) |

```bash
cat /etc/os-release | head -4       # ID_LIKE="rhel centos fedora"
cat /etc/redhat-release
rpm -q rocky-release
```

---

# 📦 Partie 1 — `dnf` et `rpm`

Même partage des rôles que sous Debian : **`rpm`** manipule les paquets installés (comme
`dpkg`), **`dnf`** gère les dépôts et les dépendances (comme `apt`).

## 1.1 — Les dépôts

```bash
dnf repolist                        # baseos, appstream, extras
ls /etc/yum.repos.d/                # un fichier .repo par dépôt
```

| Dépôt | Contenu |
|---|---|
| **BaseOS** | Le cœur du système, supporté pendant tout le cycle de vie |
| **AppStream** | Applications, langages, bases de données |
| **EPEL** | *Extra Packages for Enterprise Linux* : paquets Fedora recompilés, maintenus par la communauté |

## 1.2 — Chercher, installer, interroger

```bash
dnf check-update                    # ≈ apt update + apt list --upgradable
dnf search nginx
dnf info nginx                      # version, dépôt d'origine
dnf install -y nginx
```

⚠️ **Première différence avec Debian** : le service n'est **ni démarré, ni activé**.

```bash
systemctl is-active nginx           # -> inactive
systemctl is-enabled nginx          # -> disabled
systemctl enable --now nginx
curl -s localhost | head -3
```

Interroger la base `rpm` :

```bash
rpm -qa | wc -l                     # tous les paquets installés
rpm -qi nginx                       # informations
rpm -ql nginx-core | head           # fichiers livrés par un paquet
rpm -qf /etc/nginx/nginx.conf       # à quel paquet appartient ce fichier ?
rpm -qc nginx-core                  # ses fichiers de configuration
dnf provides semanage               # quel paquet fournit cette commande ?
```

💡 **`rpm -V` vérifie l'intégrité** d'un paquet installé (taille, empreinte, droits, date) :

```bash
echo "# modif" >> /etc/nginx/nginx.conf
rpm -V nginx-core                   # -> S.5....T.  c /etc/nginx/nginx.conf
```

| Lettre | Signification |
|---|---|
| `S` | Taille différente |
| `5` | Empreinte différente : le contenu a changé |
| `T` | Date de modification différente |
| `c` | C'est un fichier de configuration |

`rpm -Va` le fait pour **tout** le système : un outil de détection d'intrusion basique.

```bash
sed -i '/^# modif$/d' /etc/nginx/nginx.conf
```

## 1.3 — EPEL, historique, annulation

```bash
dnf install -y epel-release         # ajoute le dépôt EPEL
dnf repolist                        # epel apparaît
dnf install -y htop

dnf history                         # chaque transaction est numérotée
dnf history info last
dnf history undo last -y            # ✅ désinstalle htop ET ses dépendances
```

💡 `dnf history undo` n'a pas d'équivalent direct sous Debian : c'est l'assurance de pouvoir
revenir en arrière proprement après une installation.

```bash
dnf group list                      # ensembles de paquets (« Server with GUI »…)
```

---

# 🧱 Partie 2 — firewalld

Contrairement à Debian, le pare-feu est **actif dès l'installation**.

## 2.1 — Constater le blocage

nginx tourne, mais depuis le **poste** :

```bash
curl http://192.168.56.40/
# -> curl: (7) Failed to connect … No route to host
```

💡 `No route to host` alors que `ping` passe : c'est la signature d'un **rejet** par le
pare-feu (réponse ICMP *host-prohibited*), pas d'un problème réseau.

## 2.2 — État et zones

```bash
systemctl status firewalld --no-pager
firewall-cmd --state                # -> running
firewall-cmd --get-active-zones     # interfaces enp0s3 et enp0s8 dans la zone public
firewall-cmd --list-all             # services : cockpit dhcpv6-client ssh
```

| Notion | Rôle |
|---|---|
| **Zone** | Un niveau de confiance (`public`, `internal`, `trusted`, `drop`…), associé à des interfaces ou à des réseaux sources |
| **Service** | Un nom pour un ou plusieurs ports (`http` = 80/tcp). Liste : `firewall-cmd --get-services` |
| **Port** | Un port brut, quand aucun service n'existe : `8090/tcp` |

## 2.3 — Ouvrir un port : *runtime* vs *permanent*

```bash
firewall-cmd --add-service=http     # effet immédiat…
firewall-cmd --list-services
```

✅ Depuis le poste, `curl http://192.168.56.40/` répond. Maintenant :

```bash
firewall-cmd --reload
firewall-cmd --list-services        # ❌ http a disparu
```

⚠️ **Le piège n°1 de firewalld.** Sans `--permanent`, la règle ne vit qu'en mémoire : un
`--reload` ou un redémarrage l'efface. Avec `--permanent`, elle est écrite sur disque mais
**pas appliquée** tant qu'on ne recharge pas. La bonne séquence :

```bash
firewall-cmd --permanent --add-service=http
firewall-cmd --reload
firewall-cmd --list-services        # ✅ http présent
cat /etc/firewalld/zones/public.xml # la configuration persistante
```

Fermer ce qui ne sert pas :

```bash
firewall-cmd --permanent --remove-service=cockpit
firewall-cmd --reload
firewall-cmd --list-all
```

---

# 🛡️ Partie 3 — SELinux

## 3.1 — Le principe

Les droits Unix (`rwx`) sont **discrétionnaires** : le propriétaire d'un fichier en fait ce
qu'il veut, et root passe partout. SELinux ajoute un contrôle **obligatoire** : chaque
processus et chaque fichier porte une **étiquette** (contexte), et la politique décide quel
type de processus a le droit de toucher quel type de fichier ou de port.

**Ce qu'il protège :** un nginx compromis tourne en `httpd_t`. Même avec une faille, il ne
peut lire que des fichiers `httpd_sys_content_t`, écouter sur des ports `http_port_t`… et pas
`/etc/shadow`, ni `/root`, ni ouvrir une connexion vers une base de données.

```bash
getenforce                          # -> Enforcing
sestatus                            # politique « targeted »
```

| Mode | Effet |
|---|---|
| `Enforcing` | La politique est appliquée, les refus sont journalisés |
| `Permissive` | Rien n'est bloqué, mais tout ce qui **aurait été** bloqué est journalisé |
| `Disabled` | SELinux est éteint (à éviter) |

## 3.2 — Lire les contextes

L'option `-Z` affiche l'étiquette, sous la forme `utilisateur:rôle:TYPE:niveau`. Seul le
**type** compte en pratique.

```bash
ps -eZ | grep nginx                 # system_u:system_r:httpd_t:s0  → le processus
ls -Z /usr/share/nginx/html/        # httpd_sys_content_t           → ce qu'il peut servir
ls -dZ /root /tmp /etc/shadow       # admin_home_t, tmp_t, shadow_t → interdits à httpd_t
id -Z                               # vous : unconfined_t (non confiné)
```

## 3.3 — Le piège du `mv`

```bash
echo "Page de test" > /root/page.html
mv /root/page.html /usr/share/nginx/html/
curl -s -o /dev/null -w "%{http_code}\n" localhost/page.html   # -> 403
```

Les droits Unix sont pourtant bons :

```bash
ls -l /usr/share/nginx/html/page.html    # -rw-r--r-- root root
ls -Z /usr/share/nginx/html/page.html    # admin_home_t  ← l'étiquette de /root
```

💡 **`mv` conserve l'étiquette d'origine, `cp` prend celle du dossier de destination.** Le
fichier est toujours étiqueté « home de root », et nginx n'a pas le droit de le lire.

Où trouver la preuve :

```bash
ausearch -m AVC -ts recent          # denied { read } … comm="nginx" … tcontext=…admin_home_t
journalctl -t setroubleshoot --no-pager -n 5   # la même chose, expliquée en anglais
```

Correction : remettre l'étiquette **par défaut** du chemin.

```bash
restorecon -v /usr/share/nginx/html/page.html
curl localhost/page.html            # ✅ Page de test
```

## 3.4 — Un site hors des chemins standard

On veut servir `/srv/site` sur le port **8090**.

```bash
mkdir -p /srv/site
echo "Site sur 8090" > /srv/site/index.html

cat > /etc/nginx/conf.d/site.conf <<'EOF'
server {
    listen 8090;
    root /srv/site;
}
EOF

nginx -t
systemctl restart nginx             # ❌ échec
journalctl -u nginx -n 5 --no-pager # bind() to 0.0.0.0:8090 failed (13: Permission denied)
```

**Premier blocage : le port.** `httpd_t` ne peut écouter que sur les ports `http_port_t` :

```bash
semanage port -l | grep ^http_port_t     # 80, 81, 443, 488, 8008, 8009, 8443, 9000
semanage port -a -t http_port_t -p tcp 8090
systemctl restart nginx                  # ✅
curl -s -o /dev/null -w "%{http_code}\n" localhost:8090   # -> 403
```

**Second blocage : les fichiers.** `/srv` est étiqueté `var_t` :

```bash
ls -Z /srv/site/index.html               # var_t
```

`restorecon` ne suffit pas ici : l'étiquette par défaut de `/srv/site` **est** `var_t`. Il
faut d'abord changer la règle, puis l'appliquer :

```bash
semanage fcontext -a -t httpd_sys_content_t "/srv/site(/.*)?"
semanage fcontext -l -C                  # vos règles locales
restorecon -Rv /srv/site
curl localhost:8090                      # ✅ Site sur 8090
```

⚠️ **`chcon -t …` marche aussi, mais seulement jusqu'au prochain `restorecon`** (ou à un
réétiquetage complet du système). `semanage fcontext` + `restorecon` est la seule méthode
persistante.

Enfin, le pare-feu, pour un accès depuis le poste :

```bash
firewall-cmd --permanent --add-port=8090/tcp
firewall-cmd --reload
```

✅ Depuis le poste : `curl http://192.168.56.40:8090/`

## 3.5 — Les booléens

Certains comportements sont des interrupteurs prévus par la politique. Exemple : nginx en
**reverse proxy** vers une application locale.

```bash
# Une « application » sur le port 5000
mkdir -p /tmp/appli && echo "Reponse de l'application" > /tmp/appli/index.html
python3 -m http.server 5000 --bind 127.0.0.1 --directory /tmp/appli &

cat > /etc/nginx/default.d/appli.conf <<'EOF'
location /appli/ {
    proxy_pass http://127.0.0.1:5000/;
}
EOF
systemctl restart nginx

curl -s -o /dev/null -w "%{http_code}\n" localhost/appli/   # -> 502
tail -1 /var/log/nginx/error.log         # connect() … failed (13: Permission denied)
```

Par défaut, `httpd_t` n'a pas le droit d'**ouvrir** de connexion réseau :

```bash
getsebool -a | grep httpd                # tous les interrupteurs liés au web
getsebool httpd_can_network_connect      # -> off
setsebool -P httpd_can_network_connect on   # -P : persistant
curl localhost/appli/                    # ✅ Reponse de l'application
kill %1
```

## 3.6 — Le bon réflexe face à un refus

```bash
setenforce 0        # Permissive, temporairement : si ça marche, c'est SELinux
setenforce 1        # et on le remet AUSSITÔT
```

Puis on corrige la vraie cause, dans cet ordre :

1. **Mauvaise étiquette** → `restorecon`, ou `semanage fcontext` + `restorecon`
2. **Port non standard** → `semanage port -a`
3. **Comportement prévu mais désactivé** → `setsebool -P`

⚠️ `setroubleshoot` propose souvent `audit2allow` pour générer un module qui autorise le
refus. C'est le **dernier recours** : on autorise alors exactement ce que SELinux bloquait, y
compris si c'était une attaque.

⚠️ Ne désactivez jamais SELinux (`SELINUX=disabled` dans `/etc/selinux/config`) pour « faire
marcher » une application : c'est retirer la protection de toute la machine pour un problème
d'étiquette.

---

## 🏋️ Exercices

1. **Sans `mv`** — refaites le §3.3 avec `cp` au lieu de `mv`. Quelle étiquette obtient le
   fichier ? Pourquoi ?
2. **Le home des utilisateurs** — servez `~vagrant/public_html` avec nginx. Quel booléen
   faut-il activer (`getsebool -a | grep home`) ? Quelle étiquette pour les fichiers ?
3. **Une zone de confiance** — ajoutez le réseau `192.168.56.0/24` à la zone `trusted`
   (`--add-source`). Que devient l'accès au port 8090 sans règle de port ?
4. **Mises à jour de sécurité** — listez seulement les mises à jour de sécurité
   (`dnf updateinfo list --security`) et appliquez-les (`dnf upgrade --security`).

---

## 🆘 Dépannage

| Symptôme | Cause | Solution |
|---|---|---|
| `No route to host` depuis le poste, `ping` OK | firewalld rejette le port | `firewall-cmd --permanent --add-service=…` puis `--reload` |
| Règle firewalld disparue | Ajoutée sans `--permanent` | La rajouter avec `--permanent`, puis `--reload` |
| `403` alors que les droits Unix sont bons | Mauvaise étiquette SELinux | `ls -Z`, puis `restorecon` / `semanage fcontext` |
| `bind() … (13: Permission denied)` | Port non autorisé pour le service | `semanage port -a -t http_port_t -p tcp PORT` |
| `502`, `connect() … (13: Permission denied)` | nginx n'a pas le droit de se connecter | `setsebool -P httpd_can_network_connect on` |
| `semanage: command not found` | Paquet absent | `dnf install -y policycoreutils-python-utils` |
| Service installé mais rien n'écoute | Pas démarré par défaut sous RHEL | `systemctl enable --now SERVICE` |

---

## 🧹 Nettoyage

```bash
vagrant destroy -f        # depuis TP8-RedHat/, sur le poste
```
