
left equ 0
top equ 2
row equ 22
col equ 78
right equ left+col
bottom equ top+row

.model small
.data          
    heading db "---------------------------Welcome to the snake game----------------------------",0
    instructions db 0AH,0DH,"Use w, a, s and d to control your snake",0AH,0DH,"Press q to quit",0DH,0AH, "Press any key to continue$"
    quitmsg db "Thank you for playing!",0
    gameovermsg db "----------------------------------GAME OVER!------------------------------------", 0
    scoremsg db "Score: ",0
    head db '^',10,10
    body db '*',10,11, 3*15 DUP(0)
    segmentcount db 1
    foodactive db 1
    foodx db 8
    foody db 8
    gameover db 0
    quit db 0   
    delaytime db 5


.stack
    dw   128  dup(0)


.code

main proc far
	mov ax, @data
	mov ds, ax 
	
	mov ax, 0b800H
	mov es, ax
	
	;clearing the screen
	mov ax, 0003H
	int 10H
	
	lea bx, heading
	mov dx,00
	call writestringat
	
	lea dx, instructions
	mov ah, 09H
	int 21h
	
	mov ah, 07h
	int 21h
	mov ax, 0003H
	int 10H
    call printbox      
    
    
mainloop:       
    call delay             
    lea bx, heading
    mov dx, 00
    call writestringat
    call shiftsnake
    cmp gameover,1
    je gameover_mainloop
    
    call keyboardfunctions
    cmp quit, 1
    je quitpressed_mainloop
    call foodgeneration
    call draw
    
	jmp mainloop
    
gameover_mainloop: 
    mov ax, 0003H
	int 10H
    mov delaytime, 100
    mov dx, 0000H
    lea bx, gameovermsg
    call writestringat
    call delay    
    jmp quit_mainloop    
    
quitpressed_mainloop:
    mov ax, 0003H
	int 10H    
    mov delaytime, 100
    mov dx, 0000H
    lea bx, quitmsg
    call writestringat
    call delay    
    jmp quit_mainloop    
    
quit_mainloop:
;first clear screen
	mov ax, 0003H
	int 10h    
	mov ax, 4c00h
	int 21h  


delay proc 
      
    mov ah, 00
    int 1Ah
    mov bx, dx
    
jmp_delay:
    int 1Ah
    sub dx, bx
    cmp dl, delaytime                                                      
    jl jmp_delay    
    ret
    
delay endp
   
   


foodgeneration proc
    mov ch, foody
    mov cl, foodx
	
regenerate:
    cmp foodactive, 1
    je ret_foodactive
    mov ah, 00
    int 1Ah
    ;dx contains the ticks
    push dx
    mov ax, dx
    xor dx, dx
    xor bh, bh
    mov bl, row
    dec bl
    div bx
    mov foody, dl
    inc foody
    
    
    pop ax
    mov bl, col
    dec dl
    xor bh, bh
    xor dx, dx
    div bx
    mov foodx, dl
    inc foodx
    
    cmp foodx, cl
    jne ignore
    cmp foody, ch
    jne ignore
    jmp regenerate        
	
ignore:
    mov al, foodx
    ror al,1
    jc regenerate
    
    
    add foody, top
    add foodx, left 
    
    mov dh, foody
    mov dl, foodx
    call readcharat
    cmp bl, '*'
    je regenerate
    cmp bl, '^'
    je regenerate
    cmp bl, '<'
    je regenerate
    cmp bl, '>'
    je regenerate
    cmp bl, 'v'
    je regenerate    
    
ret_foodactive:
    ret
foodgeneration endp


dispdigit proc
    add dl, '0'
    mov ah, 02H
    int 21H
    ret
dispdigit endp   
   
dispnum proc    
    test ax,ax
    jz retz
    xor dx, dx
    ;ax contains the number to be displayed
    mov bx,10
    div bx
    ;dispnum ax first
    push dx
    call dispnum  
    pop dx
    call dispdigit
    ret
retz:
    mov ah, 02  
    ret    
dispnum endp   

setcursorpos proc
    mov ah, 02H
    push bx
    mov bh,0
    int 10h
    pop bx
    ret
setcursorpos endp


draw proc
    lea bx, scoremsg
    mov dx, 0109
    call writestringat
    
    
    add dx, 7
    call setcursorpos
    mov al, segmentcount
    dec al
    xor ah, ah
    call dispnum
        
    lea si, head
draw_loop:
    mov bl, ds:[si]
    test bl, bl
    jz out_draw
    mov dx, ds:[si+1]
    call writecharat
    add si,3   
    jmp draw_loop 

out_draw:
    mov bl, 'O'
    mov dh, foody
    mov dl, foodx
    call writecharat
    mov foodactive, 1
    
    ret
    
draw endp



;dl contains the ascii character if keypressed, else dl contains 0
readchar proc
    mov ah, 01H
    int 16H
    jnz keybdpressed
    xor dl, dl
    ret
keybdpressed:
    mov ah, 00H
    int 16H
    mov dl,al
    ret

readchar endp                    


keyboardfunctions proc
    
    call readchar
    cmp dl, 0
    je next_14
    

    cmp dl, 'w'
    jne next_11
    cmp head, 'v'
    je next_14
    mov head, '^'
    ret
next_11:
    cmp dl, 's'
    jne next_12
    cmp head, '^'
    je next_14
    mov head, 'v'
    ret
next_12:
    cmp dl, 'a'
    jne next_13
    cmp head, '>'
    je next_14
    mov head, '<'
    ret
next_13:
    cmp dl, 'd'
    jne next_14
    cmp head, '<'
    je next_14
    mov head,'>'
next_14:    
    cmp dl, 'q'
    je quit_keyboardfunctions
    ret    
	
quit_keyboardfunctions:     
    inc quit
    ret
    
keyboardfunctions endp


shiftsnake proc     
    mov bx, offset head
    
    xor ax, ax
    mov al, [bx]
    push ax
    inc bx
    mov ax, [bx]
    inc bx    
    inc bx
    xor cx, cx
l:      
    mov si, [bx]
    test si, [bx]
    jz outside
    inc cx     
    inc bx
    mov dx,[bx]
    mov [bx], ax
    mov ax,dx
    inc bx
    inc bx
    jmp l
    
outside:    

    pop ax
    
    push dx

      
    lea bx, head
    inc bx
    mov dx, [bx]
    
    cmp al, '<'
    jne next_1
    dec dl
    dec dl
    jmp done_checking_the_head
next_1:
    cmp al, '>'
    jne next_2                
    inc dl 
    inc dl
    jmp done_checking_the_head
    
next_2:
    cmp al, '^'
    jne next_3 
    dec dh               

    jmp done_checking_the_head
    
next_3:
    ;must be 'v'
    inc dh
    
done_checking_the_head:    
    mov [bx],dx
 
    call readcharat ;dx
    
    cmp bl, 'O'
    je i_ate_food
    
    
	mov cx, dx
    pop dx 
    cmp bl, '*'    ;the snake bit itself, gameover
    je game_over
    mov bl, 0
    call writecharat
    mov dx, cx
    
    
    
    
    
    ;check whether the snake is within the boundary
    cmp dh, top
    je game_over
    cmp dh, bottom
    je game_over
    cmp dl,left
    je game_over
    cmp dl, right
    je game_over
    
	ret

game_over:
    inc gameover
    ret

i_ate_food:    

    mov al, segmentcount
    xor ah, ah
    
    
    lea bx, body
    mov cx, 3
    mul cx
    
    pop dx
    add bx, ax
    mov byte ptr ds:[bx], '*'
    mov [bx+1], dx
    inc segmentcount 
    mov dh, foody
    mov dl, foodx
    mov bl, 0
    call writecharat
    mov foodactive, 0   
    ret 
shiftsnake endp


printbox proc

    mov dh, top
    mov dl, left
    mov cx, col
    mov bl, '*'
l1:                 
    call writecharat
    inc dl
    loop l1
    
    mov cx, row
l2:
    call writecharat
    inc dh
    loop l2
    
    mov cx, col
l3:
    call writecharat
    dec dl
    loop l3

    mov cx, row     
l4:
    call writecharat    
    dec dh 
    loop l4    
    
    ret
printbox endp

writecharat proc
    ;80x25
    push dx
    mov ax, dx
    and ax, 0FF00H
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    
    
    push bx
    mov bh, 160
    mul bh 
    pop bx
    and dx, 0FFH
    shl dx,1
    add ax, dx
    mov di, ax
    mov es:[di], bl
    pop dx
    ret    
writecharat endp
   
readcharat proc
    push dx
    mov ax, dx
    and ax, 0FF00H
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1    
    push bx
    mov bh, 160
    mul bh 
    pop bx
    and dx, 0FFH
    shl dx,1
    add ax, dx
    mov di, ax
    mov bl,es:[di]
    pop dx
    ret
readcharat endp        

writestringat proc
    push dx
    mov ax, dx
    and ax, 0FF00H
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    
    push bx
    mov bh, 160
    mul bh
    
    pop bx
    and dx, 0FFH
    shl dx,1
    add ax, dx
    mov di, ax
	
loop_writestringat:
    
    mov al, [bx]
    test al, al
    jz exit_writestringat
    mov es:[di], al
    inc di
    inc di
    inc bx
    jmp loop_writestringat
    
    
exit_writestringat:
    pop dx
    ret
    
    
writestringat endp

     
main endp
          
end main

