# Description du projet:

Le projet consiste en la création d'un compilateur pour des fichiers source contenant une liste 
d'algorithmes écrits dans le format ALgo, qui est un package LaTeX pour écrire des algorithmes. 
Le compilateur prend en charge les algorithmes simples ainsi que les algorithmes récursifs, 
et il génère un fichier assembleur NASM.
Ce fichier assembleur peut ensuite être assemblé et exécuté pour obtenir le résultat final 
de l'algorithme appelé en dernier dans le fichier source.


## Compilation et exécution:


Pour compiler le projet:
	`make`

Pour compiler un fichier source contenant une liste d'algorithmes ALgo :
	`./prog <nom_du_fichier>`

Pour assembler le fichier assembleur généré et générer un exécutable:
	`./asipro <nom_du_fichier.asm> <nom_exec>`

Enfin, pour exécuter le programme et obtenir le résultat final :
	`./sipro <nom_exec>`
