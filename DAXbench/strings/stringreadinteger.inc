;---------- Parse unsigned integer string ------------------------;
;                                                                 ;
; INPUT:   RSI = Source ASCII text string address                 ;
;          RCX = String size limit                                ;
; OUTPUT:  CF = Error flag: 0(NC) = No errors, parsed OK          ;
;                           1(C)  = Error, invalid value          ;  
;          RAX = Extracted numeric value, valid only if CF=0(NC)  ;
;-----------------------------------------------------------------;
StringReadInteger:
cld
push rbx rcx rsi rdi
;--- Remove left spaces ---
@@:
lodsb
cmp al,' '
loope @b
jrcxz .Error
;--- Set numer start ---
dec rsi
mov rdi,rsi
;--- Detect number stop ---
@@:
lodsb
cmp al,0
je @f
cmp al,' '
je @f
cmp al,'0'
jb .Error
cmp al,'9'
ja .Error
loop @b
@@:
dec rsi
dec rsi
;--- Check extracted ASCII number length, RDI = First digit, RSI = Last ---  
mov rax,rsi
sub rax,rdi
;- jbe .Error
jb .Error
;-
cmp rax,9
ja .Error
;--- Calculate extracted number, RDI = First digit char, RSI = Last ---
xchg rsi,rdi
xor ebx,ebx
@@:
imul rbx,rbx,10
lodsb
and eax,0Fh
add rbx,rax
cmp rsi,rdi
jbe @b
xchg rax,rbx
;--- Exit points ---
clc
.Exit:
pop rdi rsi rcx rbx
ret
.Error:
stc
jmp .Exit
