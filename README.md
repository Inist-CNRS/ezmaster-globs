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
- `DUMP_EACH_NBMINUTES` doit contenir le temps à attendre entre chaque sauvegarde.
- `GITLAB_BASEURL` doit pointer vers la racine http de votre instance gitlab cible vers laquelle vous souhaitez réaliser des mirroirs.
- `GITLAB_API_TOKEN` doit contenir le token permettant d'accéder à l'API de votre instance gitlab.

## Production avec ezmaster

Utilisez [ezmaster](https://github.com/Inist-CNRS/ezmaster) et déployez l'application `inistcnrs/ezmaster-globs:2.0.3`

Créez ensuite une instance de cette application et paramétrez-la en modifiant ces variables dans la config JSON :

```json
{
  "GITHUB_ORGANIZATIONS": [ "inist-cnrs", "istex" ],
  "DUMP_EACH_NBMINUTES": 1,
  "GITLAB_BASEURL": "https://git.abes.fr",
  "GITLAB_API_TOKEN": "xxxxx"
}
```

## Production sans ezmaster

Utilisez alors docker pour déployer `inistcnrs/ezmaster-globs:2.0.3`

Créez et lancez alors le conteneur de cette manière :

```shell
docker run -d -p 8080:80 --name ezmaster-globs inistcnrs/ezmaster-globs:2.0.3
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

