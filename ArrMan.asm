include 'emu8086.inc'
.MODEL SMALL
.stack 100h
.data

; Operations symbols
sumchar db 's'
avgchar db 'a'
maxminchar db 'm'
modchar db 'f'

; Array counter to keep track of array length
length dw 0  

; To store the maximum value
max dw 0000h, '$' 
maxString db '00000$' 
; To store the maximum value
min dw 0000h, '$'       
minString db '00000$'
; To store sum result
sumResult dw 0000h, '$'


; The array 
arr dw 50 dup(?)

; Messages to be printed
enterArrayMsg db  'Enter elements, to finish an element, press enter. To exit entering elements, press Enter twice$' 
ChooseMsg db 'press the character corresponding to the desired operation $'
optionsMsg db 'a-Average             s-Sum', 0AH, 0DH, 'm-Maximum / Minimum   f-most occurring number$'
maxmessage db 0Dh ,'the maximum number is:-  $'
minmessage db 0Dh ,'the minimum number is:-  $'
summessage db 0D ,'the array summation is:- $'
avgmessage db 0D ,'the array average is:- $'

 

; Others  

n_line db 0AH,0DH,"$" ; For new line
enterPressCount db 00h
num10 dw 000Ah

.code

DEFINE_PRINT_NUM                
DEFINE_PRINT_NUM_UNS    



main proc far
    mov ax, @data
    mov ds, ax
    
    lea dx, enterArrayMsg
    mov ah, 09h
    int 21h
    call newline
    call newline
    
    call getArray
    mov dx, offset ChooseMsg  
    mov ah, 09h
    int 21h
    call newline
    mov dx, offset optionsMsg
    int 21h   
    call newline
    mov ah, 01h
    int 21h
            
    cmp al, 'a'
    jz gettingAvg
    cmp al, 's'
    jz gettingSum
    cmp al, 'm' 
    jz gettingminmax
    
    gettingAvg:
        call arrAvg
        jmp finishExec
    gettingSum:
        call arrSum
        jmp finishExec
    gettingminmax:
        call gettingMaxMin
        jmp finishExec
        
    finishExec:
        .exit
    
    
   
    .exit
    main endp
    
    
getArray proc near
    mov si, 0
    mov di, 0
    jmp get
    
    get:
    call getNum
    cmp enterPressCount, 02h ;if count = 2, exit getArray
    jz exitArray
    
    ; MISSING IMPLEMENTATION
    call calculateVal
    mov [arr + di], dx
    call incArrCounter  
    ; 2-storeNum procedure
    
    jmp get
    
    exitArray:
    ret
    
    getArray endp    
    

arrSum proc near
    ; Saving registers values
    push ax
    push si
    push cx
    
    ; Array summation function
    xor ax, ax
    xor si, si
    xor cx, cx
    
    repeat:
    cmp cx, length
    je exit
    jmp sumarr
    
    
    sumarr:
    mov dx, [arr + si]
    add sumResult, dx
    add si, 2 ; adding 2 since arr elements are words, 2 bytes.
    inc cx
    jmp repeat
            
    exit:
    ;Print result
    mov dx, offset summessage
    mov ah, 09h
    int 21h
    
    mov ax, sumResult
    call PRINT_NUM_UNS
    call newline
    
    ;Restoring registers values
    pop cx
    pop si
    pop ax
    
    
    ret
    arrSum endp

arrAvg proc near
    call arrSum 
    xor dx, dx 
    mov ax, sumResult
    mov bx, length
    div bx
    
    
    ; Printing result      
    push ax ; pushing ax, because ah will be changed

    mov dx, offset avgmessage
    mov ah, 09h
    int 21h 
    
    pop ax ;restoring ax value for printing
    
    CALL PRINT_NUM_UNS
    
    
    ret
    arrAvg endp   

    
incArrCounter proc near
   add di, 2
   inc length
   ret
   incArrCounter endp




; Steps
; 1- Get a char
; 2- Check if char is 0D (Enter key ascii code)
; 3- if yes, add si * 2 to SP so it doesn't get the char as return address
; 4- else, Push the char on stack
; 5- increment SI (num counter used for measuring num digits)
; 6- repeat 1-5
getNum proc near
   mov si, 0
   
   start:
   mov ah, 07h
   int 21h
   cmp al, 0Dh ;checking if al = enter
   je exitGetNum ; if yes exit
   jmp pushChar ;else save the ascii code on the stack
   
   pushChar:
   ; Checking if char in range 30h-39h (numbers in ascii)
   cmp al, 30h
   jl start
   cmp al, 39h
   jg start
   ; Print char if within range
   mov ah, 0Eh
   int 10h
   
   mov ah, 00h ;making the content of AX is only the char
   push ax
   inc si
   mov enterPressCount, 00h ;reset counter if a char is written not empty enter
   jmp start
   
   exitGetNum:
   call newline ; printing a new line
   mov ax, si ; moving digits count (si) to ax
   mov dl, 2
   mul dl ; multiplying ax by dl
   add sp, ax ; adding mul result to (sp) so it points at the correct return address
   inc enterPressCount
   ret  
   
   getNum endp


; Printing a newline on display
newline proc near
    push dx
    push ax
    LEA DX,n_line
    MOV AH,9
    INT 21H
    pop ax
    pop dx     
    ret
    newline endp
    



gettingMaxMin proc near
    push si
    mov cx, word ptr [length]
    sub cx, 01
    mov si, 02h
    mov ax, word ptr [arr+00h]
    jmp gettingMax
    printMax:
        mov ax, word ptr [max] 
        mov bx, 000Ah              
        mov cx, 0000h              

    First_Loop:
        mov dx, 0000h             
        div bx                 
        push dx                
        inc cx                  
        cmp ax, 0000h           
        jnz First_Loop          

        mov si, offset maxString         
    Second_Loop:
        pop ax                 
        add ax, 30h      
        mov byte ptr [si], al           
        inc si                  
        loop Second_Loop        

        mov byte [si], '$'
      
    mov dx, offset maxMessage
    mov ah, 09h 
    int 21h
    mov dx, offset maxString
    int 21h   
    jmp gettingMin
        
        
    gettingMax:
        cmp ax, word ptr [arr+ si]
        jl swap
        continueMax:
            add si, 02h
            loop gettingMax
            jmp finish
        swap: 
            mov ax, word ptr [arr+si]
            jmp continueMax
        
        finish:
           call newline
           mov word ptr [max], ax  
           jmp printMax
           
    gettingMin:
        mov cx, word ptr [length] ;getting the length of the array in cx for looping over it
        sub cx, 01h               ;decrement it by one because we assume that the first elemment is the smallest before iteration
        mov si, 02h               ;put 2 in the si for indexing reasons because each element of the array is of size WORD
        mov ax, [arr+00h]         ;put the first element in the ax thus assuming it's the smallest so far
        
        getMin:
            cmp ax, [arr+si]      ;compare ax which holds the assumed smallest to the next item of this iteration
            jg swapMin            ;if ax is greater than this element swap ax to that element
            continueMin:
                add si, 02h       ;increment the si by two for indexing reasons
                loop getMin       ;loop to check the next number of the array until the whole array is consumed
                jmp finishMin     ;if the cx hits zero which implies that the array is finished. and the minimum number is at ax
            swapMin:
                mov ax, word ptr [arr+si] ;put the next element of the array inside ax which means that for now this element is smaller than the assumed number
                jmp continueMin           ;continue the loop to consume the whole array
            
            finishMin:
                mov word ptr [min], ax ;saving the minimum number into memory
                mov bx, 000Ah          ;putting 10 in the bx to act as a divisor    
                mov cx, 0000h          ;putting cx to 0 to count the number of digits inside the number fot looping later    

                First_Loop_Min:
                    mov dx, 0000h      ;reseting the dx to zero to hold the reminder of the new division operation       
                    div bx             ;dividing the number by 10    
                    push dx            ;push the reminder of the division which is the Least Signifcant Digit in the number at the current iteration    
                    inc cx             ;increment the cx register to keep count of how many digits are in the number    
                    cmp ax, 0000h      ;if the number which is in ax has the value of zero that means that the number is done and all the digits have been divised already     
                    jnz First_Loop_Min ;if the ax isn't zero and thus the number still holds some value above zero divide by 10 again         

                mov si, offset minString   ;move the address of the char array with the purpose of saving each ASCII in a byte         
                Second_Loop_Min:           
                    pop ax                 ;pop the Most Segnificant Digit of the remaining ones and put it in ax
                    add ax, 30h            ;add 30H to that value to get the ASCII code
                    mov byte ptr [si], al  ;save that ASCII code in it's corresponding byte in the char array         
                    inc si                 ;increment the si to move to the next index in the array 
                    loop Second_Loop_Min   ;loop over until cx which holds the number of digits of the number hits zero     

                mov byte [si], '$'         ;store $ right after the last digit for printing reasons
                
                call newline
                mov dx, offset minMessage  ;put the address of the message inside dx for printing
                mov ah, 09h                ;put 09h in the ah for printing
                int 21h                    ;call the interrupt fot printing
                mov dx, offset minString   ;move the address of the minimum number's string inside dx for printing
                int 21h                    ;call the interrupt for printing 
                pop si                     ;return the same si that was saved after the call of this precedure
                ret                        ;return to MAIN
                 
        
        
            

gettingMaxMin endp

calculateVal proc near
    settingUp: ;setting up the register with the required valuse before looping
        ;Here, returning the sp to point at the top again, (last entered digit)
        mov ax, si ; moving digits count (si) to ax
        mov dl, 2
        mul dl ; multiplying ax by dl
        sub sp, ax
    
        mov cx, si ;to initiate the cx with si too loop over with the number of digits
        mov bx, 0000h ;to store the number's position among the digits
        mov dx, 0000h ; store the final results
        
    CALC: 
        pop ax ;getting the next digit off the stack
        sub ax, 30h ; converting the ASCII code to the corresponding number 
        push cx ;storing the number of iterations temporarly 
        push ax ;puting the number back into the stack to store temporarily 
        mov ax, 0000h ;for calculating the 10's power to get the digit\'s real value respectable to its position among the digits
        mov cx, bx ; to multiply 10 to itself according to the position of the number
        
        push dx
        gettingThepower:
            mov ax, 0001h
            cmp bx, 0000h ;if this is the first number in the iteration just return 1
            jnz doMulti
            jmp finishGettingPower
            doMulti:
                mul WORD PTR [num10] ;multiplie the calue in ax with 10 
                loop doMulti
            finishgettingPower: 
                pop dx
                pop cx ; getting the digit
                push dx  
                mul cx ; multiply the digits to the power of 10 of it's position to calculate its value with respect to its position 
        pop dx        
        add dx, ax ; add the number with it's value to the dx for getting the final results 
        pop cx ; to get the original number of iterations
        inc bx ; to go to the next position 
        loop CALC
        
        ret

calculateVal endp

end main

