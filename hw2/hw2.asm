;Aleksandra Kondratjeva
;Programa, palyginanti du failus. Programa lygina failus ir i stdout isveda nesutampancius simbolius bei ju pozicijas nuo failo pradzios
;Programa ignoruoja atveji, jei bent vienas is nesutampanciu simboliu yra new line'as
.model small
buferio_dydis EQU 512
.stack 100h
.data      
    buff db buferio_dydis dup (?)    
    buff2 db buferio_dydis dup (?)
 
    duom_vardas db 200 dup (0)
    duom2_vardas db 200 dup (0)
	print db	7 dup (" "), "$"
 
    length1 dw ?
    length2 dw ?
 
	d1Fail dw ?      ;vieta skirta saugoti duom failo deskriptoriaus nr 
    d2Fail dw ?
 
    pagalbosPranesimas db "Programa, lygina du failus. Isveda nesutampancius simbolius bei ju pozicijas.$", 10, 13                                   
    klaidosPranesimas db "Klaida skaitant! Pabandykite dar  karta.$", 10, 13
	klaidaAtidaryti db "Klaida atidarant! Pabandykite dar karta.$"
	klaida_tuscias db "Vienas is failu yra tuscias!"
	newl   db ";", "$"
 
.code  
pradzia:   
    mov ax, @data
	mov ds, ax
 
	xor cx, cx     ;cx bus mano pointeris i komandines eilutes blokus
	mov bx, 82h    ;81h reiksme yra space, 82h pirmas parametru eilutes simbolis
	
	mov si, offset duom_vardas    
	mov di, offset duom2_vardas  
 
	cmp byte ptr es:[80h], 0 ;jeigu vartotojas nieko neivede
	je pagalba
 
	cmp es:[82h], '?/' ;jei vartotojas paprase pagalbos (rasau ?/) 
	jne ciklas
 
	cmp byte ptr es:[84h], 13 ;bei paspaude enteri
	je pagalba
 
;*********************************************
;
;SKATOME PARAMETRU EILUTE
;
;*********************************************
ciklas:    
    cmp byte ptr es:[bx], 20h	;space? keliaujame i failu atidaryma
    je atidaryti  
 
    cmp byte ptr es:[bx], 13	;newline (paskutinis failas???)
    je atidaryti
 
    cmp cx, 1				;jei jau uzpildem pirmo failo varda
    je uzpildytAntra        ;pildom antra
 
    cmp cx, 2
	je antrasEtapas
	
    mov dl, byte ptr es:[bx]
    mov [si], dl ;i si registra ikeliame ka turime komandineje eiluteje (duom_vardas)
 
	inc si
    inc bx 
 
    jmp ciklas
 
atidaryti:	
    cmp cx, 0 ;jei cx 0 reiskia pirmas failas dar nebuvo atidarytas
    je atidaryti1
 
    cmp cx, 1 ;jei cx 1 reiskia pirmas failas buvo atidarytas, reikia atidaryti antra
    je atidaryti2
 
atidaryti1: 
    mov ah, 3Dh
    mov al, 00                   ;00 - atidarau tik skaitymui 
    mov dx, offset duom_vardas 
    int 21h  
 
    jc klaida_atidaryti
    mov d1Fail, ax 				;ax diskriptorius.
 
    inc cx            ;increasinu cx, kad perkelciau pointeri (reiskia jau pirma faila atidariau) 
    ;inc si            ;
    inc bx            ;paslenku komandinej eilutej per viena baita
 
    jmp ciklas 
 
pagalba:
    mov ah, 09h
    mov dx, offset pagalbosPranesimas  
    int 21h
	jmp exit
 
uzpildytAntra:      
    mov dl, byte ptr es:[bx]
    mov [di], dl 
 
    inc di ;di registre duom2_vardas
    inc bx ;pasislenkam komandinej eiluteje 
 
    jmp ciklas ;------> cmp cx, 1 -----> pildys antra kol nesutiks newline'o
 
atidaryti2:
    mov ah, 3Dh
    mov al, 00 ;atidarau tik skaitymui
    mov dx, offset duom2_vardas ;
    int 21h  
 
    jc klaida_atidaryti
    mov d2Fail, ax 
 
    inc di
    inc bx
    inc cx ;cx ---- > 2, reiskia duomenu failai atidaryti
 
    jmp ciklas
 
klaida_atidaryti: ;jei nusoko cia -----> failas neatidarytas
    mov ah, 09h
    mov dx, offset klaidaAtidaryti           
    int 21h
 
pabaiga:  ;todel baigiame programa
    mov ax, 4C00h
    mov al, 0
    int 21h  
 
;*********************************************
;
;PRASIDEDA SKAITYMAS IS FAILU, NESUTAMPANCIU SIMBOLIU NUSTATYMAS
;
;*********************************************
antrasEtapas:
 
	mov bx, d1Fail ;failo deskr.
	lea dx, buff
 
    call skaityti
	mov length1, ax ;ikeliame i kintamaji kiek nuskaitem
 
	mov bx, d2Fail
	lea dx, buff2
 
    call skaityti
	mov length2, ax ;ikeliame i kintamaji kiek nuskaitem
 
    jmp nustatymas 
 
proc skaityti
    mov ah, 3Fh                 			;i bx isirasau deskriptoriaus pozicija
    mov cx, buferio_dydis             		;i dx isirasau skaitomo simbolio reiksme
    int 21h
 
    jc nepavykoNuskaityti           		;isirasau kiek elementu i mano buferi irasyta
 
    ret
    endp skaityti
 
nepavykoNuskaityti:
	jmp klaida ;klaidos pranesimas
	
 
nustatymas:        ;nustatau kuriame faile buvo irasyta daugiau elementu
    mov ax, length1
    mov cx, length2
	
	cmp ax, 0
	je klaidaTuscias
	cmp cx, 0
	je klaidaTuscias
	
    cmp cx, ax								;jei cx maziau uz ax
    jb skip
    mov cx, ax ; resikia trumpiausias ax
 
skip:
	xor di, di ;nunuliname, naudosyme kaip rodykle pozicijai nustatyti
 
skaiciavimas: 
    mov si, 2 ;kad galetume pradeti rasyt skaiciu is antros pozicijos 
	call tikrinimas

kitas:
    inc di
 
    loop skaiciavimas 
 
    ;jmp uzdaryti
 
proc tikrinimas            		;tikriname ar simboliai nelygus
    mov bl, byte ptr [offset buff  + di]  								
    mov bh, byte ptr [offset buff2 + di] 		
    cmp bh, bl ;jeigu simboliaii nelygus vaziuojame spausdinti
	jne SPAUSDINIMAS
 
	ret
	endp tikrinimas
	
SPAUSDINIMAS:
	push bx						;bx issaugotos simboliu reisksmes
	push cx                     ;cx eilutes ilgis
  
    mov cx, 3                  ;ciklas suksis 3 kartus, nes bx gali buti trizenklis
	mov ax, di
    mov bx, 10 ;bx registre daliklis
	
	konvertavimas:
    xor dx, dx
    div bx                     ;ax - sveikoji dalis, dx - liekana ax/10
    add dx, 30h ; example: 253 / 10 ----> 3  25 / 10 ----> 5 
    mov ds:[print + si], dl            ;liekana inesu vietoj trecio tarpo per pirma iteracija
    cmp ax, 0    ;jei sveikoji dalis 0, vaziuojame spausdinti simbolius
    jz spausdink_simb 
    dec si                    ;pasislenku atgal 
    loop konvertavimas
	
spausdink_simb:
	pop cx
	pop bx
	
	cmp bl, 13					;tikriname ar newline's bet kuris is nesutampanciu simboliu
	je kitas
	cmp bl, 10
	je kitas
	cmp bh, 13
	je kitas
	cmp bh, 10
	je kitas
	
	mov [print + 4], bl
	mov [print + 6], bh 
	mov ah, 09h
	mov dx, offset print
	int 21h
	cmp cx, 1
	je uzdaryti
	
    push dx
	mov dx, offset newl ;skirtukas
    mov ah, 09h
    int 21h
	pop dx
	ret
klaidaTuscias:
    mov ah, 09h
	mov dx, offset klaida_tuscias
	int 21h
	jmp exit
klaida:
    mov ah, 09h
    mov dx, offset klaidosPranesimas
    int 21h

;*********************************************
;
;UZDARAU FAILUS IR ISEINU IS PROGRAMOS
;
;*********************************************
uzdaryti: 
    mov ah, 3Eh
    mov bx, d1Fail
    int 21h
    jc klaida
 
    mov ah, 3Eh
    mov bx, d2Fail
    int 21h
    jc klaida
exit:
	mov ah, 4Ch
	mov al, 0
	int 21h
 
END pradzia