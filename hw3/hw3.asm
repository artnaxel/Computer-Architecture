.model small
dydis EQU 512
.stack 100h

.data
	file_n db 13 dup(?) ;input failo vardas
	output_n db 13 dup(?) ;output failo vardas
	newline db 0Dh, 0Ah, 24h
	
	;failu deskriptoriai
	in_handle dw 0
	out_handle dw 1
	
	ip_val dw 0
	eof db 0
	
	;skaitymo buferis
	READ_LENGTH dw dydis
	in_buff db dydis dup (?)
	in_buff_end dw 0
	in_buff_length dw dydis
	
	;rasymo buferis
	PRINT_LENGTH dw dydis
	out_buff db dydis dup (?)
	out_buff_i dw 0
	instr_buff db 50 dup (?)
    instr_length db 0
	instr_pointer dw ?

    d_val db 0
    w_val db 0
  
    mod_val db 0
	reg_val db 0
    rm_val db 0
	
    port_val db 0
    sreg_val db 0
    offset_val dw 0
    force_hex db 0
	skip_h db 0
	
	special_symbols db " ,[]:+"
    hex_abc db "0123456789ABCDEF"
    registers db "alcldlblahchdhbhaxcxdxbxspbpsidi"
	rm_0_registers db "bx+sibx+dibp+sibp+di"
    rm_4_registers db "sidibpbx"
	segments db "escsssds"
	
	is_prefix db 0
	
	com_mov db "mov"
	com_out db  "out"
	com_not db "not"
	com_rcr db "rcr"
	com_xlat db "xlat"
	unk db "UNKNOWN"
	end_msg db "end" 
	
	;ERROR MESSAGES
    msg1 db "Can't open input file.$"
    msg2 db "Can't create output file.$"
    msg3 db "Can't close input file.$"
	msg4 db "Can't close output file$"
    msg5 db "Error reading file.$"
    help_msg db "Programa, kuri vercia masinini koda i assembly.$"
.code
start:
    mov ax, @data
	mov ds, ax
	
	mov si, 0081h ;komandines eilutes pradzia
	mov bx, 0
	mov cx, -1
	
parametrai:;ARG_PARSE
    mov al, byte ptr es:[si] ;komandines eilutes parametrai bus issaugoti al
	
	cmp al, 13 ;tikriname ar newline
	je check_errors ;patiktinsime ar visi parametrai suvesti
	
	cmp al, ' ' ;parametro pabaiga, praleidziame tarpa
	je skip_space
	
	cmp al, '/' ;tikriname ar vartotojas bando ivesti /?
	je err_test
	
	inc si ;issaugojame simboli
	jmp write
err_test:
    inc si
	mov al, byte ptr es:[si] ;tikriname ar sekantis baitas yra ?
	cmp al,'?'
	jne write_init ;jei ne pratesiame darba
err_:
    mov dx, offset help_msg ;help message
	mov ah, 09h ;09 ?
	int 21h
	
	mov ax, 4C00H
	int 21h

write_init: ;pataisome po err_test
    dec si
	mov al, byte ptr es:[si]
	inc si
jmp write

skip_space:
    inc si
	mov al, byte ptr es:[si] ;skip all spaces
	cmp al,' '
	je skip_space
	inc cx ;kelinta parametra reikia skaityti
	mov bx, 0 ;indeksas naujo parametro
jmp parametrai

check_errors:
    cmp cx, 1
	je continue
	
	cmp cx, 2
	je continue
	
	cmp cx, 0
	je continue
jmp err_

write:
    cmp cx, 0
	je pirmas_parametras
	
	cmp cx, 1
	je antras_parametras
jmp err_

pirmas_parametras:
    mov [file_n + bx], al ;pirmas parametras
    inc bx
jmp parametrai	

antras_parametras:
    mov [output_n + bx], al ;antras parametras
	inc bx
jmp parametrai

continue:
	
	mov dx, offset file_n ;atidaryti input faila
	mov ax, 3D00h
	int 21h
	jc open_if_error ;tikriname ar sekmingai atidarytas input failas
	mov in_handle, ax
	jmp create_of
	
open_if_error:
    lea dx, msg1
	call PrintText
	mov ax, 4C00H
	int 21h
	
create_of:
	xor cx, cx
	mov dx, offset output_n
	mov ax, 3C00h
	int 21h
	jc create_of_error ;tikriname ar sekmingai atidarytas output failas
	mov out_handle, ax
	jmp buferiai
	
create_of_error:
    lea dx, msg2
	call PrintText
	


buferiai:
mov ax, ds
mov es, ax
xor ax, ax
    lea si, in_buff
	    lea di, instr_buff
	    mov instr_pointer, di
	lea di, out_buff
	xor ax, ax
	xor bx, bx
	xor cx, cx
	xor dx, dx
;**********************************
;                                 *
;prasideda pagrindinis algoritmas *
;                                 *
;**********************************
main:
   ;cmp out_handle, 1
   ;jne skip_puship
   call PushIp
   skip_puship:
   call IncSi ;skaitome faila po 512
   cmp eof, 1
   je exit_main_loop
   xor dh, dh
   mov dl, byte ptr [si]
   call Nustatyk ;nustatome instrukcija
   ;cmp out_handle, 1
   ;jne skip_pushspace
   mov cx, 1
   call CheckOutBuff
        mov byte ptr [di], " "
	inc di
	inc out_buff_i
	skip_pushspace:
	    push si
		mov cl, instr_length
		lea si, instr_buff ;dedame instrukcija i bendra buferi
		call PushToOutBuff
		mov instr_length, 0 ;nunuliname instrukcijos ilgi
		lea si, instr_buff
		mov instr_pointer, si
		pop si
		call PushNewline
	cont_main_loop:
	cmp out_buff_i, dydis ;tikriname ar pilnai uzpildytas bendras buferis
	jb main ;jei ne skaitome toliau
	call PrintText
jmp main

exit_main_loop:
    mov cx, 3
	lea si, end_msg
	call PushToOutBuff
	call Print
close_if:
    cmp in_handle, 0
	je close_of
	mov ah, 3Eh
	mov bx, in_handle
	int 21h
	jc close_if_error
	jmp close_of
	
close_if_error:
    lea dx, msg3
	call PrintText
close_of:
    cmp out_handle, 1
	je clean_exit
	mov ah, 3Eh
	mov bx, out_handle
	int 21h
	jc close_of_error
	jmp clean_exit

close_of_error:
    lea dx, msg4
	int 21h
clean_exit:
    mov ax, 4C00h
	int 21h
;**********************************
;                                 *
;FUNKCIJOS                        *
;                                 *
;**********************************
proc Nustatyk
    ;Segmentas
    cmp dl, 26h
    jne skip_es
    mov is_prefix, 0
    jmp was_segment
	
    skip_es:
    cmp dl, 2Eh
    jne skip_cs
    mov is_prefix, 1
    jmp was_segment
	
    skip_cs:
    cmp dl, 36h
    jne skip_ss
    mov is_prefix, 2
    jmp was_segment
	
    skip_ss:
    cmp dl, 3Eh
    jne skip_ds
    mov is_prefix, 3
    jmp was_segment
	
    skip_ds:
    mov is_prefix, 4
    jmp was_not_segment
	
    was_segment:
	call IncSi
    mov dl, byte ptr [si]
	was_not_segment:
	;MOV
	mov al, dl
	xor al, 10001000b ;jei tai mov_1 turetu skirtis/arba ne tik paskutiniai du bitai (didziausia reiksme 3 - 00000011)
	cmp al, 4
	jae skip_mov_1 ;jei didesnis ar lygus
	call its_mov_1
	ret
	
	skip_mov_1:
	mov al, dl
	xor al, 11000110b ;jei tai mov_2 gali skirtis tik paskutinis bitas (w), max reiksme 1
	cmp al, 2
	jae skip_mov_2
	call its_mov_2
	ret
	
	skip_mov_2:
	mov al, dl
	xor al, 10110000b ;jei tai mov_3 gali skirtis tik paskutiniai 4 bitai, max reiksme 15
	cmp al, 16
	jae skip_mov_3
	call its_mov_3
	ret
	
	skip_mov_3:
	mov al, dl
	xor al, 10100000b ;gali skirtis tik paskutinis bitas, jei mov_4 arba mov_5
	cmp al, 4
	jae skip_mov_45
	call its_mov_45
	ret
	
	skip_mov_45:
	mov al, dl
	xor al, 10001100b ;gali skirtis tik priespaskutinis bitas
	shr al, 1 ;stumiam desiniau
	cmp al, 2 ;gauname max reiksme 1
	jae skip_mov_6
	call its_mov_6
	ret
	
	skip_mov_6:
	;OUT
	mov al, dl
	xor al, 11100110b ;ga;i skirtis tik paskutinis bitas
	cmp al, 2
	jae skip_out_1
	call its_out_1
	ret
	
	skip_out_1:
	mov al, dl
	xor al, 11101110b ;gali skirtis tik paskutinis bitas
	cmp al, 2
	jae skip_out_2
	call its_out_2
	ret
	
	skip_out_2:
	;NOT
	mov al, dl
	xor al, 11110110b ;gali skirtis tik paskutinis bitas
	cmp al, 2
	jae skip_not
	call its_not
	ret
	
	skip_not:
	;RCR
	mov al, dl
	xor al, 11010000b ;gali skirtis tik paskutiniai du bitai
	cmp al, 4
	jae skip_rcr
	call its_rcr
	ret
	
	skip_rcr:
	mov al, dl
	xor al, 11010111b ;niekas negali skirtis, turetu gautis 0000 0000
	cmp al, 1
	jae skip_xlat
	call its_xlat
	ret
	
	skip_xlat:
	;UNKNOWN INSTRUCTION

	call NEZINOMA ;UNKNOWN
	ret
endp Nustatyk

proc Read
     push ax
    push bx
    push cx
    push dx
    
    mov ah, 3Fh
    mov bx, in_handle
    mov cx, READ_LENGTH
    lea dx, in_buff
    int 21h
    jnc read_file_success
    read_file_error:
    mov ah, 09h
    lea dx, msg5
    int 21h
    ;end

    read_file_success:
	
    lea si, in_buff
    mov in_buff_end, si
    add in_buff_end, ax
    mov in_buff_length, ax
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
endp Read

proc Print
    push ax
	push bx
	push cx
	push dx
	
	mov ah, 40h
	mov bx, out_handle
	mov cx, out_buff_i
	lea dx, out_buff
	int 21h
	
	mov out_buff_i, 0
	lea di, out_buff
	
	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp Print

proc IncSi
    push dx
	
	cmp si, in_buff_end
	jb checkinbuff_skip_read
	
	cmp in_buff_length, dydis
	je inc_si_read
	
	mov eof, 1 ;jei perskaite maziau uz dydi, pasiekta failo pabaiga
	pop dx
	ret
	inc_si_read:
	    call Read
	    jmp inc_si_end
	checkinbuff_skip_read:
	    inc si
	inc_si_end:
	    inc ip_val
		
	;cmp out_handle, 1
	;jne skip_incsi_push
	;Ikelsime masinini koda
	    xor dh, dh
		mov skip_h, 1
		mov dl, byte ptr[si]
		call PushOutHexValue
		mov skip_h, 0
	skip_incsi_push:
	    pop dx
	ret
endp IncSi

proc CheckOutBuff ;patikrinsime ar isvedimo buferis uzpildytas
    push ax
	
	mov ax, out_buff_i
	add ax, cx
	
	cmp ax, PRINT_LENGTH ;tikriname ar visas buferis uzpildytas
	jbe checkoutbuff_skip_print ;jei ne, tai dar nespausdinsime
	
	call Print
	
	checkoutbuff_skip_print:
	    pop ax
		ret
endp CheckOutBuff

;Ideti cx simboliu is ds:si i isvedimo buferi (es:di)
proc PushToOutBuff
    call CheckOutBuff
	add out_buff_i, cx
	rep movsb
	
	ret
endp PushToOutBuff

proc PushToBuffer
    push di
	add instr_length, cl
	mov di, instr_pointer
	rep movsb
	
	mov instr_pointer, di
	pop di
	ret
endp PushToBuffer

proc PushSpecialSymbol
    push si
	mov cx, 1
	lea si, special_symbols + bx
	call PushToBuffer
	pop si
	ret
endp PushSpecialSymbol

proc PushOutHexValue ;
    ;in dx is word value to be pushed
	push ax
	xor ah, ah
	push si
	    mov cx, 5
		call CheckOutBuff
	cmp force_hex, 1
	je pushouthexvalue_force ;jei du baitai
	cmp dh, 0
	je pushouthexvalue_byte
	    ;konvertuojame i zmogui suprantama pavidala
		pushouthexvalue_force:
		mov al, dh
		and al, 0F0h
		shr al, 4
		lea si, hex_abc
		add si, ax
		movsb
		
		mov al, dh
		and al, 0Fh ;0Fh - 00001111
		lea si, hex_abc
		add si, ax
		movsb
		
		add out_buff_i, 2
		
		pushouthexvalue_byte:
		mov al, dl
		and al, 0F0h
		shr al, 4
		lea si, hex_abc
		add si, ax
		movsb
		
		mov al, dl
		and al, 0Fh
		lea si, hex_abc
		add si, ax
		movsb
		
		add out_buff_i, 2 ;dvi raides vienas baitas
		
		cmp force_hex, 1
		je pushouthexvalue_skip_h
		    cmp skip_h, 1
			je pushouthexvalue_skip_h
		mov byte ptr [di],"h"
		inc di
		inc out_buff_i
		pushouthexvalue_skip_h:
		    pop si
			pop ax
			ret
endp PushOutHexValue

proc PushHexValue
    push ax
	xor ah, ah
	
	push si
	push di
	
	mov di, instr_pointer
	
	cmp force_hex, 1 ;ip
	je pushhexvalue_force ;jei du baitai
	cmp dh, 0
	je pushhexvalue_byte
	pushhexvalue_force:
	mov al, dh
	and al, 0F0h ;11110000
	shr al, 4
	lea si, hex_abc
	add si, ax
	movsb
	
	mov al, dh
	and al, 0Fh ;00001111
	lea si, hex_abc
	add si, ax
	movsb
	
	add instr_length, 2
	
	pushhexvalue_byte:
    mov al, dl
    and al, 0F0h
    shr al, 4
    lea si, hex_abc
    add si, ax
    movsb

    mov al, dl
    and al, 0Fh
    lea si, hex_abc
    add si, ax
    movsb

    add instr_length, 2
	
	cmp force_hex, 1
    je pushhexvalue_skip_h
	cmp skip_h, 1
	je pushhexvalue_skip_h
    mov byte ptr [di], "h" ;pridedam raide h
    inc di
    inc instr_length
    pushhexvalue_skip_h:

	mov instr_pointer, di
	pop di
    pop si
    pop ax
    ret
	
endp PushHexValue

proc PushNewline
    mov cx, 2
	call CheckOutBuff
	
	mov byte ptr[di], 13
	inc di
	mov byte ptr[di], 10
	inc di
	
	add out_buff_i, 2
	ret
endp PushNewline

proc PrintText
    push ax
	
	mov ah, 09h
	int 21h
	lea dx, newline
	int 21h
	
	pop ax
	ret
endp PrintText

proc PushOffset
    mov bx, 5 ;+
	call PushSpecialSymbol
	call read_bytes ;poslinkis
	call PushHexValue
	ret
endp PushOffset

proc read_bytes
    xor dh, dh
	call IncSi
	mov dl, [si]
	;mod = 01 ---> vieno baito poslinkis
	;mod = 10 ---> dvieju baitu poslinks
	;tiesioginis adresas ---> dvieju baitu poslinkis
	cmp mod_val, 01b
	je read_b_offset
	call IncSi
	mov dh, [si]
	
	read_b_offset:
	ret
endp read_bytes

proc read_w_bytes
    xor dh, dh
	call IncSi
	mov dl, [si]
	cmp w_val, 0
	je read_w_b_offset
	call IncSi
	mov dh, [si]
	read_w_b_offset:
	ret
endp read_w_bytes

proc dwmodregrm
    ;w
	mov al, dl
	and al, 1b
	mov w_val, al
	
	;d_val
	mov al, dl
	and al, 10b
	shr al, 1
	mov d_val, al
	
	;Dabar analizuosime mod reg r/m
	call IncSi
	mov dl, byte ptr [si]
	
	;mod
	mov al, dl
	and al, 11000000b
	shr al, 6
	mov mod_val, al
	
	;reg
	mov al, dl
	and al, 111000b
	shr al, 3
	mov reg_val, al
	
	;rm
	mov al, dl
	and al, 111b
	mov rm_val, al
	
	ret
endp dwmodregrm

proc analizuok_reg
    push si
	xor bh, bh
	
	lea si, registers
	mov bl, reg_val
	cmp w_val, 0 ;tikriname ar operuojame zodziais ar baitais
	je parse_reg_skip_add ;jei ne baitais tai reikia pridet 8
	add bx, 8 ;pvz al pavirs ax
	
	parse_reg_skip_add:
	add bx, bx
	add si, bx
	mov cx, 2
	call PushToBuffer ;idedame i buferi
	
	pop si
	ret
endp analizuok_reg

proc analizuok_sreg
    push si
	xor bh, bh
	;Nustatome segmenta
	lea si, segments
	mov bl, sreg_val
	add bx, bx
	add si, bx
	mov cx, 2
	call PushToBuffer
	
	pop si
	ret
endp analizuok_sreg

proc analizuok_rm
    ;mod nusako, koks yra poslinkis, mod 11 - r/m laukas yra registre (AL, AH, BL...)
    cmp mod_val, 11b
	jne rm_skip_mod11
	mov al, rm_val
	mov reg_val, al
	call analizuok_reg
	ret
	
	rm_skip_mod11:
	cmp is_prefix, 4
	je rm_no_prefix
	mov al, is_prefix
	mov sreg_val, al
	call analizuok_sreg
	mov bx, 4 ;dvitaskis
	call PushSpecialSymbol
	
	rm_no_prefix:
	mov bx, 2 ;[ 
	call PushSpecialSymbol
	
	cmp rm_val, 100b
	jb parse_rm_0
	
	cmp rm_val, 110b ;tikriname ar tiesioginis adresas
	jne rm_skip_direct
	
	cmp mod_val, 00b
	jne rm_skip_direct
	;parse_rm_direct:
	call read_bytes
	call PushHexValue
	mov bx, 3;]
	call PushSpecialSymbol
ret	
    rm_skip_direct:
	;parse_rm_4
    push si
	xor bh, bh
	mov bl, rm_val
	sub bl, 4
	add bl, bl
	mov cx, 2 ;[
	lea si, rm_4_registers + bx
	call PushToBuffer
	pop si
	
	;Tikriname ar reikia poslinkio
	cmp mod_val, 00b
	je rm_4_no_offset
	;parse_rm_4_offset:
	call PushOffset
	rm_4_no_offset:
	mov bx, 3 ;]
	call PushSpecialSymbol
	ret
	
	parse_rm_0:
	push si
	xor bh, bh
	mov bl, rm_val
	;nustatome pozicija
	mov cx, 5
	mov al, bl
	mul cl
	mov bl, al
	lea si, rm_0_registers + bx
	call PushToBuffer
	pop si
	
	cmp mod_val, 00b
	je rm_0_no_offset
	;parse_rm_0_offset:
	call PushOffset
	rm_0_no_offset:
	mov bx, 3 ;]
	call PushSpecialSymbol
	ret
endp analizuok_rm

proc PushIp
    push dx
	mov force_hex, 1
	mov dx, ip_val
	call PushOutHexValue
	pop dx
	mov force_hex, 0
	
	mov cx, 2
	call CheckOutBuff
	mov byte ptr [di], ":"
	inc di
	mov byte ptr [di], " "
	inc di
	add out_buff_i, 2
	
	ret
endp PushIp

proc its_mov
    push si
	
	mov cx, 3
	lea si, com_mov
	call PushToBuffer ;ikeliame i buferi mov innstrukcija
	mov bx, 0
	call PushSpecialSymbol ;ikeliame i buferi tarpa
	
	pop si
	ret
endp its_mov

proc its_mov_1
    xor bx, bx
	call  its_mov ;ikelsime i buferi mov
	call dwmodregrm
	
	cmp d_val, 1 ; d = 0 ---> reg -> r/m; d=1 ----> r/m -> reg
	je parse_mov_1_d1
	
	call analizuok_rm
	mov bx, 1
	call PushSpecialSymbol ;ikeliame kableli i buferi
	mov bx, 0
	call PushSpecialSymbol ;ikeliame tarpa i buferi
	call analizuok_reg
	jmp parse_mov_1_end
	
	parse_mov_1_d1:
	call analizuok_reg
	mov bx, 1
	call PushSpecialSymbol ;ikeliame kableli i buferi
	mov bx, 0 ;ikeliame tarpa i buferi
	call PushSpecialSymbol
	call analizuok_rm
	parse_mov_1_end:
	ret
endp its_mov_1

proc its_mov_2
    call its_mov ;ikeliame mov i bufferi
	call dwmodregrm
	call analizuok_rm
	
	mov bx, 1 ;kablelis
   call PushSpecialSymbol
	
    mov bx, 0 ;space
    call PushSpecialSymbol
	call read_w_bytes ;bet. op1 [bet.op2, jei w = 1]
	call PushHexValue ;paverciame i hex pavidala
	ret
endp its_mov_2

proc its_mov_3
    mov al, dl
	and al, 111b
	mov reg_val, al
	
	mov al, dl
	and al, 1000b
	shr al, 3
	mov w_val, al
	
	call its_mov
	call analizuok_reg
	mov bx, 1;kablelis
	call PushSpecialSymbol
	mov bx, 0 ;space
	call PushSpecialSymbol
	call read_w_bytes ;bet. op1 [bet.op2, jei w = 1]
	call PushHexValue  ;paverciame i hex pavidala
	ret
endp its_mov_3

proc its_mov_45
    mov al, dl
	and al, 1
	mov w_val, al
	
	mov al, dl
	and al, 10b
	shr al, 1
	mov d_val, al
	
	mov mod_val, 0
	mov reg_val, 0 ;registras yra akumuliatorius
	mov rm_val, 110b
	;tiesiogine adresacija
	cmp is_prefix, 4
	jne mov_45_already_segment
	dec is_prefix
	mov_45_already_segment:
	
	call its_mov
	cmp d_val, 1
	je parse_mov_5
	;parse_mov_4
	call analizuok_reg ;al arba ax
	mov bx, 1 ;kablelis
	call PushSpecialSymbol
	mov bx, 0 ;tarpas
	call PushSpecialSymbol
	call analizuok_rm
	ret
	
	parse_mov_5:
	call analizuok_rm
	mov bx, 1 ;kablelis
	call PushSpecialSymbol
	mov bx, 0 ;tarpas
	call PushSpecialSymbol
	call analizuok_reg
	ret
endp its_mov_45

proc its_mov_6
    push dx
	call its_mov
	call dwmodregrm
	pop dx
	
	mov al, dl
	and al, 10b
	shr al, 1
	mov d_val, al
	
	mov w_val, 1
	
	mov al, reg_val
	mov sreg_val, al
	
	cmp d_val, 0
	jne mov_6_d1
	
	;parse_mov_6_d0:
	call analizuok_rm
	mov bx, 1 ;kablelis
	call PushSpecialSymbol
	mov bx, 0 ;tarpas
	call PushSpecialSymbol
	call analizuok_sreg
	ret
	
	mov_6_d1:
	call analizuok_sreg
	mov bx, 1 ;kablelis
	call PushSpecialSymbol
	mov bx, 0 ;tarpas
	call PushSpecialSymbol
	call analizuok_rm
	ret
endp its_mov_6

proc its_out
    push si
	mov cx, 3
	lea si, com_out
	call PushToBuffer
	pop si
	mov bx, 0 ;tarpas
	call PushSpecialSymbol
	ret
endp its_out

proc its_out_1
    push dx
	mov w_val, 0
	call read_w_bytes ;perskaitysime viena baita
	mov port_val, dl
	pop dx
	
	mov al, dl
	and al, 1
	mov w_val, al
	mov reg_val, 000 ;Registre AL (jei w = 0) arba registre AX (jei w = 1)
	
	call its_out
	push dx
	xor dh, dh
	mov dl, port_val
	call PushHexValue ;kovertuojame i hex
	pop dx
	mov bx, 1 ;kablelis
	call PushSpecialSymbol
	mov bx, 0 ;tarpas
	call PushSpecialSymbol
	call analizuok_reg ;ax arba al registras
	
	ret
endp its_out_1

proc its_out_2
    push dx
	call its_out
	mov w_val, 1
	mov reg_val, 010b ;isvedame dx registra
	call analizuok_reg
	
	pop dx
	mov al, dl
	and al, 1
	mov w_val, al
	
	mov bx, 1
	call PushSpecialSymbol
	mov bx, 0
	call PushSpecialSymbol
	
	mov reg_val, 0 ;siunciame is AX arba is AL
	call analizuok_reg
	
	ret
	
endp its_out_2

proc its_not
    call dwmodregrm
	
	cmp reg_val, 010b
	jne ne_not
	
	push si
	mov cx, 3
	lea si, com_not
	call PushToBuffer
	pop si
	mov bx, 0 ;tarpas
	call PushSpecialSymbol
	
	call analizuok_rm
	ret
	ne_not:
	call NEZINOMA
	ret
endp its_not

proc its_rcr
    call dwmodregrm
	
	cmp reg_val, 011b
	jne ne_rcr
	
	push si
	mov cx, 3
	lea si, com_rcr
	call PushToBuffer
	pop si
	mov bx, 0 ;tarpas
	call PushSpecialSymbol
	
	call analizuok_rm
	mov bx, 1 ;kablelis
	call PushSpecialSymbol
	mov bx, 0 ;tarpas
	call PushSpecialSymbol
	
	cmp d_val, 1
	je rcr_v1
	
	;jeigu v = 0, tai pastumiama i desine per viena pozicija
	;parce_rcr_v0
	push di
	mov di, instr_pointer
	mov byte ptr [di], "1"
	inc di
	inc instr_length
	mov instr_pointer, di
	pop di
	ret
	
	;jeigu v = 1, tai postumio skaitliukas yra registro CL reiksme
	rcr_v1:
	mov w_val, 0
	mov reg_val, 001b
	call analizuok_reg
	ret
	
	ne_rcr:
	call NEZINOMA
	ret
endp its_rcr

proc its_xlat
    push si
	mov cx, 4
	lea si, com_xlat
	call PushToBuffer
	pop si
	ret
endp its_xlat

proc NEZINOMA
    push si
	mov cx, 7
	lea si, unk
	call PushToBuffer
	pop si
	ret
endp NEZINOMA
end start
