.data 
	image_width:		.word 256	#Largeur de l'arene du jeu (pixels)
	image_height:		.word 256	#Hauteur de l'arene du jeu (pixels)
	width_of_unit:		.word 8		#Largeur d'un unit (pixels)
	height_of_unit:		.word 8		#Hauteur d'un unit (pixels)
	i_largeur:		.word 0		#Largeur de l'arene du jeu (units)
	i_hauteur:		.word 0		#Hauteur de l'arene du jeu (units)
	main_image:		.word 0		#Adresse de l'arene du jeu
	obst_image:		.word 0		#Adresse de l'image d'obstacles
	last_column_index:	.word 0		#Index du derniere element du ligne
	last_row_index:		.word 0		#Index du derniere element du colonne
	nurriture:		.word 0		#Adresse du pixel representant la nurriture
	nb_obstacle:		.word 20	#Nombre d'obstacles dans l'arene 
	nb_obst_image:		.word 145	#Nombre d'obstacles dans l'arene + les nombre des borders 	
						#(125 dont 124 pixels de border et 4 octets de delimitation)	
	message_fin:		.asciz 		"Le jeu esti fini !\n"							
	message_nouv_nurr:	.asciz 		"Nouveau nurriture genere !\n"
	fifo_tete:           	.word 0         #Adresse de la tete du FIFO
	fifo_queue:          	.word 0         #Adresse de la queue du FIFO
    	fifo_longeur:		.word 0		#Longeur du serpent							
.text


    	
#-------------------------------#Code for testing
	call I_predef
	call I_creer
	la tp nb_obstacle
	lw a0 0(tp)
	call O_creer
	call N_creer
	call F_creer
	
	la tp obst_image
	lw a0 0(tp)
	la tp nb_obst_image
	lw a1 0(tp)
	call O_afficher
	call N_placer
	call Init_snake
	
	
#------------------------------------
loop:		
	
	la tp fifo_tete
	lw a0 0(tp)
	la tp fifo_longeur
	lw a1 0(tp)
	call F_afficher
	
	li t2, 0xffff0000      # t2 : adresse de RCR
   	lw t3, 0(t2)           # Lire l'etat de RCR
    	beq t3, zero, no_input # Si RCR est 0, continuer sans action

    	li t2, 0xffff0004      # t2 : adresse de RDR
    	lw t4, 0(t2)           # Lire la touche pressse
    	li t0, 119             # 'w' pour haut
    	beq t4, t0, move_up
    	li t0, 97             # 'a' pour gauche
    	beq t4, t0, move_left
    	li t0, 115             # 's' pour bas
    	beq t4, t0, move_down
    	li t0, 100             # 'd' pour droite
    	beq t4, t0, move_right
    	li t0, 120             # 'x' pour quitter
    	beq t4, t0, end
no_input:
    	j loop                 # Retourner au d�but de la boucle

move_up:
    	addi t6, t6, -1        # D�placer le serpent vers le haut en diminuant y
    	j verification

move_down:
    	addi t6, t6, 1         # D�placer le serpent vers le bas en augmentant y
    	j verification

move_left:
    	addi t5, t5, -1        # D�placer le serpent vers la gauche en diminuant x
    	j verification

move_right:
    	addi t5, t5, 1         # D�placer le serpent vers la droite en augmentant x
    	j verification
    
verification:
	mv a0 t5
	mv a1 t6
	call I_coordToAdresse
	lw a2 0(a0)
	la tp obst_image
	lw a0 0(tp)
	la tp nb_obst_image
	lw a1 0(tp)
	call O_contient
	li t2 1
	beq t2 a0 end
	
	mv a0 t5
	mv a1 t6
	call I_coordToAdresse
	la tp nurriture
	lw tp 0(tp)
	beq tp a0 nouveau_placement
	
	mv a0 t5
	mv a1 t6
	call I_coordToAdresse
	lw a1 0(a0)
	la tp fifo_tete
	lw a0 0(tp)
	call F_enfiler
	call F_defiler
	j loop
nouveau_placement:
	mv a0 t5
	mv a1 t6
	call I_coordToAdresse
	lw a1 0(a0)
	la tp fifo_tete
	lw a0 0(tp)
	call F_enfiler
	call N_placer
	la a0 message_nouv_nurr
	li a7 4
	ecall
	j loop
end:
	la a0 message_fin
	li a7 4
	ecall
    	li a7 10
    	ecall
    	
#-------------------------------#Fonction-----------------------#
#Fonction qui calcule tous les elements definis dans le data	#
#Aucun element requis, retourne rien				#
#-------------------------------#-------------------------------#
I_predef:			
    	la t0 image_width	#Adresse du largeur de l'arene dans t0 
    	la t1 width_of_unit	#Adresse de la largeur d'un unit dans t1
    	lw t2 0(t0)		#Chargement du largeur d'arene dans t2
    	lw t3 0(t1)		#Chargement du valeur du largeur d'un unit dans t3
    	div a0 t2 t3		#Calculons dans a0 le nombre d'units per ligne
    	la t4 i_largeur		#Adresse de largeur dans t4
    	sw a0 0(t4)		#Chargmenet du largeur dans i_largeur
    	
    	addi a0 a0 -1		#i_largeur - 1 pour avoir l'index du derniere element de la ligne
    	la t0 last_column_index	#Adresse du last_column_index (index du derniere colonne = index du derniere element de la ligne) dans t0
    	sw a0 0(t0)		#Chargement du index dans data
    	
    	la t0 image_height	#Adresse d'hauteur de l'arene dans t0 
    	la t1 height_of_unit	#Adresse d'hauteur d'un unit dans t1
    	lw t2 0(t0)		#Chargement d'hauteur d'arene dans t2
    	lw t3 0(t1)		#Chargement du valeur d'hauteur d'un unit dans t3
    	div a0 t2 t3		#Calculons dans a0 le nombre d'units per colonne
    	la t4 i_hauteur		#Adresse d'hauteur dans t4
    	sw a0 0(t4)		#Chargmenet du largeur dans i_hauteur
    				
    	addi a0 a0 -1		#i_hauteur - 1 pour avoir l'index du derniere element de la ligne
    	la t0 last_row_index	#Adresse du last_row_index dans t0
    	sw a0 0(t0)		#Chargement du index dans data
    	ret			#Retour de la fonction
				
#-------------------------------#Fonction--		
#No parameter needed, return the adress of allocated space in a0 (also stores it in main_image)
#Creating the image for the game starting on the 0x10008000 adress
I_creer:			
    	la tp i_largeur
    	lw t1 0(tp)		#Load i_largeur in t1
    	la tp i_hauteur             
    	lw t2 0(tp)		#Load i_hauteur in t2

    	mul t3 t1 t2   		#t3 = i_largeur * i_hauteur (total pixels)
    	mul a3 t1 t2		#a3 = t3 (for while loop to insert values in image)
    	li a1 4                 #Each pixel address takes 4 bytes
    	mul a1 a1 t3          	#Total bytes needed = total pixels * 4

    	mv a0 a1                #Move total bytes to allocate into a0
    	li a7 9                 #Syscall number for sbrk
    	ecall                   #Allocate space

    	bgez a0 alloc_success   #If allocation succeeded, branch
    	li a0 -1                #Return -1 if allocation failed
    	ret
alloc_success:
	la tp main_image
    	sw a0 0(tp)		#Store in s6 the adress of the image
load_values:
	mv t0 a0		#t0 = adress of the first unit in image
	li t1 0x10008000	#t1 = adress of the first unit in bitmap
	li t2 0			#t2 = number of starting element
	mv t3 a3		#t3 = total nubmer of units
	li t4 4			#t4 = number of bytes to add each step
loading:bge t2 t3 next_step	#if t2 < t3 then loop else next step
	sw t1 0(t0)
	addi t2 t2 1
	add t1 t1 t4
	add t0 t0 t4
	j loading
next_step:
	ret
	
#-------------------------------#Next function			
#x in a0, y in a1 as parameters, retuns the adress of the pixel (x, y) in a0
#Converts the coords in adress
I_coordToAdresse:			
	addi sp sp -4 		#Adjust stack pointer 
	sw ra 0(sp) 		#Save return address
	li t3 4	
    	la t1 i_largeur
    	lw t1 0(t1)		#Storing in t1 i_largeur

   	mul t2 a1 t1         	#t2 = y * largeur_pixels 
   	add t2 t2 a0          	#t2 = (y * largeur_pixels) + x
   	mul t2 t2 t3         	#t2 * 4, 4 bytes per integer
   	
    	la t0 main_image
    	lw t0 0(t0)		#t0 = adress of the first unit in image
    	add a0 t0 t2         	#a0 = adress of the pixel
    	lw ra 0(sp) 		#Restore return address 
    	addi sp sp 4 		#Restore stack pointer
    	ret  
   
#-------------------------------#Next function	
#Adress in a0, return x in a0 and y in a1
#Converts the adresse in coords
I_adresseToCoord:		#Returns adress of the pixel in a0
	addi sp sp -4 		#Adjust stack pointer 
	sw ra 0(sp) 		#Save return address
	la t0 main_image
    	lw t0 0(t0)		#t0 = adress of the first unit in image
    	sub a0 a0 t0   		#Substract the starting adress of the image to obtain the number of bytes we need to get the adress from the image 
    	
    	li t3 4			#4 bytes per pixel
    	divu t2 a0 t3		#Divide by 4 to get pixel index
    	
    	la t1 i_largeur
    	lw t1 0(t1)		#Storing in t1 i_largeur
    	divu t4 t2 t1		#y = pixel index / i_largeur
    	remu a0 t2 t1		#x = pixel index % i_largeur

    	mv a1 t4               	#y in a1, x already in a0
    	lw ra 0(sp) 		#Restore return address 
    	addi sp sp 4 		#Restore stack pointer
    	ret

#-------------------------------#Next function	
#x in a0, y in a1, color in a2, returns void
#Coloring a pixel by coords and color
I_plot:				#Coloring the pixel on (a0, a1) coordinates in a2 color
	addi sp sp -4 		#Adjust stack pointer 
	sw ra 0(sp) 		#Save return address
	call I_coordToAdresse
	
	lw a0 0(a0)		#Store in a0 the adress of the unit
	sw a2 0(a0)		#Loading in the adress of a0 the color stored in a2
	lw ra 0(sp) 		#Restore return address 
    	addi sp sp 4 		#Restore stack pointer
	ret
	
#-------------------------------#Next function	
#Adress of image in a0, number of pixels to color in a1, returns void
#Coloring a specific number of pixels from an image
O_afficher:			#Coloring first a0's pixels in light blue
	mv t0 a0		#adress of the image
	mv t1 a1		#the number of elements
	li t2 0			#loop counter
	li t3 4			#4 bytes to jump on next adress
	li t4 0x003665FF	#the color for the elements
color:	bge t2 t1 end_O_afficher#if counter >= number of elements then end
	lw tp 0(t0)
	sw t4 0(tp)		#*t0 = t4
	add t0 t0 t3		#move to the next adress
	addi t2 t2 1
	j color
end_O_afficher:
	ret
	
#-------------------------------#Next function	
#Adress of image in a0, number of pixels in a1, pixel to find in a2, returns 1 in a0 in pixel found else 0
#Finding if a pixel belongs to an image
O_contient:			#Returns 1 in a0 if the element found, else 0 in a0
	mv t0 a0		#image adress
	mv t1 a1		#number of elements
	mv t2 a2		#element to find
	li t3 4			#4 bytes
	li t4 0			#counter = 0
app:	bge t4 t1 end_O_contient_0	#if counter >= number of elements then exit 0
	lw tp 0(t0)
	beq tp t2 end_O_contient_1	#if tp == t2 then exit 1
	addi t4 t4 1			#counter += 1
	add t0 t0 t3			#adress += 4 bytes
	j app				#repet verification
end_O_contient_1:
	li a0 1			#exit 1
	ret
end_O_contient_0:
	li a0 0			#exit 0
	ret
	
#-------------------------------#Next function	
#Number of obstacles in a0, return the adress of allocated space in a0 (also stores it in obst_image)
#Allocates the image for borders and obstacles
O_alloc:
	addi sp sp -4 	#Adjust stack pointer 
	sw ra 0(sp) 		#Save return address
	
    	li t0 0           	#Initialize width counter
    	li t1 0           	#Initialize height counter
    	li t2 2           	#Border size multiplier
	la tp i_largeur
	lw tp 0(tp)		#tp = i_largeur
    	add t0 tp tp     	#t0 = 2 * i_largeur (total width border units)
    	la tp i_hauteur
    	lw tp 0(tp)		#tp = i_hauteur
    	add t1 tp tp     	#t1 = 2 * i_hauteur (total height border units)
    	
    	add t3 t0 t1     	#t3 = 2 * (width + height) (total border units)
    	add t3 t3 a0     	#t3 = total border + isolated obstacles
    	slli a0 t3 2     	#Calculate total memory in bytes

    	mv a0 a1          	#Move byte count to a0 for syscall
    	li a7 9           	#Syscall number for sbrk
    	ecall              	#Allocate space

    	bgez a0 alloc_success2
    	li a0 -1          	#Return -1 if allocation failed
    	ret

alloc_success2:
	la tp obst_image
	sw a0 0(tp)		#Store allocated space in obst_image
    	lw ra 0(sp) 		#Restore return address 
    	addi sp sp 4 		#Restore stack pointer
	ret	

#-------------------------------#Next function	
#No parameters needed, returns the coords of a random generated pixel in the arena (x in a0 and y in a1)
#Generates a random obstacle
O_getObst:			
	addi sp sp -4 		#Adjust stack pointer 
	sw ra 0(sp) 		#Save return address
	li t0 0			#To save the x
	li t1 0			#To save the y
	
	la tp i_largeur
	lw tp 0(tp)		#Generating a random coordinate for x
	addi tp tp -3
	mv a1 tp
	li a7 42		#System call to random int generator
	ecall
	addi a0 a0 2
	mv t0 a0		#Store x in a0
	
	la tp i_hauteur
	lw tp 0(tp)		#Generating a random coordinate for y
	addi tp tp -3
	mv a1 tp
	li a7 42		#System call to random int generator
	ecall
	addi a0 a0 2
	mv t1 a0		#Store y in a0
	
	mv a0 t0		#x in a0
	mv a1 t1		#y in a1
	
	lw ra 0(sp) 		#Restore return address 
    	addi sp sp 4 		#Restore stack pointer
	ret	

#-------------------------------#Next function	
#Number of obstacles in a0, returns void
#Allocates the image for borders and obstacles, generates the obstacles and places them with the borders in the allocated space
O_creer:
	addi sp sp -4 		#Adjust stack pointer 
	sw ra 0(sp) 		#Save return address
	
	mv t6 a0 		#Stock the number of obstacles in t6
	la tp main_image
	lw t5 0(tp) 		#Stock the main image adress
	
	call O_alloc		#Alloc the space for borders and obstacles
	
	la tp obst_image
	lw s10 0(tp)		#Stock the obst image adress
	la tp i_largeur
	lw tp 0(tp)		#tp = i_largeur
	mv a4 tp 		#a4 = i_largeur
	la tp i_hauteur
	lw tp 0(tp)		#tp = i_hauteur
	mul a4 a4 tp		#Stock the number of units
	
	li a3 0			#Counter
verif:	bgt a3 a4 place_obst	#Verify each element if it is a border
	mv a0 t5		#Move the main adress in t0
	call I_adresseToCoord	#Get x and y
	call itsBorder		#Verify is its border
	beqz a0 next_verif	#If not border, then next_verif
	li tp 0			
	lw tp 0(t5)		#Get the pixel from the adress
	sw tp 0(s10)		#Store the pixel in the image of obstacles
	addi s10 s10 4		#Move to the next position in the image of obstacles
next_verif:
	addi t5 t5 4		#Next adress in the main image
	addi a3 a3 1		#Counte += 1
	j verif
place_obst:
	li t5 0			#Counter for loop	
placing:bge t5 t6 end_O_creer	#Placing obstacles on the field
	call O_getObst		#Generating a random x and y
	call I_coordToAdresse	#Get the adress
	li tp 0
	lw tp 0(a0)		#Load the pixel from the adress
	sw tp 0(s10)		#Store the pixel in the image of obstacles
	addi s10 s10 4		#Move to the next adress
	addi t5 t5 1		#Counter += 1
	j placing
end_O_creer:
	lw ra 0(sp) 		#Restore return address 
    	addi sp sp 4 		#Restore stack pointer
	ret	
	
#-------------------------------#Next function	
#No parameter needed, return void 
#Allocate the space for the food 
N_creer:	
	li a0 4
	li a7 9
	ecall
	
	bgez a0 alloc_success3  #If allocation succeeded, branch
    	li a0 -1                #Return -1 if allocation failed
    	ret
    	
alloc_success3:
	la tp nurriture
	sw a0 0(tp)
	ret

#-------------------------------#Next function	
#
#
N_placer:
generation:
	addi sp sp -4 		#Adjust stack pointer 
	sw ra 0(sp) 		#Save return address
	call O_getObst
	mv s0 a0
	mv s1 a1
	call I_coordToAdresse
	lw a2 0(a0)
	la tp obst_image
	lw a0 0(tp)
	la tp nb_obst_image
	lw a1 0(tp)
	call O_contient
	beqz a0 placement
	j generation
placement:
	mv a0 s0
	mv a1 s1
	call I_coordToAdresse
	la tp nurriture
	sw a0 0(tp)
	
	mv a0 s0
	mv a1 s1
	li a2 0x00FF0000
	call I_plot
	lw ra 0(sp) 		#Restore return address 
    	addi sp sp 4 		#Restore stack pointer
	ret
	
#-------------------------------#Next function	
#No parameter needed, return the coords of the snake, x in a0 and y  in a1
#Creates the snake at (1, 1)
Init_snake:	
	addi sp sp -4 		#Adjust stack pointer 
	sw ra 0(sp) 		#Save return address
	li t5 1
	li t6 1
	li a0 1
	li a1 1
	call I_coordToAdresse
	lw a1 0(a0)
	la tp fifo_tete
	lw a0 0(tp)
	call F_enfiler
	lw ra 0(sp) 		#Restore return address 
    	addi sp sp 4 		#Restore stack pointer
	ret
	
	
#-------------------------------#Next function	
#x in a0, y in a1, returns 1 in a0 if the pixel is a border, else 0
#Determines if the pixel is border 
itsBorder:			#Takes x in a0 and y in a1 and return 1 if its a border otherwise 0
	beqz a0 isborder	#If x == 0 its border
	beqz a1 isborder	#If y == 0 its border
	la tp last_column_index
	lw tp 0(tp)		#tp = i_largeur - 1
	beq a0 tp isborder	#If x == i_largeur - 1 its border
	la tp last_row_index
	lw tp 0(tp)		#tp = i_hauteru - 1
	beq a1 tp isborder	#If y == i_hauter - 1 its border
	li a0 0			#Load 0 in a0 and exit
	j endborder
isborder:
	li a0 1			#Load 1 in a1 and exit
endborder:
	ret
	
#-------------------------------#Next function	
# Pas de param�tres n�cessaires, retourne l'adresse de l'espace m�moire allou� dans a0
# Cette fonction cr�e la file pour stocker les pixels du serpent
F_creer:
    	# Calculer la taille maximale de la file
    	la tp i_largeur
    	lw t0 0(tp)             # Largeur de l'image
    	la tp i_hauteur
    	lw t1 0(tp)             # Hauteur de l'image
    	mul t2 t0 t1            # t4 = largeur * hauteur (nombre maximum de pixels)
	
    	# Allouer l'espace m�moire
    	slli a0 t2 2            # Multiplier par 4 pour la taille en octets
    	li a7 9                 # Syscall sbrk pour allouer
    	ecall

    	# V�rifier si l'allocation a r�ussi
    	bgez a0 fifo_success
    	li a0, -1               # Retourner -1 si �chec d'allocation
    	ret
fifo_success:
    	la tp fifo_queue
    	sw a0 0(tp)             # Initialiser la queue � l'adresse de d�part
    	la tp fifo_tete         # Charger l'adresse de fifo_tete
    	sw a0 0(tp)             # Initialiser la t�te � l'adresse de d�part
	ret
	
#-------------------------------#Fonction
# Adresse de la file dans a0, nouveau pixel � ajouter dans a1
# Ajoute un �l�ment � la t�te de la file
F_enfiler:
	la tp fifo_longeur
	lw t0 0(tp)		#t0 = longeur du serpent
	beqz t0 premier_enf	#Si la longeur du serpent == 0
	
	li t1 1
	beq t0 t1 deuxiem_enf	#Si la longeur du serpent == 1
	
	li t1 0
	la tp fifo_queue
	lw t2 0(tp)		#Ancienne queue
	addi t3 t2 4		#Nouvelle queue
	sw t3 0(tp)		#Charger la nouvelle queue en fifo_queue
deplacer_p:
	bge t1 t0 inser_nouv
	
	lw tp 0(t2)		#Element du ancienne adresse
	sw tp 0(t3)		#Chargement d'element a la nouvelle adresse
	
	addi t2 t2 -4		#On passe a l'element suivant
	addi t3 t3 -4		#On passe a l'element suivant
	addi t1 t1 1		#Counter += 1
	j deplacer_p
inser_nouv:	
	la tp fifo_tete
	lw t0 0(tp)		#Chargement d'adresse du tete
	sw a1 0(t0)		#Chargement du nouveau element en tete
	
	la tp fifo_longeur
	lw t0 0(tp)		#Longeur du serpent
	addi t0 t0 1		#Augmenter la longeur
 	sw t0 0(tp)		#Charger dans fifo_longeur
 	j enfile_fin
    
premier_enf:
 	addi t0 t0 1		#Augmenter la longeur
 	sw t0 0(tp)		#Charger dans fifo_longeur
 	
 	la tp fifo_tete
 	lw t1 0(tp)		
 	sw a1 0(t1)		#Mettre le pixel en tete
 	
 	la tp fifo_queue
 	lw t2 0(tp)
 	sw a1 0(t2)		#Mettre le meme pixel en queue
 	j enfile_fin
 	
 deuxiem_enf:
 	addi t0 t0 1		#Augmenter la longeur
 	sw t0 0(tp)		#Charger dans fifo_longeur
 	
 	la tp fifo_queue
 	lw t2 0(tp)
 	addi t2 t2 4		#Augmenter l'adresse du queue
 	
 	la tp fifo_tete
 	lw tp 0(tp)		
 	lw t3 0(tp)
 	sw t3 0(t2)
 	sw a1 0(tp)		#Mettre le nouveau pixel en queue
 	
 	la tp fifo_queue
 	sw t2 0(tp)
 	j enfile_fin
 
 enfile_fin:  
    	ret
    	
#-------------------------------#Fonction

F_defiler:
    	la tp fifo_longeur            
	lw t0 0(tp)		#t0 = longeur de serpent
    	beqz t0 file_vide      	#Si long_serpent == 0 alors erreur
    	
	li t1 1			
	beq t0 t1 seul_elem	#Si long_serpent == 1 alors file vide

	la tp fifo_queue
	lw t2 0(tp)		#t2 = adresse du dernier element
	lw t4 0(t2)		#t4 = valeur du pixel
	li t3 0			#t3 = 0
	sw t3 0(t2)		#*t2 = 0
	sw t3 0(t4)		#*t4 = 0
	addi t2 t2 -4		#t2 = adresse d'avant dernier element
	sw t2 0(tp)		#Charge t2 dans fifo_queue
	
	addi t0 t0 -1		#long_serpent - 1
	la tp fifo_longeur	
	sw t0 0(tp)		#Sauvegarder la longeur
	j defile_fin
file_vide:
    	li a0, -1                #Return a0 = -1
    	ret
seul_elem:
	la tp fifo_queue
	lw t2 0(tp)		#t2 = adresse du dernier (et le seult) element
	lw t3 0(t2)		#t3 = couleur du pixel
	li tp 0			#tp = 0
	sw tp 0(t2)		#*t2 = tp
	sw tp 0(t3)
	
	addi t0 t0 -1		#long_serpent - 1
	la tp fifo_longeur
	sw t0 0(tp)		#Sauvegarder la longeur
	ret
defile_fin:
	ret
	
#-------------------------------#Fonction
# Prend deux arguments : a0 = adresse de la file, a1 = indice souhait�
# Retourne le pixel correspondant � l'indice a1 dans a0
# Si a1 vaut 0, renvoie le pixel de t�te
# Si a1 vaut n - 1, renvoie le pixel de queue
# Si a1 est entre 1 et n - 2, renvoie le pixel � l'indice dans la file
F_valeurIndice:
   	la tp fifo_longeur
    	lw t0 0(tp)		#long_serpent
    	beqz t0 valInd_err	#Si long_serpent == 0 alors renvoie 0
    	
    	li t2 1
    	beq t2 t0 ret_seul_elem	#Si ling_serpent == 1 alors renvoie le seul element
    	
    	beqz a1 ret_tete	#Si a1 == 0 alors renvoi la tete
    	
    	addi t0 t0 -1
    	beq a1 t0 ret_queue	#Si a1 == long_serpent - 1 alors renvoie la queue
    	
    	li t2 4
    	mul a1 a1 t2		#Elements a parcourir * nombre des bytes = adresse d'element souhaite
    	add a0 a0 a1
    	lw a0 0(a0)
    	ret
    	
ret_tete:
	la tp fifo_tete
	lw t0 0(tp)		#t0 = element de la tete
	lw a0 0(t0)		#Retourne la tete
	ret
ret_seul_elem:
	la tp fifo_tete
	lw t0 0(tp)		#t0 = element de la tete
	lw a0 0(t0)		#Retourne la tete
	ret
ret_queue:
	la tp fifo_queue	
	lw t0 0(tp)		#t0 = element de la queue
	lw a0 0(t0)		#Retourne la queue
	ret
valInd_err:
	li a0 0			#Retourne 0
	ret
	
#-------------------------------#Fonction
#
#
F_contient:
    	la tp fifo_longeur
    	lw t1 0(tp)		#t1 = longeur du serpent
ver_appartenance:    	
	blez t1 end_cont	#if t1 <= 0 alors retourne 0
	
    	lw t2 0(a0)		#t2 = *a0
    	beq a1 t2 contient	#if a1 == t2 alors retourne 1
    	
    	addi a0 a0 4		#Passons au element suivant
    	addi t1 t1 -1		#Nombre d'elements restans - 1
    	j ver_appartenance
    
contient:
	li a0 1			#Retourne 1
	ret
end_cont:
	li a0 0			#Retourne 0
	ret
	
#-------------------------------#Fonction
#
#
F_lister:
    la t0, fifo_queue          # Charger l'adresse de fifo_queue
    lw t1, 0(t0)               # Charger l'adresse actuelle de la queue
    la t2, fifo_longeur        # Charger l'adresse de fifo_longeur
    lw t3, 0(t2)               # Charger la longueur actuelle de la file (nombre d'éléments)

    beqz t3, end_lister        # Si la longueur est 0, la file est vide, sortir

print_pixels:
    lw a0, 0(t1)               # Charger le pixel actuel à l'adresse de la queue
    li a7, 34                   # Appel système pour afficher le pixel en hexad
    ecall

    addi t1, t1, -4             # Passer à l'élément suivant dans la file
    addi t3, t3, -1            # Décrémenter le compteur d'éléments
    bnez t3, print_pixels      # Continuer tant qu'il reste des éléments

end_lister:
    ret
    
#-------------------------------#Next function	
#Adress of image in a0, number of pixels to color in a1, returns void
#Coloring a specific number of pixels from an image
F_afficher:			#Coloring first a0's pixels in light blue
	mv t0 a0		#adress of the image
	mv t1 a1		#the number of elements
	li t2 0			#loop counter
	li t3 4			#4 bytes to jump on next adress
	li t4 0x0027d950	#the color for the elements
color2:	bge t2 t1 end_O_afficher2#if counter >= number of elements then end
	lw tp 0(t0)
	sw t4 0(tp)		#*t0 = t4
	add t0 t0 t3		#move to the next adress
	addi t2 t2 1
	j color2
end_O_afficher2:
	ret
