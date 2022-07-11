;Aleksandra Kondratjeva, uzd nr. 13
;Parasykite programa, kuri iveda simboliu eilute ir atspausdina rastu didziuju ASCII raidziu skaiciu.
 
.model small
.stack 100h
.data
    msg1 DB "Iveskite simboliu eilute: $"
	msg2 DB "Rezultatas: "
	ats DB 3 dup(" "), "$"
	buff DB 255, ?, 255 dup(?)
	endl DB 10, 13, "$"
.code
start:
	mov ax, @data
	mov ds, ax
	
	mov ah, 09h
    mov dx, offset msg1
    int 21h
	
	mov ah, 0Ah
	mov dx, offset buff
	int 21h
	
	xor cx, cx
    mov cl, [buff + 1]
    mov si, offset buff + 2      
	
    jcxz baigti        ;jei cx = 0
	
ciklas:	
    mov ah, [si]
	cmp	ah, 'A'
	jb	skip
	cmp	ah, 'Z'
	ja	skip
	
	inc bx             ;jei simbolis didzioji raide
	
skip:
 	inc si 
	loop ciklas

baigti:
    call print_endl
	
	mov si, offset ats + 2     ;ats bus si registre, (+ 2) pasislenku i gala, praleidziu du simbolius
	xor cx, cx
	mov cx, 3                  ;ciklas suksis 3 kartus, nes bx gali buti trizenklis
	
	mov ax, bx
	
	mov bx, 10                 ;bx registre daliklis
	
ciklas2:
	xor dx, dx
	div bx                     ;ax - sveikoji dalis, dx - liekana
	add dx, 30h
	mov ds:[si], dl            ;liekana inesu vietoj trecio tarpo per pirma iteracija
	cmp ax, 0                  
	jz pabaiga
	dec si                    ;pasislenku atgal 
	loop ciklas2

pabaiga:                       ;baigiame programa
    mov ah, 09h
	mov dx, offset msg2
	int 21h
	
    mov ax, 4c00h
    int 21h
	
print_endl:
    mov ah, 09h
    mov dx, offset endl
    int 21h
    ret
	
end start