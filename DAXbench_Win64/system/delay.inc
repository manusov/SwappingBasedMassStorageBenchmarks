; THIS SUBROUTINE DEPRECATED.
; USE WINAPI [Sleep], TO MINIMIZE CPU UTILIZATION AND SIMPLEST METHOD.  

;------------------------------------------------------------------------;
; Make time delay                                                        ;
;                                                                        ;
; INPUT:   EAX = Delay value, seconds                                    ;
; OUTPUT:  None                                                          ;
;          EAX, EDX corrupted                                            ;
;------------------------------------------------------------------------;
SecondsDelay:
cld                         ; Clear direction, because STOSQ used
push rbx rcx rsi rbp r8 r9 r10 r11 rax	 ; R8-R11 because API, RAX = Variable
mov ebx,eax                 ; EBX = Delay value
mov rbp,rsp                 ; RBP used for restore RSP and variables addr.
and rsp,0FFFFFFFFFFFFFFF0h  ; Align stack (16)
sub rsp,32                  ; Make parameters shadow
;--- Synchronization, wait toggle ---
mov rcx,rbp
call [GetSystemTimeAsFileTime]  ; Get current count
mov rsi,[rbp]
@@:
mov rcx,rbp
call [GetSystemTimeAsFileTime]  ; Get next count for wait 100 ns
cmp rsi,[rbp]
je @b
;--- Seconds cycle ---
.L0:
;--- Start time point ---
mov rsi,[rbp]
add rsi,10000000                ; RSI = 10^7 * 100ns = 1 second
;--- Delay 1 second ---
@@:
mov rcx,rbp
call [GetSystemTimeAsFileTime]  ; Get count for wait 1 second
cmp rsi,[rbp]                   ; Compare target=rsi and returned=[rbp] 
ja @b                           ; Go wait if target > returned, must 1 second
;--- Stop time point ---
dec ebx
jnz .L0
;--- Restore RSP, pop extra registers, exit ---
mov rsp,rbp                            ; Restore RSP after align. and shadow
pop rbx r11 r10 r9 r8 rbp rsi rcx rbx  ; First POP RBX for RSP-8 only 
ret

