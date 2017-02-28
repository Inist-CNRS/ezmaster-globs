# GLoBS
*Github LOcal Backup Server* (prototype)

Permet de disposer localement à l'INIST d'un clone des dépôts GitHub créés et
utilisés au DPI de l'INIST.


## Concepts
  * serveur Git
  * serveur HTTP léger pointant sur les projets
  * update régulier des dépôts du serveur local via cron à partir d'une liste
    de dépôts GitHub exploités par le DPI

## Utilisation
Pour installer un GLoBS, il suffit de lancer ``install.sh`` (de préférence sur
une machine fraichement installée en ``Ubuntu server`` dont l'utilisateur
principal est « globs »).

```
    $ ./install.sh
``` 

## Fonctionnement

### repositories.list
Dans ``/home/globs/bin`` vous trouverez le fichier texte ``repositories.list``
qui contient la liste des dépôts (une URL par ligne) à cloner.
Ce fichier peut être édité à tout moment. Les nouveaux dépôts seront clonés dans
``/home/git`` (et ceux déjà clonés seront mis à jour grâce au script exécuté par
cron).

### Mise-à-jour
Toutes les heures les dépôts locaux sont mis-à-jour pour refléter leurs 
homologues de GitHub grâce au script ``/home/globs/bin/globs.cron.sh``.
Parallèlement, le serveur est remis à l'heure grâce à un autre script executé 
par root (``/home/globs/bin/root.cron.sh``).

### Accès
Les dépôts sur GLoBS sont accessibles classiquement en SSH et HTTP.

#### SSH
Vous pouvez clôner les dépôts grâce à une commande du type

```
  $ git clone git@nom.du.serveur.globs/ezmaster.git
```

#### HTTP

```
  $ git clone http://nom.du.serveur.globs/ezmaster.git
```
