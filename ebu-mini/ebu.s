.intel_syntax noprefix
.code16
.text
.global _start
_start:
    cli
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov sp,0x7000
    sti
    cld
    mov ax,3
    int 0x10
    mov byte ptr [attr],0x0B
    call cls
    mov si,offset banner
    call print
    mov byte ptr [attr],0x0F
    mov si,offset m_boot
    call print
    mov cx,30
1:  mov al,0xDB
    call putc
    push cx
    xor cx,cx
    mov dx,0x8000
    mov ah,0x86
    int 0x15
    pop cx
    loop 1b
    call nl
    call nl
login:
    mov byte ptr [attr],0x0F
    mov si,offset m_user
    call print
    mov byte ptr [mask],0
    mov di,offset ubuf
    call readline
    mov si,offset m_pass
    call print
    mov byte ptr [mask],1
    mov di,offset buf
    call readline
    mov byte ptr [mask],0
    mov bx,offset utab
1:  mov di,[bx]
    test di,di
    jz 9f
    mov si,offset ubuf
    call streq
    jnz 2f
    mov di,[bx+2]
    mov si,offset buf
    call streq
    jnz 9f
    mov ax,[bx]
    mov [username],ax
    jmp welcome
2:  add bx,4
    jmp 1b
9:  mov byte ptr [attr],0x0C
    mov si,offset m_bad
    call print
    jmp login
welcome:
    mov byte ptr [attr],0x0A
    call cls
    mov si,offset m_wel
    call print
    mov si,[username]
    call print
    mov si,offset m_wel2
    call print
shell:
    mov byte ptr [mask],0
    mov byte ptr [attr],0x0E
    mov si,[username]
    call print
    mov si,offset m_prompt
    call print
    mov byte ptr [attr],0x0A
    mov di,offset buf
    call readline
    cmp byte ptr [buf],0
    je shell
    mov word ptr [arg],offset empty
    mov si,offset buf
1:  lodsb
    test al,al
    jz 2f
    cmp al,' '
    jne 1b
    mov byte ptr [si-1],0
    mov [arg],si
2:  mov bx,offset cmdtab
3:  mov di,[bx]
    test di,di
    jz 5f
    mov si,offset buf
    call streq
    jz 4f
    add bx,4
    jmp 3b
4:  call word ptr [bx+2]
    jmp shell
5:  mov si,offset m_unk
    call print
    jmp shell

# ---------- komutlar ----------
do_help:
    mov si,offset m_help
    jmp print
do_ver:
    mov si,offset m_ver
    jmp print
do_about:
    mov si,offset m_about
    jmp print
do_clear:
    jmp cls
do_echo:
    mov si,[arg]
    call print
    jmp nl
do_whoami:
    mov si,[username]
    call print
    jmp nl
do_time:
    mov ah,2
    int 0x1A
    mov al,ch
    call pbcd
    mov al,':'
    call putc
    mov al,cl
    call pbcd
    mov al,':'
    call putc
    mov al,dh
    call pbcd
    jmp nl
do_date:
    mov ah,4
    int 0x1A
    mov al,dl
    call pbcd
    mov al,'/'
    call putc
    mov al,dh
    call pbcd
    mov al,'/'
    call putc
    mov al,ch
    call pbcd
    mov al,cl
    call pbcd
    jmp nl
do_mem:
    int 0x12
    call printdec
    mov si,offset m_kb
    jmp print
do_color:
    mov si,[arg]
    mov al,[si]
    cmp al,'0'
    jb 9f
    cmp al,'9'
    jbe 1f
    or al,0x20
    cmp al,'a'
    jb 9f
    cmp al,'f'
    ja 9f
    sub al,'a'-10-'0'
1:  sub al,'0'
    mov [attr],al
    jmp cls
9:  mov si,offset m_color
    jmp print
do_rainbow:
    mov byte ptr [tmp],1
1:  mov al,[tmp]
    mov [attr],al
    mov si,offset m_ebu
    call print
    inc byte ptr [tmp]
    cmp byte ptr [tmp],16
    jb 1b
    mov byte ptr [attr],0x0A
    jmp nl
do_beep:
    mov al,0xB6
    out 0x43,al
    mov ax,1356
    out 0x42,al
    mov al,ah
    out 0x42,al
    in al,0x61
    or al,3
    out 0x61,al
    mov ah,0x86
    mov cx,7
    mov dx,0xA120
    int 0x15
    in al,0x61
    and al,0xFC
    out 0x61,al
    ret
do_calc:
    mov si,[arg]
    call atoi
    push ax
    call skipsp
    lodsb
    mov dl,al
    call skipsp
    call atoi
    mov cx,ax
    pop ax
    cmp dl,'+'
    je 1f
    cmp dl,'-'
    je 2f
    cmp dl,'*'
    je 3f
    cmp dl,'/'
    je 4f
    jmp 9f
1:  add ax,cx
    jmp 8f
2:  sub ax,cx
    jns 8f
    push ax
    mov al,'-'
    call putc
    pop ax
    neg ax
    jmp 8f
3:  mul cx
    jmp 8f
4:  test cx,cx
    jz 9f
    xor dx,dx
    div cx
8:  call printdec
    jmp nl
9:  mov si,offset m_calc
    jmp print
do_sinav:
    mov word ptr [score],0
    mov bx,offset qtab
1:  mov si,[bx]
    test si,si
    jz 3f
    call print
    mov di,offset buf
    call readline
    mov si,offset buf
    mov di,[bx+2]
    call streq
    jnz 2f
    inc word ptr [score]
2:  add bx,4
    jmp 1b
3:  mov si,offset m_score
    call print
    mov ax,[score]
    call printdec
    mov si,offset m_of3
    jmp print
do_halt:
    mov si,offset m_halt
    call print
    cli
1:  hlt
    jmp 1b
do_reboot:
    .byte 0xEA
    .word 0,0xFFFF

# ---------- yardimcilar ----------
nl:
    push ax
    mov al,13
    call putc
    mov al,10
    call putc
    pop ax
    ret
print:
    lodsb
    test al,al
    jz 1f
    call putc
    jmp print
1:  ret
putc:
    pusha
    cmp al,13
    je 7f
    cmp al,10
    je 7f
    cmp al,8
    je 7f
    mov ah,9
    xor bh,bh
    mov bl,[attr]
    mov cx,1
    int 0x10
    mov ah,3
    xor bh,bh
    int 0x10
    inc dl
    cmp dl,80
    jb 6f
    mov ax,0x0E0D
    mov bx,7
    int 0x10
    mov ax,0x0E0A
    int 0x10
    jmp 8f
6:  mov ah,2
    int 0x10
    jmp 8f
7:  mov ah,0x0E
    mov bx,7
    int 0x10
8:  popa
    ret
cls:
    pusha
    mov ax,0x0600
    mov bh,[attr]
    xor cx,cx
    mov dx,0x184F
    int 0x10
    mov ah,2
    xor bx,bx
    xor dx,dx
    int 0x10
    popa
    ret
readline:
    xor cx,cx
1:  xor ah,ah
    int 0x16
    cmp al,13
    je 3f
    cmp al,8
    je 2f
    cmp al,32
    jb 1b
    cmp cx,60
    jae 1b
    stosb
    inc cx
    cmp byte ptr [mask],0
    je 4f
    mov al,'*'
4:  call putc
    jmp 1b
2:  test cx,cx
    jz 1b
    dec di
    dec cx
    mov al,8
    call putc
    mov al,' '
    call putc
    mov al,8
    call putc
    jmp 1b
3:  xor al,al
    stosb
    jmp nl
streq:
1:  lodsb
    mov ah,[di]
    inc di
    cmp al,ah
    jne 2f
    test al,al
    jnz 1b
2:  ret
skipsp:
1:  cmp byte ptr [si],' '
    jne 2f
    inc si
    jmp 1b
2:  ret
atoi:
    xor bx,bx
1:  movzx ax,byte ptr [si]
    sub ax,'0'
    cmp ax,9
    ja 2f
    inc si
    push ax
    mov ax,bx
    mov cx,10
    mul cx
    pop dx
    add ax,dx
    mov bx,ax
    jmp 1b
2:  mov ax,bx
    ret
printdec:
    push bx
    push cx
    push dx
    xor cx,cx
    mov bx,10
1:  xor dx,dx
    div bx
    push dx
    inc cx
    test ax,ax
    jnz 1b
2:  pop ax
    add al,'0'
    call putc
    loop 2b
    pop dx
    pop cx
    pop bx
    ret
pbcd:
    push ax
    shr al,4
    add al,'0'
    call putc
    pop ax
    and al,0x0F
    add al,'0'
    jmp putc

# ---------- veri ----------
attr: .byte 0x0A
mask: .byte 0
tmp:  .byte 0
score: .word 0
arg: .word 0
username: .word 0
empty: .byte 0
banner: .ascii "\r\n  _____ ____  _   _\r\n | ____| __ )| | | |    EBU OS 1.0\r\n |  _| |  _ \\| | | |    Egitim icin kendi isletim sistemi\r\n | |___| |_) | |_| |\r\n |_____|____/ \\___/\r\n\r\n"
.byte 0
m_boot: .asciz "  Sistem yukleniyor: "
m_user: .asciz "  Kullanici: "
m_pass: .asciz "  Sifre: "
m_bad: .asciz "  Hatali giris! (ogrenci/1234  ogretmen/ogretmen  root/root)\r\n\r\n"
m_wel: .asciz "\r\n  Hos geldin, "
m_wel2: .asciz "!  'help' yaz.\r\n\r\n"
m_prompt: .asciz "@ebu:~$ "
m_unk: .asciz "Komut bulunamadi. 'help' yaz.\r\n"
m_ver: .asciz "EBU OS 1.0 (16-bit gercek mod cekirdek)\r\n"
m_about: .asciz "EBU OS: sifirdan yazilmis egitim isletim sistemi.\r\nLinux ve Windows'tan bagimsiz, tek ISO.\r\n"
m_help: .asciz "Komutlar:\r\n help  ver  about  clear  echo  whoami  time  date  mem\r\n color <0-f>  rainbow  beep  calc 12+30  sinav  halt  reboot\r\n"
m_kb: .asciz " KB bellek\r\n"
m_color: .asciz "Kullanim: color 0-f\r\n"
m_calc: .asciz "Kullanim: calc 12+30  (+ - * /)\r\n"
m_ebu: .asciz "EBU OS "
m_score: .asciz "\r\nPuan: "
m_of3: .asciz " / 3\r\n"
m_halt: .asciz "Kapaniyor... Bilgisayari guvenle kapatabilirsin.\r\n"
q1: .asciz "1) 7 x 8 = ? "
q2: .asciz "2) Turkiye'nin baskenti (kucuk harf)? "
q3: .asciz "3) Suyun kaynama noktasi (C)? "
a1: .asciz "56"
a2: .asciz "ankara"
a3: .asciz "100"
qtab: .word q1,a1,q2,a2,q3,a3,0
u1: .asciz "ogrenci"
p1: .asciz "1234"
u2: .asciz "ogretmen"
p2: .asciz "ogretmen"
u3: .asciz "root"
p3: .asciz "root"
utab: .word u1,p1,u2,p2,u3,p3,0
s_help: .asciz "help"
s_ver: .asciz "ver"
s_about: .asciz "about"
s_clear: .asciz "clear"
s_echo: .asciz "echo"
s_whoami: .asciz "whoami"
s_time: .asciz "time"
s_date: .asciz "date"
s_mem: .asciz "mem"
s_color: .asciz "color"
s_rainbow: .asciz "rainbow"
s_beep: .asciz "beep"
s_calc: .asciz "calc"
s_sinav: .asciz "sinav"
s_halt: .asciz "halt"
s_reboot: .asciz "reboot"
cmdtab: .word s_help,do_help,s_ver,do_ver,s_about,do_about,s_clear,do_clear,s_echo,do_echo,s_whoami,do_whoami
 .word s_time,do_time,s_date,do_date,s_mem,do_mem,s_color,do_color,s_rainbow,do_rainbow,s_beep,do_beep
 .word s_calc,do_calc,s_sinav,do_sinav,s_halt,do_halt,s_reboot,do_reboot,0,0
ubuf: .skip 64
buf: .skip 64
