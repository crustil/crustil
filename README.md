# CRUSTIL

Crustil est un ensemble d'outils de gestion de configuration Docker et de projet. Il est utile pour le développement et pour la mise en production.

## Installation

Installation depuis les sources git.

```bash
$ git clone ssh://git@github.com:tfSheol/crustil.git
$ cd crustil
$ sudo npm install -g
```

Installation via **[npmjs.com/package/crustil](https://npmjs.com/package/crustil)**.

```bash
$ sudo npm install -g crustil
```

--------------------------------------------------------------------------------

## crustil

### 1 - Fichier de configuration `config.properties`

```yaml
project.name=framework                                                   # nom du projet principal
project.domain=<domain.fr>                                               # nom de domain du projet
project.api=<api.domain.fr>                                              # nom de domain de l'api (souvent le point d'entré de l'api-gateway)

project.xx.name=xxxxx
project.xx.version=0.0.1
project.xx.version.base=latest

project.stack.name=project_name                                          # nom du projet de l'alias `stack`
project.stack.version=0.0.3                                              # version du projet
project.stack.version.base=latest                                        # version de l'image Docker utilisée pour la création des images Docker java

project.admin.name=micro-service/project/admin-dashboard
project.admin.dashboard.json=<json_dashboard>
project.admin.version=0.0.1

project.monitor.name=micro-service/project/monitor-dashboard
project.monitor.dashboard.json=<json_dashboard>
project.monitor.version=0.0.1

project.test.name=micro-service/project/bla
project.test.json.path=<json_vertx_path_other_stack_project>

project.services.db=db,adminer,hazelcast                                 # définie les services docker à lancer via un alias normmé "db"
project.services.init=traefik,db,adminer,rethinkdb
project.services.base=api-gateway,health-service
project.services.oauth=login-service,law-service,...                     # liste des services oauth
project.services.stack=account-service
project.services.xx=xx-xxxx-service                                      # il est possible de ratacher plusieurs configurations à un projet, ici le projet "xx"

project.xx.json.path=/data/xxxxx/config/vertx
project.xx.dashboard.json=/data/xxxxx/config/dashboard

project.stack.json.path=/data/stack/config/vertx                          # chemin de la configuration vertx
project.stack.dashboard.admin.json=/data/stack/config/dashboard-admin     # chemin de la configuration frontend du dashboard admin

project.base.gateway.json.path=/data/xxxx/config/gateway                  # chemin de la configuration spécifique utilisée par l'api-gateway

registry=registry.cloudvector.fr/<project_name>                           # url du registry Docker suvi du
nginx.config.path=$(lib)/nginx                                            # chemin de configuration de Nginx
traefik.version=v1.7.19                                                   # version de Traefik
traefik.config.path=$(lib)/traefik                                        # dossier de configuration de Traefik

hazelcast.version=3.12.4                                                  # version d'Hazelcast
hazelcast.memory=512M                                                     # memoire maximun attribuée à Hazelcast pour son runtime
hazelcast.config.path=$(lib)/hazelcast                                    # dossier de configuration d'Hazelcast

db.connector=db                                                           # connecteur pour le serveur de base de donnée, c'est également un host
db.root.host=%                                                            # scrop de droit MariaDB, MySQL,...
db.database=fc                                                            # non de la base de donnée par défaut
db.root.password=password                                                 # mot de passe pour l'utilisateur `root` utilisé lors de la connexion à la base de donnée
db.user=test                                                              # nom d'utilisateur initialisé ç l'initialisation de la base de donnée
db.password=password                                                      # mot de passe pour l'utilsateur `test` renseigné précédament
db.sql.script=$(pwd)/sql/init                                             # chemin des scripts SQL appliqués lors de l'initialisation de la base de donnée

nosql.build.path=$(lib)/rethinkdb
nosql.tools.data.path=$(lib)/data/rethinkdb
```

### 2 - Paramètres

Certains paramètres utilisent le dossier d'installation de Crustil ainsi que certains fichiers de configurations présents dans ce même dossier.

```bash
CRUSTIL="$(npm root -g)/crustil/"

$(lib) est remplacé par $(npm root -g)/crustil # dossier d'installation de Crustil
$(pwd) est remplacé par $(pwd)/ + la valeur du paramètre --config-path
```

Voici la liste des paramètres disponible pour toutes les commandes suivantes

```bash
--working-directory=<chemin_du_dossier_de_travail>  # defaut : valeur de $(lib)
--config-path=<chemin_du_fichier_de_configuration>  # defaut : valeur de $(lib)
--config-name=<nom_du_fichier_de_configuration>     # défaut : config.properties
--project-path=<chemin_du_projet>                   # défaut : valeur de $(lib)
--compose-path=[../,.,/home]                        # pas de valeur par défaut, attends une liste de chemin
```

### 3 - Démarrer les services de bases (utile pour le développement)

Lancement de la base de donnée (MariaDB), adminer & hazelcast

```bash
$ crustil start db
```

Adminer est disponible via l'url suivante : `http://docker:8085`

```sql
Système : MySQL
Serveur : db
Utilisateur : root
Mot de passe : password
Base de données : à_laisser_vide
```

> Le port multicast d'hazelcast est : `54327`

### 4 - cmd/paramètre `--generate-config-file`

Générer un fichier de configuration basique pour un nouveau projet.

```bash
$ crustil <cmd:optionnel> --generate-config-file
```

### 5 - paramètre `--prod`

Passer les nom de projet en mode production (utile pour la partie compilation).

```bash
$ crustil <cmd> --prod
```

### 6 - cmd `generate` livrable et production

Génère un fichier `docker-compose.yml` issue du fichier `config.properties`.

```bash
$ crustil generate
$ crustil generate --prod
```

### 7 - cmd ``

--------------------------------------------------------------------------------

## crustil_backup_project

Script utilisé par le système de génération automatique présent sur `gitlab-ci`. Il copie tous les projets enfants d'un projet `parent` dans un dossier `build`.

> Script à utiliser dans un dossier `parent` prossédant un fichier **pom.xml**

```bash
$ crustil_backup_project
```

--------------------------------------------------------------------------------

## crustil_build

Script permettant de construire les images Docker des projets **Angular2+**.

> tips: Il est possible d'éxécuter ce script dans le dossier courant en spécifiant les chemins par "."

### 1 - Paramètres

```bash
--config-path=<chemin/du/fichier/de/configuration>         # pas de valeur par défaut
--config-name=<nom_du_fichier_de_configuration>            # défaut: build.properties
--dockerfile-context=<chemin/du/context/dockerfile>        # défaut : . répertoire courant
--dockerfile=<nom_du_dockerfile>                           # défaut : Dockerfile
--dockerfile-path=<chemin/du/fichier/dockerfile>           # défaut : . répertoire courant
```

### 2 - fichier de configuration `build.properties`

```properties
project.name=project/dashboard
registry=registry.domain.com
version=0.0.3
dashboard.name=dashboard
```

### 3 - build des images

Construction des images Docker pour les projets **Angular2+**.

```bash
$ crustil_build --config-path=.
$ crustil_build --config-path=$(pwd)/docker --dockerfile=Dockerfile --dockerfile-path=$(pwd)/docker --dockerfile-context=$(pwd)/docker/
```

### 4 - tag

Construction des images docker pour les projets **Angular2+** et aposer le tag complet (registry) présent dans le ficher `build.properties`.

```bash
$ crustil_build --config-path=. --tag
$ crustil_build --config-path=$(pwd)/docker --dockerfile=Dockerfile --dockerfile-path=$(pwd)/docker --dockerfile-context=$(pwd)/docker/ --tag
```

### 5 - push

Construction des images Docker pour les projets **Angular2+** et envoyer directement sur le registry Docker spécifié dans le fichier `build.properties`.

```bash
$ crustil_build --config-path=. --push
$ crustil_build --config-path=$(pwd)/docker --dockerfile=Dockerfile --dockerfile-path=$(pwd)/docker --dockerfile-context=$(pwd)/docker/ --push
```

### 6 - tag + push

Permet la construction, l'aposition du tag registry et l'envoit sur la registry distante (voir **5 - tag** et **6 - tag + push**)

```bash
$ crustil_build --config-path=. --tag --push
$ crustil_build --config-path=$(pwd)/docker --dockerfile=Dockerfile --dockerfile-path=$(pwd)/docker --dockerfile-context=$(pwd)/docker/ --tag --push
```

--------------------------------------------------------------------------------

## crustil_build_old

Ancien script de build multi sources (Java & Node). Ce script permet de build les projets et de build les images Docker.

> Le script n'est pas assez permissif pour généréer aujourd'hui les builds projets.

> > Le script doit obligatoirement être exécuté dans un dossier `parent`. La compatibilité de ce script est de moins en moins présente.

```bash
======== Config properties ========
=> project_name:
=> domain:
=> api:
=> registry:            registry.domain.com
===================================
Please use 'nvm use stable' (current stable node version: v12.4.0)
```

```bash
all       build all sources and all docker images
sources   build only sources
java      build java docker images
nginx     build nginx docker images
docker    build all docker images

crustil_build_old all|sources|java|nginx|docker
```

Construire toutes les sources + les images Docker d'un seul coup `sources (java + nginx) -> docker (java + nginx)`.

```bash
$ crustil_build_old all
```

Construire toutes les sources java + nginx.

```bash
$ crustil_build_old sources
```

Construire toutes les souces java.

```bash
$ crustil_build_old java
```

Construire toutes les sources node + images docker Nginx.

```bash
$ crustil_build_old nginx
```

Construire toutes les sources docker java.

```bash
$ crustil_build_old docker
```

--------------------------------------------------------------------------------

## crustil_clean

Ce script permet de nettoyer différents types de fichiers générés pendant le développement.

```bash
vertx      remove all tmp vertx folders
target     remove target folders
node       remove all extra node folders
project    remove all iml files (intellij)

crustil_clean vertx|target|node|project
```

> Pour toutes les commandes il est possible de se placer dans des répertoires parents pour effectuer ces tâches sur plusieurs projets.

Supprimer tous les fichiers temporaires générés par `vert.x`.

```bash
$ crustil_clean vertx
```

Supprimer tous les fichiers générés présents dans le dossier `target`.

```bash
$ crustil_clean target
```

Supprimer tous les dossiers `node_modules`.

```bash
$ crustil_clean node
```

Supprimer tous les fichiers temporaires d'Intelij IDEA.

```bash
$ crustil_clean project
```

--------------------------------------------------------------------------------

## crustil_fix_repository

Ce script désactive certaines configuration présentes dans git empêchant la bonne gestion git entre Windows et WSL (linux). `core.filemode false`

```bash
crustil_fix_repository <options>

  --working-directory=<path>         set working directory
```

> Pour toutes les commandes il est possible de se placer dans des répertoires parents pour effectuer ces tâches sur plusieurs projets.

Appliquer les correctifs **git** à partir du dossier courant.

```bash
$ crustil_fix_repository
```

Appliquer les correctifs **git** en spécifiant le dossier de travail.

```bash
$ crustil_fix_repository --working-directory=../
```

--------------------------------------------------------------------------------

## crustil_get_children_project

L'enssembles des commandes sont à effectuer depuis un projet `parent` (`nk-parent` || `da-parent`).

### 1 - Tags

#### 1.1 - Mise à jour depuis la master

```bash
$ crustil_get_children_project --reset
$ crustil_get_children_project --master
$ crustil_get_children_project --pull
```

#### 1.2 - Récupérer une version taggée

```bash
$ crustil_get_children_project –-reset
$ crustil_get_children_project –-pull
$ crustil_get_children_project --checkout-tag=0.0.3
```

```bash
$ crustil_get_children_project –-clone
$ crustil_get_children_project --checkout-tag=0.0.3
```

> En cas d'erreur, il est possible d'effectuer les commandes git à la main.

```bash
$ git checkout tags/0.0.3 -b 0.0.3-branch
```

#### 1.3 - Récupérer la dernière version taggée

```bash
$ crustil_get_children_project --checkout-last-tag
```

#### 1.4 - Tagger une nouvelle version (pour livraison)

> Important: `git push origin 0.0.3` permet de push la version du parent.

```bash
$ crustil_get_children_project --git-tag=0.0.3 --tag
```

--------------------------------------------------------------------------------

## crustil_set_ip

Ce script n'est utile que sur un système Windows disposant de WSL (version 2). Il modifie le fichier host de Windows pour rajouter / modifier une entrée `<ip> docker`

```
172.28.229.164 docker
```

> Il est possible d'exécuter ce script de puis n'importe quel dossier.

```bash
$ crustil_set_ip

IP: 172.28.229.164
replace: "172.28.229.164 docker"
```