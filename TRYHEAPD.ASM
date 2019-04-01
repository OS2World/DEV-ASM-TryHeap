        title   TRYHEAP Demo of HEAP.ASM routines
        page    55,132

; TRYHEAP.ASM   Demo of routines in HEAP.ASM (MS-DOS version)
; Copyright (C) 1989 Ziff Davis Communications
; PC Magazine * Ray Dunan

cr      equ     0dh                     ; ASCII carriage return
lf      equ     0ah                     ; ASCII line feed
hsize   equ     4096                    ; heap size     

stdin   equ     0                       ; standard input handle
stdout  equ     1                       ; standard output handle

DGROUP  group   _DATA


_DATA   segment word public 'DATA'

msg1    db      cr,lf
        db      'Heap Manager Demonstration Program'
        db      cr,lf
msg1_len equ $-msg1

msg2    db      cr,lf
        db      'Commands available:'
        db      cr,lf,lf
        db      'A nnnn       = Allocate block of nnnn bytes'
        db      cr,lf
        db      'R xxxx nnnn  = Reallocate block xxxx to nnnn bytes'
        db      cr,lf
        db      'F xxxx       = Free block xxxx'
        db      cr,lf,lf
        db      'All values are entered and displayed in hex.'
        db      cr,lf
msg2_len equ $-msg2

msg3    db      cr,lf,lf,'Enter command:  '
msg3_len equ $-msg3

msg4    db      cr,lf,'Function failed!',cr,lf
msg4_len equ $-msg4

msg5    db      cr,lf,'Initialization failed!',cr,lf
msg5_len equ $-msg5
        
msg6    db      cr,lf,'Returned pointer: '
msg6a   db      'XXXX',cr,lf
msg6_len equ $-msg6

msg7    db      cr,lf,'Current heap contents:'
        db      cr,lf,lf,'Base  Length  Owned/Free'
msg7_len equ $-msg7

msg8    db      cr,lf
msg8a   db      'XXXX   '               ; base address (hex)    
msg8b   db      'XXXX   '               ; block length (hex)
msg8c   db      'X'                     ; O = owned, F = free
msg8_len equ $-msg8

ibuff   db      80 dup (?)              ; keyboard input buffer

heap    db      hsize dup (?)           ; heap storage area

_DATA   ends


_TEXT   segment word public 'CODE'

        assume  cs:_TEXT,ds:_DATA

        extrn   hinit:near              ; initialize heap
        extrn   halloc:near             ; allocate heap block
        extrn   hrealloc:near           ; resize heap block
        extrn   hfree:near              ; free heap block
        extrn   htol:near               ; hex ASCII to binary
        extrn   itoh:near               ; binary to hex ASCII

main    proc    far

        mov     ax,DGROUP               ; make our data segment
        mov     ds,ax                   ; addressable 
        mov     es,ax

        mov     bx,offset heap          ; heap base address
        mov     ax,hsize                ; heap size
        call    hinit                   ; initialize heap

        jnc     main1                   ; successful init, continue

        mov     dx,offset msg5          ; initialization failed,
        mov     cx,msg5_len             ; display error message
        call    pmsg                    ; and exit
        jmp     main9

main1:  mov     dx,offset msg1          ; display sign-on message
        mov     cx,msg1_len
        call    pmsg

        mov     dx,offset msg2          ; display help message
        mov     cx,msg2_len             ; listing available commands
        call    pmsg

        call    hwalk                   ; walk & display heap

main2:  mov     dx,offset msg3          ; display prompt
        mov     cx,msg3_len
        call    pmsg       

                                        ; read keyboard...
        mov     dx,offset ibuff         ; buffer address
        mov     cx,80                   ; buffer length
        mov     bx,stdin                ; standard input handle
        mov     ah,3fh                  ; function 3fh = read
        int     21h                     ; transfer to MS-DOS

        cmp     ax,2                    ; anything entered?
        je      main9                   ; no, terminate program

        mov     ax,word ptr ibuff       ; get first 2 chars
        or      ax,0020h                ; lower-case the command

        cmp     ax,' a'                 ; allocate block command?
        je      main3                   ; yes, jump

        cmp     ax,' r'                 ; reallocate block command?
        je      main4                   ; yes, jump

        cmp     ax,' f'                 ; free block command?
        je      main6                   ; yes, jump

        mov     dx,offset msg2          ; couldn't match command,
        mov     cx,msg2_len             ; display list of available
        call    pmsg                    ; commands

        jmp     main2                   ; get another command   

main3:                                  ; allocate block command

        mov     si,offset ibuff+2       ; convert block size    
        call    htol

        call    halloc                  ; now request allocation
        jc      main7                   ; jump if function failed
        jmp     main5                   ; go display returned pointer

main4:                                  ; reallocate block command

        mov     si,offset ibuff+2       ; convert block pointer
        call    htol

        mov     bx,ax                   ; convert new block size        
        call    htol

        call    hrealloc                ; now request reallocation
        jc      main7                   ; jump if function failed

main5:  mov     ax,bx                   ; function succeeded,
        mov     bx,offset msg6a         ; convert returned pointer
        call    itoh

        mov     dx,offset msg6          ; display returned pointer
        mov     cx,msg6_len
        call    pmsg

        jmp     main8                   ; go display heap

main6:                                  ; free block command

        mov     si,offset ibuff+2       ; convert block pointer
        call    htol

        mov     bx,ax                   ; request release of block
        call    hfree
        jnc     main8                   ; jump if function successful

main7:  mov     dx,offset msg4          ; display 'Function failed!'
        mov     cx,msg4_len
        call    pmsg

main8:  call    hwalk                   ; walk & display heap
        jmp     main2                   ; get another entry

main9:  mov     ax,4c00h                ; function 4CH = exit   
        int     21h                     ; transfer to MS-DOS

main    endp

;
; HWALK: displays address, length, and status of each heap block
;
; Call with:    nothing
;
; Returns:      nothing
;
hwalk   proc    near

        mov     dx,offset msg7          ; display heading
        mov     cx,msg7_len
        call    pmsg

        mov     si,offset heap          ; address of start of heap
        mov     di,si           
        add     di,hsize                ; address of end of heap

hwalk1: cmp     si,di                   ; end of heap yet?
        je      hwalk3                  ; yes, exit

        mov     ax,si                   ; convert block address
        add     ax,2                    ; to ASCII
        mov     bx,offset msg8a
        call    itoh

        lodsw                           ; get length of block
        mov     msg8c,'F'               ; assume block free
        or      ax,ax                   ; test allocated bit
        jns     hwalk2                  ; jump, block really free
        mov     msg8c,'O'               ; indicate block owned

hwalk2: and     ax,7fffh                ; isolate length and
        add     si,ax                   ; update block pointer

        mov     bx,offset msg8b         ; convert block length
        call    itoh                    ; to ASCII

        mov     dx,offset msg8          ; display block information
        mov     cx,msg8_len
        call    pmsg

        jmp     hwalk1                  ; do next block

hwalk3: ret

hwalk   endp

;
; PMSG: display message on standard output
;
; Call with:    DS:DX = message address
;               CX    = message length
;
; Returns:      nothing
;
pmsg    proc    near   

        mov     bx,stdout               ; standard output handle
        mov     ah,40h                  ; function 40h = write
        int     21h                     ; transfer to MS-DOS
        ret                             ; return to caller

pmsg    endp

_TEXT   ends


STACK   segment para stack 'STACK'

        dw      64 dup (0)

STACK   ends

        end     main

