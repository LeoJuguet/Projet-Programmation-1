# Projet-Programmation-1
Projet de programmation, d'implémentation d'un compilateur d'expression arithmétique vers assembleur X86-64, en Ocaml, nommé `aritha`

## Compilation
### Compilation du compilateur
Pour compiler le compilateur `aritha` lancez la commande :
`make aritha`. Cela compile le compilateur d'expression arithmétiqe sous un exécutable nommé `aritha`.

### Compilation du rapport
Pour compiler le rapport lancez la commande :
`make rapport`. Cela compile le rapport sous un fichier nommé `rapport.pdf`.

### Tout compiler
Pour tout compiler exécutez la comande :
`make`. Cela effectue les deux commandes précédentes.

## Compilateur aritha
La syntaxe pour compiler un fichier avec des expressions arithmétiques supporté est la suivante :

```aritha <file> [-o <output>]```

- `-o` Définir le nom du fichier
- `-help` Afficher la liste des options
- `--help` Afficher la liste des options

Le nom du fichier créer est par défaut le nom de votre fichier avec l'extension `.s`.
Le fichier générer est un code assembleur qui peut être compilé en exécutable avec `gcc -no-pie <file>.s` puis exécuté avec `./a.out`.
## Test
Des tests sont disponibles dans le dossier [test](./test/). Pour afficher la liste des tests vous pouvez effectuer la commande `make listTest`.
Les tests sont constitués de deux fichiers, un fichier avec l'extension `.exp` qui contient un code compilable en assembleur par le compilateur généré lors de l'exécution de la commande `make`. Et un fichier avec l'extension `.ok` qui contient le résultat attendue lors de l'exécution de l'exécutable créer à partir du fichier `.s` générée par `aritha`.

### Test automatisé

Pour lancer tous les tests exécutez la commande `make test`

## Nettoyage
Pour nettoyer les fichiers créés lancez la commande `make clean`.

Pour nettoyer les fichiers créés lors de l'exécution des test effectuez un `make cleantest`.
