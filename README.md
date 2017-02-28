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
une machine fraichement installée en ``Ubuntu server``).

```
    $ ./install.sh
```

## Fonctionnement
