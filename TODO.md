# TODO

- Faire de munitions, carburant des beliefs
- Mettre à jours le belief convoi critic lors d'un split
- Message Drones to Drones
- Messages Leader to Leader
- Ne pas calculer  le A* a chaque fois qu'il y a un hostile sur le chemin

# DONE

- Mettre la possibilité de faire un A* en évitant des zones
- Si le A* en evitant les zones calcul A* basic mais prevenir les drones de nettoyer les zones sensibles
- Mettre la zone directement en variable des patches comme elle ne changera pas !! (sauf si on veut que la taille des zones soit dynamique )
- Remplacer dans le code le calcul des patch-to-zone par la fonction **patch-to-zone**
- Pour le A* avec les zone regarder si dans les zones il n'y a pas le point de depart,la base, let l'objectif (arrivée en gle car on pourrait etre un leurre !!!!!!)
