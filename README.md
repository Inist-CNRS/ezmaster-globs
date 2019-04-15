# ezmaster-globs

[![Build Status](https://travis-ci.org/Inist-CNRS/ezmaster-globs.svg?branch=master)](https://travis-ci.org/Inist-CNRS/ezmaster-globs) [![Docker Pulls](https://img.shields.io/docker/pulls/inistcnrs/ezmaster-globs.svg)](https://registry.hub.docker.com/u/inistcnrs/ezmaster-globs/)

GLoBS : *Github LOcal Backup Server*

L'objectif de cette application est de sauvegarder localement des clones de dépôts GitHub afin de proposer un moyen de sauvegarde et de pouvoir temporairement s'y synchroniser dans le cas où github est down.

L'application permet de :

- régulièrement (variable `DUMP_EACH_NBMINUTES`) cloner et se synchroniser avec les dépôts des organisations github passées en argument (variable `GITHUB_ORGANIZATIONS`)
- mettre à disposition les dépôts clonés à travers un serveur web (protocole http) et ainsi permettre de réaliser des `git clone` en lecture seule de ces dépôts
- (optionnellement) réaliser un mirroir des dépôts sur une instance gitlab

## Variables de configuration

- `GITHUB_ORGANIZATIONS` doit contenir la liste des organisation github que vous souhaitez sauvegarder.
- `GITHUB_PERSONAL_ACCESS_TOKEN` doit contenir le token OAUTH issu d'un compte github pour pouvoir naviguer via l'API de github dans la liste des dépôts et pouvoir dépasser la [limite de requête en mode anonyme](https://developer.github.com/v3/#rate-limiting). Pour le générer, rendez vous ici : https://github.com/settings/tokens (attention ce token ne doit pas être partagé)

- `GITLAB_HTTP_BASEURL` doit pointer vers la racine http de votre instance gitlab cible vers laquelle vous souhaitez réaliser des mirroirs (sans le / de fin). Exemple : "https://git.abes.fr"
- `GITLAB_SSH_BASEURL` doit pointer vers la racine de l'accès SSH du dépôt git sous gitlab (utilisé au moment de faire un git push vers gitlab via ssh). Exemple: "git@git.abes.fr"
- `GITLAB_PERSONAL_ACCESS_TOKEN` doit contenir le token permettant d'accéder à l'API de votre instance gitlab. Pour le générer, rendez vous ici https://git.abes.fr/profile/personal_access_tokens (adaptez votre baseurl & attention ce token ne doit pas être partagé)
- `GITLAB_GROUP_PREFIX` contient un optionnel préfixe qui sera utilisé au moment de la création des groupes gitlab en mirroir des organizations github. Ex: "inist-cnrs" coté github deviendrait "github-backup-inist-cnrs" coté gitlab dans le cas où GITLAB_GROUP_PREFIX vaut "github-backup-"  

- `DUMP_EACH_NBMINUTES` doit contenir le temps à attendre entre chaque sauvegarde.
- `DUMP_TO` doit contenir la liste des emplacement où sauvegarder : "local" et/ou "gitlab"

## Production avec ezmaster

Utilisez [ezmaster](https://github.com/Inist-CNRS/ezmaster) et déployez l'application `inistcnrs/ezmaster-globs:2.0.3`

Créez ensuite une instance de cette application et paramétrez-la en modifiant ces variables dans la config JSON :

```json
{
  "GITHUB_ORGANIZATIONS": [ "inist-cnrs", "istex" ],
  "GITHUB_PERSONAL_ACCESS_TOKEN": "change me",
  "GITLAB_HTTP_BASEURL": "https://git.abes.fr",
  "GITLAB_SSH_BASEURL": "git@git.abes.fr",
  "GITLAB_PERSONAL_ACCESS_TOKEN": "change me",
  "GITLAB_GROUP_PREFIX": "github-backup-",
  "DUMP_EACH_NBMINUTES": 1,
  "DUMP_TO": [ "local", "gitlab "]
}
```

## Production sans ezmaster

Utilisez alors docker pour déployer `inistcnrs/ezmaster-globs:2.0.3`

Créez et lancez alors le conteneur de cette manière :

```shell
GITHUB_ORGANIZATIONS="abes-esr Transition-bibliographique" \
GITHUB_PERSONAL_ACCESS_TOKEN="change me" \
GITLAB_HTTP_BASEURL="https://git.abes.fr" \
GITLAB_SSH_BASEURL="git@git.abes.fr" \
GITLAB_PERSONAL_ACCESS_TOKEN="change me" \
GITLAB_GROUP_PREFIX="github-backup-" \
DUMP_EACH_NBMINUTES=5 \
DUMP_TO="local gitlab" \
docker-compose up
```

## Développements

```bash
npm run build # pour construire l'image docker
npm run debug # pour lancer le serveur web et le clonage
DUMP_EACH_NBMINUTES=1 GITHUB_ORGANIZATIONS="abes-esr" npm run debug # pour personnaliser depuis des variables d'env
```

Se connecter ensuite sur http://127.0.0.1:8080/ pour visualiser les dépôts, par défaut `config.json` référence les dépôts de [l'organisation github `inist-cnrs`](https://github.com/Inist-CNRS/)

Vous pouvez tester de les cloner à partir du serveur web fourni par ezmaster-globs de cette manière (exemple ici sur le dépôt node-xml-writer qui est cloné localement par défaut car config.json demande de cloner l'organisation github inist-cnrs) :

```
git clone http://127.0.0.1:8080/inist-cnrs/node-xml-writer.git
```

