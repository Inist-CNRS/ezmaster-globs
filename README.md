# ezmaster-globs
GLoBS : *Github LOcal Backup Server*

L'objectif de cette application est de sauvegarder localement des clones de dépôts GitHub afin de proposer un moyen de sauvegarde et de pouvoir temporairement s'y synchroniser dans le cas où github est down.

L'application permet de :

- régulièrement (variable `DUMP_EACH_NBMINUTES`) clonner et se synchroniser avec les dépôts des organisation github passées en argument (variable `GITHUB_ORGANIZATIONS`)
- mettre à disposition les dépôts clonés à travers un serveur web (protocole http) et ainsi permettre de réaliser des `git clone` en lecture seule de ces dépôts

## Production

Utiliser [ezmaster](https://github.com/Inist-CNRS/ezmaster) et déployer l'application `inist-cnrs/ezmaster-globs:1.0.0`

Créer ensuite une instance de cette application et paramétrez la en modifiant ces variables :

```json
{
  "GITHUB_ORGANIZATIONS": [ "inist-cnrs", "istex" ],
  "DUMP_EACH_NBMINUTES": 1
}
```

La variable `GITHUB_ORGANIZATIONS` doit contenir la liste des organisation github que vous souhaitez sauvegarder.

La variable `DUMP_EACH_NBMINUTES` doit contenir le temps à attendre entre chaque sauvegarde.

## Développements

```bash
make build     # pour construire l'image docker
make run-debug # pour lancer le serveur web et le clonnage
```

Se connecter ensuite sur http://127.0.0.1:8080/ pour visualiser les dépôts, par défaut `config.json` référence les dépôts de [l'organisation github `inist-cnrs`](https://github.com/Inist-CNRS/)

Vous pouvez alors les clonner localement de cette manière (exemple ici sur le dépôt node-xml-writer qui est clonné localement par défaut car config.json demande de clonner l'organisation github inist-cnrs) :

```
git clone https://127.0.0.1:8080/inist-cnrs/node-xml-writer
```

