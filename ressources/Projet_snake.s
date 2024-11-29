
# Bitmap Display : Mettez en Base address for display -> 0x10008000(gp)

.data 
    image_width:        .word 256     # Largeur de l'arène du jeu (en pixels)
    image_height:       .word 256     # Hauteur de l'arène du jeu (en pixels)
    width_of_unit:      .word 8       # Largeur d'un unit (en pixels)
    height_of_unit:     .word 8       # Hauteur d'un unit (en pixels)
    i_largeur:          .word 0       # Largeur de l'arène du jeu (en units)
    i_hauteur:          .word 0       # Hauteur de l'arène du jeu (en units)
    main_image:         .word 0       # Adresse de l'arène du jeu
    obst_image:         .word 0       # Adresse de l'image des obstacles
    last_column_index:  .word 0       # Index du dernier élément de la ligne
    last_row_index:     .word 0       # Index du dernier élément de la colonne
    nurriture:          .word 0       # Adresse du pixel représentant la nourriture
    nb_obstacle:        .word 20      # Nombre d'obstacles dans l'arène 
    nb_obst_image:      .word 145     # Nombre total d'obstacles et de bordures 
    message_fin:        .asciz "Le jeu est fini !\n" # Message de fin de jeu                          
    message_nouv_nurr:  .asciz "Nouvelle nourriture générée !\n" # Message lors de la création de nourriture
    fifo_tete:          .word 0       # Adresse de la tête du FIFO
    fifo_queue:         .word 0       # Adresse de la queue du FIFO
    fifo_longeur:       .word 0       # Longueur du serpent
    
    direction: .word 1      # Direction initiale (1 = bas)

.text

#-------------------------------# Initialisation
# Code pour initialiser les éléments nécessaires pour le jeu
call I_predef           # Initialiser les dimensions et indices de l'arène
call I_creer            # Créer l'image principale
la tp, nb_obstacle      # Charger le nombre d'obstacles
lw a0, 0(tp)            # Charger nb_obstacle dans a0
call O_creer            # Créer les obstacles
call N_creer            # Créer la nourriture
call F_creer            # Créer la file pour le serpent

# Afficher les obstacles et positionner la nourriture
la tp, obst_image
lw a0, 0(tp)            # Charger l'adresse de l'image des obstacles
la tp, nb_obst_image
lw a1, 0(tp)            # Charger le nombre d'obstacles dans a1
call O_afficher         # Afficher les obstacles
call N_placer           # Placer la nourriture
call Init_snake         # Initialiser le serpent

#------------------------------------------------

loop:		
    la tp, fifo_tete
    lw a0, 0(tp)            # Charger l'adresse de la tête du FIFO
    la tp, fifo_longeur
    lw a1, 0(tp)            # Charger la longueur du serpent
    call F_afficher         # Afficher la file FIFO

    # Lire l'état de RCR pour détecter une touche    
    li t2, 0xffff0000       # t2 : adresse de RCR
    lw t3, 0(t2)            # Lire l'état de RCR
    beq t3, zero, no_input  # Si RCR est 0, continuer sans action

    # Lire la touche pressée et déterminer la direction
    li t2, 0xffff0004       # t2 : adresse de RDR
    lw t4, 0(t2)            # Lire la touche pressée
    li t0, 122              # 'z' pour haut
    beq t4, t0, set_up
    li t0, 113              # 'q' pour gauche
    beq t4, t0, set_left
    li t0, 115              # 's' pour bas
    beq t4, t0, set_down
    li t0, 100              # 'd' pour droite
    beq t4, t0, set_right
    li t0, 120              # 'x' pour quitter
    beq t4, t0, end
    
no_input:
    # Utiliser l'appel système pour la pause en millisecondes
    li a0, 200              # Durée de la pause en ms 
    li a7, 32               # Code pour la temporisation en millisecondes
    ecall                   

    # Déplacement automatique selon la direction
    la tp, direction
    lw t0, 0(tp)              # Charger la direction actuelle

    li t1, 0                   # Direction haut
    beq t0, t1, move_up
    li t1, 1                   # Direction bas
    beq t0, t1, move_down
    li t1, 2                   # Direction gauche
    beq t0, t1, move_left
    li t1, 3                   # Direction droite
    beq t0, t1, move_right

    j loop                     # Retourner au début de la boucle

# Changement de direction en fonction de la touche appuyée
set_up:
    li t0, 0                   # Direction haut
    j update_direction
set_left:
    li t0, 2                   # Direction gauche
    j update_direction
set_down:
    li t0, 1                   # Direction bas
    j update_direction
set_right:
    li t0, 3                   # Direction droite
    j update_direction

update_direction:
    la tp, direction
    sw t0, 0(tp)               # Mettre à jour la direction
    j loop                     # Retourner dans la boucle

move_up:
    addi t6, t6, -1            # Déplacer le serpent vers le haut en diminuant y
    j verification

move_down:
    addi t6, t6, 1             # Déplacer le serpent vers le bas en augmentant y
    j verification

move_left:
    addi t5, t5, -1            # Déplacer le serpent vers la gauche en diminuant x
    j verification

move_right:
    addi t5, t5, 1             # Déplacer le serpent vers la droite en augmentant x
    j verification

#-------------------------------# Vérification
verification:
    mv a0, t5               # Charger la coordonnée x dans a0
    mv a1, t6               # Charger la coordonnée y dans a1
    call I_coordToAdresse   # Convertir les coordonnées en adresse
    lw a2, 0(a0)            # Charger le pixel à l'adresse calculée
    la tp, obst_image
    lw a0, 0(tp)            # Charger l'adresse de l'image des obstacles
    la tp, nb_obst_image
    lw a1, 0(tp)            # Charger le nombre d'obstacles dans a1
    call O_contient         # Vérifier si le pixel est un obstacle
    li t2, 1
    beq t2, a0, end         # Si c'est un obstacle, terminer le jeu

    # Vérifier si le serpent a mangé la nourriture
    mv a0, t5               # Charger la coordonnée x dans a0
    mv a1, t6               # Charger la coordonnée y dans a1
    call I_coordToAdresse   # Convertir les coordonnées en adresse
    la tp, nurriture
    lw tp, 0(tp)            # Charger l'adresse de la nourriture
    beq tp, a0, nouveau_placement # Si c'est la nourriture, placer une nouvelle nourriture
    
    # Vérifier si la tête touche le corps du serpent
    mv a0, t5                   # a0 : Coordonnée x de la tête du serpent
    mv a1, t6                   # a1 : Coordonnée y de la tête du serpent
    call I_coordToAdresse       
    lw a1, 0(a0)                
    la tp, fifo_tete            # tp : Adresse de la tête de la file FIFO
    lw a0, 0(tp)               
    call F_contient             # Vérifier si la tête du serpent touche son corps
    li tp, 1                    # tp : Valeur pour indiquer une collision = 1
    beq tp, a0, end             # Si a0 == 1 (collision), sauter à la fin du jeu


    # Déplacer le serpent
    mv a0, t5               # Charger la coordonnée x dans a0
    mv a1, t6               # Charger la coordonnée y dans a1
    call I_coordToAdresse   # Convertir les coordonnées en adresse
    lw a1, 0(a0)            # Charger le pixel à l'adresse calculée
    la tp, fifo_tete
    lw a0, 0(tp)            # Charger l'adresse de la tête du FIFO
    call F_enfiler          # Ajouter le nouveau pixel en tête
    call F_defiler          # Supprimer l'élément à la queue
    j loop                  # Revenir à la boucle principale

nouveau_placement:
    mv a0, t5               # Charger la coordonnée x dans a0
    mv a1, t6               # Charger la coordonnée y dans a1
    call I_coordToAdresse   # Convertir les coordonnées en adresse
    lw a1, 0(a0)            # Charger le pixel à l'adresse calculée
    la tp, fifo_tete
    lw a0, 0(tp)            # Charger l'adresse de la tête du FIFO
    call F_enfiler          # Ajouter la nourriture mangée en tête
    call N_placer           # Placer une nouvelle nourriture
    la a0, message_nouv_nurr
    li a7, 4                # Afficher le message de nouvelle nourriture
    ecall
    j loop                  # Revenir à la boucle principale

#-------------------------------# Fin du jeu
end:
    la a0, message_fin
    li a7, 4                # Afficher le message de fin de jeu
    ecall
    li a7, 10               # Appel système pour terminer le programme
    ecall  


#-------------------------------#Fonction-----------------------#
# Fonction qui calcule tous les éléments définis dans la section data
# Aucun argument requis, retourne rien.
# Initialise les dimensions en unités et les indices pour l'arène du jeu.
#-------------------------------#-------------------------------#
I_predef:			
    la t0, image_width           # t0 : Adresse de la largeur de l'arène 
    la t1, width_of_unit         # t1 : Adresse de la largeur d'un unit 
    lw t2, 0(t0)                 # t2 : Largeur de l'arène en pixels
    lw t3, 0(t1)                 # t3 : Largeur d'un unit en pixels
    div a0, t2, t3               # a0 : Largeur en unités (nombre d'unités par ligne)
    la t4, i_largeur             # t4 : Adresse de i_largeur
    sw a0, 0(t4)                 # Sauvegarder la largeur de l'arène en unités dans i_largeur
    
    addi a0, a0, -1              # a0 : i_largeur - 1 pour l'index du dernier élément de la ligne
    la t0, last_column_index     # t0 : Adresse de last_column_index
    sw a0, 0(t0)                 # Sauvegarder l'index de la dernière colonne dans data
    
    la t0, image_height          # t0 : Adresse de la hauteur de l'arène 
    la t1, height_of_unit        # t1 : Adresse de la hauteur d'un unit
    lw t2, 0(t0)                 # t2 : Hauteur de l'arène en pixels
    lw t3, 0(t1)                 # t3 : Hauteur d'un unit en pixels
    div a0, t2, t3               # a0 : Hauteur en unités (nombre d'unités par colonne)
    la t4, i_hauteur             # t4 : Adresse de i_hauteur
    sw a0, 0(t4)                 # Sauvegarder la hauteur de l'arène en unités dans i_hauteur
    
    addi a0, a0, -1              # a0 : i_hauteur - 1 pour l'index du dernier élément de la colonne
    la t0, last_row_index        # t0 : Adresse de last_row_index
    sw a0, 0(t0)                 # Sauvegarder l'index de la dernière ligne dans data
    ret                          # Retour de la fonction

#-------------------------------# Fonction
# Aucun argument requis, retourne l'adresse de l'espace mémoire alloué dans a0 (et le stocke dans main_image).
# Crée l'image de l'arène du jeu à l'adresse 0x10008000.
#-------------------------------#
I_creer:			
    la tp, i_largeur
    lw t1, 0(tp)                # t1 : i_largeur
    la tp, i_hauteur
    lw t2, 0(tp)                # t2 : i_hauteur

    mul t3, t1, t2              # t3 : Nombre total de pixels (i_largeur * i_hauteur)
    mul a3, t1, t2              # a3 : Total pixels (pour boucle d'initialisation)
    li a1, 4                    # a1 : Chaque adresse de pixel occupe 4 octets
    mul a1, a1, t3              # a1 : Taille totale en octets (nombre total de pixels * 4)

    mv a0, a1                   # a0 : Taille totale en octets pour l'allocation
    li a7, 9                    # Appel système pour sbrk (allocation mémoire)
    ecall                       # Allocation de mémoire

    bgez a0, alloc_success      # Si allocation réussie, sauter à alloc_success
    li a0, -1                   # Retourner -1 en cas d'échec d'allocation
    ret

alloc_success:
    la tp, main_image
    sw a0, 0(tp)                # Stocker l'adresse de l'image principale dans main_image
load_values:
    mv t0, a0                   # t0 : Adresse du premier unit de l'image
    li t1, 0x10008000           # t1 : Adresse du premier unit dans le bitmap
    li t2, 0                    # t2 : Compteur d'éléments de départ
    mv t3, a3                   # t3 : Nombre total d'unités
    li t4, 4                    # t4 : Incrément en octets
loading:
    bgt t2, t3, next_step       # Si t2 >= t3, fin de la boucle
    sw t1, 0(t0)                # Charger l'adresse dans le bitmap
    addi t2, t2, 1              # Incrémenter le compteur
    add t1, t1, t4              # Passer à l'adresse suivante
    add t0, t0, t4              # Incrémenter l'adresse de l'image
    j loading                   # Répéter la boucle
next_step:
    ret

#-------------------------------# Fonction
# Prend x en a0 et y en a1 comme paramètres, retourne l'adresse du pixel (x, y) dans a0.
# Convertit les coordonnées en adresse.
#-------------------------------#
I_coordToAdresse:			
    addi sp, sp, -4             # Ajuster le pointeur de pile
    sw ra, 0(sp)                # Sauvegarder l'adresse de retour
    li t3, 4                    # 4 octets par entier

    la t1, i_largeur
    lw t1, 0(t1)                # t1 : Largeur de l'image en unités

    mul t2, a1, t1              # t2 = y * largeur_pixels
    add t2, t2, a0              # t2 = (y * largeur_pixels) + x
    mul t2, t2, t3              # t2 : Multiplier par 4 pour obtenir l'adresse

    la t0, main_image
    lw t0, 0(t0)                # t0 : Adresse de départ de l'image
    add a0, t0, t2              # a0 : Adresse du pixel
    lw ra, 0(sp)                # Restaurer l'adresse de retour
    addi sp, sp, 4              # Restaurer le pointeur de pile
    ret

#-------------------------------# Fonction
# Prend une adresse en a0, retourne x en a0 et y en a1.
# Convertit l'adresse en coordonnées.
#-------------------------------#
I_adresseToCoord:		
    addi sp, sp, -4             # Ajuster le pointeur de pile
    sw ra, 0(sp)                # Sauvegarder l'adresse de retour
    la t0, main_image
    lw t0, 0(t0)                # t0 : Adresse de départ de l'image
    sub a0, a0, t0              # Soustraire l'adresse de départ pour obtenir l'offset en octets

    li t3, 4                    # 4 octets par pixel
    divu t2, a0, t3             # Diviser par 4 pour obtenir l'index du pixel

    la t1, i_largeur
    lw t1, 0(t1)                # t1 : Largeur de l'image en unités
    divu t4, t2, t1             # y = index du pixel / i_largeur
    remu a0, t2, t1             # x = index du pixel % i_largeur

    mv a1, t4                   # y dans a1, x est déjà dans a0
    lw ra, 0(sp)                # Restaurer l'adresse de retour
    addi sp, sp, 4              # Restaurer le pointeur de pile
    ret

#-------------------------------# Fonction
# Prend x en a0, y en a1, et couleur en a2 ; retourne void.
# Colorie un pixel en fonction des coordonnées et de la couleur donnée.
#-------------------------------#
I_plot:				
    addi sp, sp, -4             # Ajuster le pointeur de pile
    sw ra, 0(sp)                # Sauvegarder l'adresse de retour
    call I_coordToAdresse       # Appeler pour obtenir l'adresse du pixel

    lw a0, 0(a0)                # Charger l'adresse de l'unité dans a0
    sw a2, 0(a0)                # Stocker la couleur à l'adresse du pixel
    lw ra, 0(sp)                # Restaurer l'adresse de retour
    addi sp, sp, 4              # Restaurer le pointeur de pile
    ret

#-------------------------------# Fonction
# Prend l'adresse de l'image en a0, le nombre de pixels à colorier en a1, retourne void.
# Colore un nombre spécifique de pixels dans une image en bleu clair.
#-------------------------------#
O_afficher:			
    mv t0, a0                   # t0 : Adresse de l'image
    mv t1, a1                   # t1 : Nombre de pixels à colorier
    li t2, 0                    # t2 : Compteur de boucle
    li t3, 4                    # t3 : Incrément pour sauter de 4 octets à la prochaine adresse
    li t4, 0x003665FF           # t4 : Couleur bleu clair

color:
    bge t2, t1, end_O_afficher  # Si le compteur atteint le nombre de pixels, fin
    lw tp, 0(t0)                # Charger l'adresse actuelle
    sw t4, 0(tp)                # Appliquer la couleur
    add t0, t0, t3              # Passer à l'adresse suivante
    addi t2, t2, 1              # Incrémenter le compteur
    j color                     # Boucle pour colorier les pixels

end_O_afficher:
    ret
	
#-------------------------------# Fonction
# Adresse de l'image dans a0, nombre de pixels dans a1, pixel à rechercher dans a2
# Retourne 1 dans a0 si le pixel est trouvé dans l'image, sinon retourne 0
# Vérifie si un pixel appartient à une image
#-------------------------------#
O_contient:			
    mv t0, a0                # t0 : Adresse de l'image
    mv t1, a1                # t1 : Nombre d'éléments dans l'image
    mv t2, a2                # t2 : Pixel à rechercher
    li t3, 4                 # t3 : Incrément de 4 octets par élément
    li t4, 0                 # t4 : Compteur initialisé à 0

app:
    bge t4, t1, end_O_contient_0 # Si le compteur atteint le nombre d'éléments, quitter avec 0
    lw tp, 0(t0)                 # Charger le pixel courant de l'image
    beq tp, t2, end_O_contient_1 # Si le pixel courant est égal au pixel recherché, quitter avec 1
    addi t4, t4, 1               # Incrémenter le compteur
    add t0, t0, t3               # Passer à l'adresse du pixel suivant
    j app                        # Recommencer la vérification pour le pixel suivant

end_O_contient_1:
    li a0, 1                     # Retourner 1 si le pixel a été trouvé
    ret

end_O_contient_0:
    li a0, 0                     # Retourner 0 si le pixel n'a pas été trouvé
    ret

#-------------------------------# Fonction
# Nombre d'obstacles dans a0, retourne l'adresse de l'espace alloué dans a0 (stockée également dans obst_image)
# Alloue l'image pour les bordures et les obstacles
#-------------------------------#
O_alloc:
    addi sp, sp, -4             # Ajuster le pointeur de pile
    sw ra, 0(sp)                # Sauvegarder l'adresse de retour

    li t0, 0                    # t0 : Compteur de largeur initialisé
    li t1, 0                    # t1 : Compteur de hauteur initialisé
    li t2, 2                    # t2 : Multiplicateur pour la bordure

    la tp, i_largeur
    lw tp, 0(tp)                # tp : Largeur de l'arène en unités
    add t0, tp, tp              # t0 : Largeur totale des bordures (2 * i_largeur)

    la tp, i_hauteur
    lw tp, 0(tp)                # tp : Hauteur de l'arène en unités
    add t1, tp, tp              # t1 : Hauteur totale des bordures (2 * i_hauteur)

    add t3, t0, t1              # t3 : Nombre total de pixels pour les bordures
    add t3, t3, a0              # t3 : Nombre total de pixels pour bordures + obstacles
    slli a0, t3, 2              # Calculer la taille totale en octets (chaque pixel prend 4 octets)

    mv a0, a1                   # Copier la taille en octets dans a0 pour l'appel système
    li a7, 9                    # Numéro de l'appel système pour sbrk (allocation mémoire)
    ecall                       # Appeler pour allouer l'espace mémoire

    bgez a0, alloc_success2     # Si l'allocation réussit, aller à alloc_success2
    li a0, -1                   # Retourner -1 en cas d'échec d'allocation
    ret

alloc_success2:
    la tp, obst_image
    sw a0, 0(tp)                # Stocker l'adresse allouée dans obst_image
    lw ra, 0(sp)                # Restaurer l'adresse de retour
    addi sp, sp, 4              # Restaurer le pointeur de pile
    ret

#-------------------------------# Fonction
# Aucun paramètre requis, retourne les coordonnées d'un pixel aléatoire dans l'arène (x dans a0 et y dans a1)
# Génère un obstacle aléatoire
#-------------------------------#
O_getObst:			
    addi sp, sp, -4             # Ajuster le pointeur de pile
    sw ra, 0(sp)                # Sauvegarder l'adresse de retour
    li t0, 0                    # t0 : Initialisation de x
    li t1, 0                    # t1 : Initialisation de y

    la tp, i_largeur
    lw tp, 0(tp)                # Charger i_largeur pour générer x
    addi tp, tp, -3             # Limiter la génération de x dans les bordures
    mv a1, tp
    li a7, 42                   # Appel système pour générer un nombre aléatoire
    ecall
    addi a0, a0, 2              # Ajuster la valeur de x pour éviter la bordure
    mv t0, a0                   # Stocker x dans t0

    la tp, i_hauteur
    lw tp, 0(tp)                # Charger i_hauteur pour générer y
    addi tp, tp, -3             # Limiter la génération de y dans les bordures
    mv a1, tp
    li a7, 42                   # Appel système pour générer un nombre aléatoire
    ecall
    addi a0, a0, 2              # Ajuster la valeur de y pour éviter la bordure
    mv t1, a0                   # Stocker y dans t1

    mv a0, t0                   # Mettre x dans a0
    mv a1, t1                   # Mettre y dans a1

    lw ra, 0(sp)                # Restaurer l'adresse de retour
    addi sp, sp, 4              # Restaurer le pointeur de pile
    ret

#-------------------------------# Fonction
# Nombre d'obstacles dans a0, retourne void
# Alloue l'image pour les bordures et obstacles, génère les obstacles et les place avec les bordures
#-------------------------------#
O_creer:
    addi sp, sp, -4             # Ajuster le pointeur de pile
    sw ra, 0(sp)                # Sauvegarder l'adresse de retour

    mv t6, a0                   # Stocker le nombre d'obstacles dans t6
    la tp, main_image
    lw t5, 0(tp)                # Stocker l'adresse de l'image principale dans t5

    call O_alloc                # Allouer l'espace pour les bordures et obstacles

    la tp, obst_image
    lw s10, 0(tp)               # Stocker l'adresse de l'image d'obstacles dans s10
    la tp, i_largeur
    lw tp, 0(tp)                # Charger i_largeur
    mv a4, tp                   # a4 : Largeur en unités
    la tp, i_hauteur
    lw tp, 0(tp)                # Charger i_hauteur
    mul a4, a4, tp              # a4 : Nombre total d'unités (largeur * hauteur)

    li a3, 0                    # Initialiser le compteur de pixels
verif:
    bgt a3, a4, place_obst      # Si compteur dépasse le total d'unités, passer à place_obst
    mv a0, t5                   # Charger l'adresse actuelle dans a0
    call I_adresseToCoord       # Obtenir les coordonnées x et y
    call itsBorder              # Vérifier si c'est une bordure
    beqz a0, next_verif         # Si ce n'est pas une bordure, passer à l'adresse suivante
    li tp, 0
    lw tp, 0(t5)                # Charger le pixel de l'adresse courante
    sw tp, 0(s10)               # Stocker le pixel dans l'image d'obstacles
    addi s10, s10, 4            # Passer à l'adresse suivante dans l'image d'obstacles

next_verif:
    addi t5, t5, 4              # Incrémenter l'adresse dans l'image principale
    addi a3, a3, 1              # Incrémenter le compteur de pixels
    j verif                     # Répéter la vérification pour le pixel suivant

place_obst:
    li t5, 0                    # Initialiser le compteur d'obstacles

placing:
    bge t5, t6, end_O_creer     # Si tous les obstacles sont placés, fin
    call O_getObst              # Générer des coordonnées x et y aléatoires
    call I_coordToAdresse       # Obtenir l'adresse correspondante
    li tp, 0
    lw tp, 0(a0)                # Charger le pixel à cette adresse
    sw tp, 0(s10)               # Stocker le pixel dans l'image d'obstacles
    addi s10, s10, 4            # Passer à l'adresse suivante
    addi t5, t5, 1              # Incrémenter le compteur d'obstacles
    j placing                   # Placer le prochain obstacle

end_O_creer:
    lw ra, 0(sp)                # Restaurer l'adresse de retour
    addi sp, sp, 4              # Restaurer le pointeur de pile
    ret
	
	
#-------------------------------# Fonction
# Aucun paramètre requis, retourne void
# Alloue l'espace pour la nourriture
#-------------------------------#
N_creer:	
    li a0, 4                    # Taille d'un pixel en octets (4 octets)
    li a7, 9                    # Numéro de l'appel système pour sbrk (allocation mémoire)
    ecall                       # Appel système pour allouer la mémoire

    bgez a0, alloc_success3     # Si l'allocation réussit, aller à alloc_success3
    li a0, -1                   # En cas d'échec, retourner -1
    ret

alloc_success3:
    la tp, nurriture
    sw a0, 0(tp)                # Stocker l'adresse allouée dans nurriture
    ret

#-------------------------------# Fonction
# Aucun paramètre requis, retourne void
# Place la nourriture dans une position aléatoire qui n'est pas un obstacle
#-------------------------------#
N_placer:
generation:
    addi sp, sp, -4             # Ajuster le pointeur de pile
    sw ra, 0(sp)                # Sauvegarder l'adresse de retour
    call O_getObst              # Générer des coordonnées aléatoires pour la nourriture
    mv s0, a0                   # Stocker x dans s0
    mv s1, a1                   # Stocker y dans s1
    call I_coordToAdresse       # Obtenir l'adresse de ces coordonnées
    lw a2, 0(a0)                # Charger le pixel à cette adresse
    la tp, obst_image
    lw a0, 0(tp)                # Charger l'image d'obstacles dans a0
    la tp, nb_obst_image
    lw a1, 0(tp)                # Charger le nombre d'obstacles dans a1
    call O_contient             # Vérifier si le pixel est un obstacle
    beqz a0, placement          # Si ce n'est pas un obstacle, passer au placement
    j generation                # Sinon, régénérer des coordonnées

placement:
    mv a0, s0                   # Charger x dans a0
    mv a1, s1                   # Charger y dans a1
    call I_coordToAdresse       # Obtenir l'adresse pour les coordonnées x, y
    la tp, nurriture
    sw a0, 0(tp)                # Stocker l'adresse de la nourriture

    mv a0, s0                   # Charger x dans a0
    mv a1, s1                   # Charger y dans a1
    li a2, 0x00FF0000           # Couleur de la nourriture (rouge)
    call I_plot                 # Colorer le pixel de nourriture en rouge
    lw ra, 0(sp)                # Restaurer l'adresse de retour
    addi sp, sp, 4              # Restaurer le pointeur de pile
    ret

#-------------------------------# Fonction
# Aucun paramètre requis, retourne les coordonnées du serpent (x dans a0 et y dans a1)
# Crée le serpent en position (1, 1)
#-------------------------------#
Init_snake:	
    addi sp, sp, -4             # Ajuster le pointeur de pile
    sw ra, 0(sp)                # Sauvegarder l'adresse de retour
    li t5, 1                    # Initialiser x à 1
    li t6, 1                    # Initialiser y à 1
    li a0, 1                    # Charger x dans a0
    li a1, 1                    # Charger y dans a1
    call I_coordToAdresse       # Obtenir l'adresse de (1,1) pour la tête du serpent
    lw a1, 0(a0)                # Charger le pixel à cette adresse
    la tp, fifo_tete
    lw a0, 0(tp)                # Charger l'adresse de la tête du FIFO
    call F_enfiler              # Enfiler la tête du serpent
    lw ra, 0(sp)                # Restaurer l'adresse de retour
    addi sp, sp, 4              # Restaurer le pointeur de pile
    ret

#-------------------------------# Fonction
# x dans a0, y dans a1, retourne 1 dans a0 si le pixel est une bordure, sinon retourne 0
# Détermine si un pixel donné appartient à la bordure
#-------------------------------#
itsBorder:			
    beqz a0, isborder           # Si x == 0, c'est une bordure
    beqz a1, isborder           # Si y == 0, c'est une bordure
    la tp, last_column_index
    lw tp, 0(tp)                # Charger i_largeur - 1
    beq a0, tp, isborder        # Si x == i_largeur - 1, c'est une bordure
    la tp, last_row_index
    lw tp, 0(tp)                # Charger i_hauteur - 1
    beq a1, tp, isborder        # Si y == i_hauteur - 1, c'est une bordure
    li a0, 0                    # Sinon, retourner 0 (pas une bordure)
    j endborder

isborder:
    li a0, 1                    # Retourner 1 si c'est une bordure
endborder:
    ret

	
#-------------------------------#Fonction-----------------------#
# Prend aucun paramètre, retourne l'adresse de l'espace mémoire alloué dans a0
# Cette fonction crée la file pour stocker les pixels du serpent
#-------------------------------#
F_creer:
    # Calculer la taille maximale de la file
    la tp, i_largeur           # Charger l'adresse de la largeur de l'arène dans tp
    lw t0, 0(tp)               # t0 : largeur de l'image en unités
    la tp, i_hauteur
    lw t1, 0(tp)               # t1 : hauteur de l'image en unités
    mul t2, t0, t1             # t2 = largeur * hauteur (nombre maximum de pixels)

    # Allouer l'espace mémoire pour la file
    slli a0, t2, 2             # a0 : taille en octets (nombre de pixels * 4 octets par pixel)
    li a7, 9                   # Appel système sbrk pour allouer la mémoire
    ecall                      # Exécuter l'appel système

    # Vérifier si l'allocation a réussi
    bgez a0, fifo_success      # Si allocation réussie, passer à fifo_success
    li a0, -1                  # Retourner -1 en cas d'échec d'allocation
    ret

fifo_success:
    la tp, fifo_queue
    sw a0, 0(tp)               # Initialiser la queue à l'adresse allouée
    la tp, fifo_tete
    sw a0, 0(tp)               # Initialiser la tête à la même adresse (file vide au départ)
    ret

#-------------------------------#Fonction-----------------------#
# Prend deux arguments : a0 = adresse de la file, a1 = pixel à ajouter
# Ajoute un élément à la tête de la file
#-------------------------------#
F_enfiler:
    la tp, fifo_longeur
    lw t0, 0(tp)               # t0 : longueur actuelle du serpent
    beqz t0, premier_enf       # Si longueur == 0, premier élément

    li t1, 1
    beq t0, t1, deuxiem_enf    # Si longueur == 1, deuxième élément

    # Enfile un élément dans une file non vide
    li t1, 0
    la tp, fifo_queue
    lw t2, 0(tp)               # t2 : adresse actuelle de la queue
    addi t3, t2, 4             # t3 : nouvelle adresse pour la queue
    sw t3, 0(tp)               # Mettre à jour fifo_queue avec la nouvelle adresse de la queue

deplacer_p:
    bge t1, t0, inser_nouv     # Si t1 >= longueur, insérer nouveau pixel

    lw tp, 0(t2)               # Charger l'élément à l'adresse actuelle de la queue
    sw tp, 0(t3)               # Déplacer cet élément à la nouvelle adresse

    addi t2, t2, -4            # Passer à l'élément précédent
    addi t3, t3, -4            # Nouvelle adresse de l'élément précédent
    addi t1, t1, 1             # Incrémenter le compteur
    j deplacer_p

inser_nouv:
    la tp, fifo_tete
    lw t0, 0(tp)               # Charger l'adresse de la tête
    sw a1, 0(t0)               # Placer le nouveau pixel en tête

    la tp, fifo_longeur
    lw t0, 0(tp)               # Charger la longueur actuelle de la file
    addi t0, t0, 1             # Incrémenter la longueur
    sw t0, 0(tp)               # Mettre à jour fifo_longeur
    j enfile_fin

premier_enf:
    addi t0, t0, 1             # Incrémenter la longueur à 1
    sw t0, 0(tp)               # Mettre à jour fifo_longeur

    la tp, fifo_tete
    lw t1, 0(tp)               
    sw a1, 0(t1)               # Placer le pixel en tête

    la tp, fifo_queue
    lw t2, 0(tp)
    sw a1, 0(t2)               # Placer le même pixel en queue
    j enfile_fin

deuxiem_enf:
    addi t0, t0, 1             # Incrémenter la longueur
    sw t0, 0(tp)               # Mettre à jour fifo_longeur

    la tp, fifo_queue
    lw t2, 0(tp)
    addi t2, t2, 4             # Mettre à jour l'adresse de la queue

    la tp, fifo_tete
    lw tp, 0(tp)               
    lw t3, 0(tp)               # Charger le pixel de la tête actuelle
    sw t3, 0(t2)               # Mettre ce pixel à la nouvelle queue
    sw a1, 0(tp)               # Mettre le nouveau pixel en tête

    la tp, fifo_queue
    sw t2, 0(tp)               # Mettre à jour l'adresse de la queue
    j enfile_fin

enfile_fin:
    ret

#-------------------------------#Fonction-----------------------#
# Aucun paramètre nécessaire
# Défiler un élément de la queue de la file, réduisant ainsi sa longueur
#-------------------------------#
F_defiler:
    la tp, fifo_longeur
    lw t0, 0(tp)               # t0 : longueur actuelle du serpent
    beqz t0, file_vide         # Si longueur == 0, retourner erreur

    li t1, 1
    beq t0, t1, seul_elem      # Si longueur == 1, supprimer le seul élément

    la tp, fifo_queue
    lw t2, 0(tp)               # t2 : adresse du dernier élément (queue)
    lw t4, 0(t2)               # t4 : valeur du pixel
    li t3, 0
    sw t3, 0(t2)               # Mettre l'adresse de queue à 0
    sw t3, 0(t4)               # Mettre la valeur du pixel à 0
    addi t2, t2, -4            # Passer à l'adresse précédente
    sw t2, 0(tp)               # Mettre à jour fifo_queue

    addi t0, t0, -1            # Réduire la longueur de la file
    la tp, fifo_longeur
    sw t0, 0(tp)               # Mettre à jour fifo_longeur
    j defile_fin

file_vide:
    li a0, -1                  # Retourner -1 en cas d'erreur (file vide)
    ret

seul_elem:
    la tp, fifo_queue
    lw t2, 0(tp)               # t2 : adresse du dernier (et seul) élément
    lw t3, 0(t2)               # t3 : couleur du pixel
    li tp, 0
    sw tp, 0(t2)               # Mettre l'adresse du dernier élément à 0
    sw tp, 0(t3)               # Mettre la couleur du pixel à 0

    addi t0, t0, -1            # Réduire la longueur de la file à 0
    la tp, fifo_longeur
    sw t0, 0(tp)               # Mettre à jour fifo_longeur
    ret

defile_fin:
    ret

	
#-------------------------------#Fonction
# Prend deux arguments : a0 = adresse de la file, a1 = indice souhaité
# Retourne le pixel correspondant à l'indice a1 dans a0
# Si a1 vaut 0, renvoie le pixel de tête
# Si a1 vaut n - 1, renvoie le pixel de queue
# Si a1 est entre 1 et n - 2, renvoie le pixel à l'indice dans la file
#-------------------------------#
F_valeurIndice:
    la tp, fifo_longeur
    lw t0, 0(tp)               # Charger la longueur actuelle du serpent dans t0
    beqz t0, valInd_err        # Si la longueur est 0, retourner une erreur (0)

    li t2, 1
    beq t2, t0, ret_seul_elem  # Si longueur == 1, retourner le seul élément (tête)

    beqz a1, ret_tete          # Si a1 == 0, retourner la tête

    addi t0, t0, -1
    beq a1, t0, ret_queue      # Si a1 == longueur - 1, retourner la queue

    # Calculer l'adresse du pixel à l'indice a1
    li t2, 4
    mul a1, a1, t2             # Multiplier l'indice par 4 pour obtenir l'adresse
    add a0, a0, a1
    lw a0, 0(a0)               # Charger la valeur du pixel à cette adresse
    ret

ret_tete:
    la tp, fifo_tete
    lw t0, 0(tp)               # Charger l'adresse de la tête
    lw a0, 0(t0)               # Retourner la valeur de la tête
    ret

ret_seul_elem:
    la tp, fifo_tete
    lw t0, 0(tp)               # Charger l'adresse de la tête
    lw a0, 0(t0)               # Retourner la valeur de la tête
    ret

ret_queue:
    la tp, fifo_queue
    lw t0, 0(tp)               # Charger l'adresse de la queue
    lw a0, 0(t0)               # Retourner la valeur de la queue
    ret

valInd_err:
    li a0, 0                   # En cas d'erreur, retourner 0
    ret

#-------------------------------#Fonction
# Prend deux arguments : a0 = adresse de la file, a1 = pixel à rechercher
# Renvoie 1 dans a0 si le pixel appartient à la file, 0 sinon.
#-------------------------------#
F_contient:
    la tp, fifo_longeur
    lw t1, 0(tp)               # Charger la longueur actuelle du serpent dans t1

ver_appartenance:
    blez t1, end_cont          # Si la longueur est <= 0, retourner 0

    lw t2, 0(a0)               # Charger le pixel actuel dans t2
    beq a1, t2, contient       # Si a1 == t2, le pixel est trouvé, retourner 1

    addi a0, a0, 4             # Passer à l'élément suivant dans la file
    addi t1, t1, -1            # Décrémenter le compteur de pixels restants
    j ver_appartenance         # Boucler pour vérifier les pixels suivants

contient:
    li a0, 1                   # Pixel trouvé, retourner 1
    ret

end_cont:
    li a0, 0                   # Pixel non trouvé, retourner 0
    ret

#-------------------------------#Fonction
# Aucun paramètre nécessaire
# Affiche tous les pixels de la file, du plus récent (queue) au plus ancien (tête)
#-------------------------------#
F_lister:
    la t0, fifo_queue          # Charger l'adresse de la queue de la file dans t0
    lw t1, 0(t0)               # Charger l'adresse actuelle de la queue dans t1
    la t2, fifo_longeur        # Charger l'adresse de la longueur de la file dans t2
    lw t3, 0(t2)               # Charger la longueur actuelle de la file (nombre d'éléments) dans t3

    beqz t3, end_lister        # Si la longueur est 0, la file est vide, sortir

print_pixels:
    lw a0, 0(t1)               # Charger le pixel actuel à l'adresse de la queue
    li a7, 34                  # Appel système pour afficher le pixel en hexadécimal
    ecall

    addi t1, t1, -4            # Passer à l'élément suivant dans la file
    addi t3, t3, -1            # Décrémenter le compteur d'éléments
    bnez t3, print_pixels      # Continuer tant qu'il reste des éléments

end_lister:
    ret

#-------------------------------#Fonction
# Prend deux arguments : a0 = adresse de l'image, a1 = nombre de pixels à colorier
# Colorie un nombre spécifique de pixels de l'image avec une couleur prédéfinie
#-------------------------------#
F_afficher:
    mv t0, a0                  # Adresse de l'image
    mv t1, a1                  # Nombre de pixels à colorier
    li t2, 0                   # Compteur de boucle
    li t3, 4                   # Décalage de 4 octets pour passer à l'adresse suivante
    li t4, 0x0027d950          # Couleur utilisée pour les éléments

color2:
    bge t2, t1, end_O_afficher2 # Si le compteur >= nombre de pixels, terminer

    lw tp, 0(t0)               # Charger la valeur à l'adresse actuelle de l'image
    sw t4, 0(tp)               # Appliquer la couleur à l'adresse actuelle
    add t0, t0, t3             # Passer à l'adresse suivante dans l'image
    addi t2, t2, 1             # Incrémenter le compteur
    j color2                   # Répéter jusqu'à la fin

end_O_afficher2:
    ret
