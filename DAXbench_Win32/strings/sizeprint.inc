;---------- Print memory block size as Integer.Float ----------;
; Float part is 1 char, use P1-version of Floating Print       ;
; If rounding precision impossible, print as hex               ;
; Only x.5 floating values supported, otherwise as hex         ;
;                                                              ;
; INPUT:   EAX = Number value, units = Bytes                   ;
;          BL  = Force units (override as smallest only)       ;
;                FF = No force units, auto select              ;
;                0 = Bytes, 1 = KB, 2 = MB, 3 = GB, 4 = TB     ;
;          EDI = Destination Pointer (flat)                    ;
; OUTPUT:  EDI = New Destination Pointer (flat)                ;
;                modified because string write                 ;
;--------------------------------------------------------------;
SizePrint32:
cld
push eax ebx ecx edx esi
bsf ecx,eax

mov bh,0                    ; BH=0 means BYTES
cmp cl,8
jbe .L3                     ; Bits[0-8] handled as bytes print
cmp bh,bl
je .L3                      ; Go if force BYTES

mov bh,1                    ; BH=1 means KILOBYTES
shr eax,10
cmp cl,9
je .L4                      ; Bit[9] handled as KB print with ".5" 
cmp cl,18
jbe .L3                     ; Bits[10-18] handled as KB print with ".0" 
cmp bh,bl
je .L3                      ; Go if force KILOBYTES

mov bh,2                    ; BH=2 means MEGABYTES
shr eax,10
cmp cl,19 
je .L4                      ; Bit[19] handled as MB print with ".5" 
cmp cl,28
jbe .L3                     ; Bits[20-28] handled as MB print with ".0"
cmp bh,bl
je .L3                      ; Go if force MEGABYTES

mov bh,3                    ; BH=3 means GIGABYTES
shr eax,10
cmp cl,29 
je .L4                      ; Bit[29] handled as GB print with ".5" 
cmp cl,38
jbe .L3                     ; Bits[30-38] handled as GB print with ".0" 
cmp bh,bl
je .L3                      ; Go if force GIGABYTES
                            ; Otherwise as GB print with ".0"

;--- Entry point for common units with 1/2 float part, fixed as ".5" ---
.L4:
mov dl,5                    ; For this print mode, value fixed ".5"
jmp .L30
;--- Entry point for common units without float part, fixed as ".0" ---
.L3:
mov dl,0                    ; For this print mode, value fixed ".0"
.L30:
test bh,bh
jz .L2                      ; Go print as bytes (not float) if low bits set
mov bl,0
call DecimalPrint32         ; Print 32-bit decimal integer: number of Units
mov al,'.'
stosb                       ; Decimal point before fixed "0"
movzx eax,dl                ; For this print mode, value fixed ".0" or ".5"
jmp .L20
;--- Entry point for print as BYTES ---
.L2:
cmp eax,1
jne .L20
mov bh,5                    ; Must write "1 Byte" instead "1 Bytes"
.L20:
mov bl,0                    ; BL = Template mode, 0 = no template
call DecimalPrint32         ; Print 32-bit decimal integer: number of Bytes
mov al,' '
stosb
lea esi,[U_B]               ; ESI = Pointer to table with units names
mov al,bh                   ; AL = String selector
mov ah,5                    ; AH = String selector limit
call StringWriteSelected    ; Print units: Bytes/Byte/KB/MB/GB/TB
;--- Exit ---
.L0:
pop esi edx ecx ebx eax
ret

