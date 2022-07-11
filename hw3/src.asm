.model tiny
.code
org 0100h
start:
    xlat
    xlat
	
    rcr ax, 1    
    rcr cl, cl
    rcr al, 1
    rcr rcrd, 1
    rcr rcrd, cl
	
	div ax
	div byte ptr [di + 1234h]
	
	rcl cl, cl
	rcl al, 1
	
    not ax
    not notd
    not al
    not bh
    not di
	
    out 25h, AL
    out 12h, AX
    out dx, al
    out dx, al
    out dx, ax
	
    mov ax, ax
    mov bx, cx
    mov dh, ah
    mov bh, bl
    mov di, si
    mov dl, al
    mov bl, dh
    mov al, 45h
    mov ax, 1245h
    mov dx, 4565h
    mov mov1d, 45h
    mov si, 1234h
    mov ax, mov2d
    mov al, mov1d
    mov mov1d, al
    mov mov2d, ax
    mov ah, mov1d
    mov mov1d, ah
    mov es, mov2d
	mov mov2d, ds
    mov es, dx
    mov es, ax
    mov ds, dx
    mov dx, cs
    mov ss, si
    mov ds, sp
    mov ds, sp
    mov ds, sp
    mov ds, sp
    mov ds, sp
    mov ds, sp
	
    mov2d dw 0h
    mov1d db 0h
    notd db 111b
    rcrd db 13h
end start