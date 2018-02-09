;---------- Parse unsigned integer string ------------------------;
;                                                                 ;
; INPUT:   ESI = Source ASCII text string address                 ;
;          ECX = String size limit                                ;
; OUTPUT:  CF = Error flag: 0(NC) = No errors, parsed OK          ;
;                           1(C)  = Error, invalid value          ;  
;          EAX = Extracted numeric value, valid only if CF=0(NC)  ;
;-----------------------------------------------------------------;
StringReadInteger:
cld
push ebx ecx esi edi
;--- Remove left spaces ---
@@:
lodsb
cmp al,' '
loope @b
jecxz .Error
;--- Set numer start ---
dec esi
mov edi,esi
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
dec esi
dec esi
;--- Check extracted ASCII number length, EDI = First digit, ESI = Last ---  
mov eax,esi
sub eax,edi
jb .Error
cmp eax,9
ja .Error
;--- Calculate extracted number, EDI = First digit char, ESI = Last ---
xchg esi,edi
xor ebx,ebx
@@:
imul ebx,ebx,10
lodsb
and eax,0Fh
add ebx,eax
cmp esi,edi
jbe @b
xchg eax,ebx
;--- Exit points ---
clc
.Exit:
pop edi esi ecx ebx
ret
.Error:
stc
jmp .Exit
