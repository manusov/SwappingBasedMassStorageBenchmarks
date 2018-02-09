;--- String write for errors messages ---------;
; INPUT:  AL = Error code selector, 0-based    ;
; OUTPUT: EAX = OS Status                      ;
;----------------------------------------------;
ErrorStringWrite:
cmp al,0
je ErrorWrite
SkipStrings:
cmp byte [ecx],0
je NextString
inc ecx
jmp SkipStrings
NextString:
dec al
jnz SkipStrings  
inc ecx
;---
ErrorWrite:
push ecx
lea ecx,[CrLf]
call ConsoleStringWrite
pop ecx
call ConsoleStringWrite
lea ecx,[CrLf]
; No RET, continue in the next subroutine

;--- String write in ASCII --------------------;
; INPUT:  ECX = Pointer to string              ;
;         ASCII string at ECX memory address   ;
;         string is null-terminated            ;
;         also global variables used           ;
; OUTPUT: EAX = OS Status                      ;
;----------------------------------------------;
ConsoleStringWrite:
;--- Entry ---
push ebp 0                    ; EBP = non-volatile, 0 = for storage
mov ebp,esp                   ; EBP = storage for ESP and pointer to frame
;--- Calculate string length ---
xor eax,eax                   ; EAX = Number of chars
@@:
cmp byte [ecx+eax],0          ; Check current char from string
je @f                         ; Exit cycle if terminator (byte=0) found
inc eax                       ; Chars counter + 1
jmp @b                        ; Go next iteration
@@:
;--- Write console ---
push 0                        ; Parm#5 = Reserved
push ebp                      ; Parm#4 = Pointer to out. variable, count
push eax                      ; Parm#3 = Number of chars 
push ecx                      ; Parm#2 = Pointer to string
push [OutputDevice]           ; Parm#1 = Input device handle 
call [WriteConsole]           ; Display output
;--- Exit ---
pop ebp ebp
ret

;---------------------- Win64 console functions notes -------------------------;
; Used functions:
;
; GetStdHandle
; Input:  Parm#1 = Handle type code for retrieve
; Output: EAX = Handle, if error 0 or INVALID_HANDLE_VALUE 
;
; WriteConsole
; Input:  Parm#1 = Handle of output device
;         Parm#2 = Pointer to buffer
;         Parm#3 = Number of characters to write
;         Parm#4 = Pointer to returned number of successfully chars write
;         Parm#5 = Reserved parameters must be 0 (NULL)
; Output: Status, Nonzero=OK, 0=Error 
;
; ReadConsole
; Input:  Parm#1 = Handle of input device
;         Parm#2 = Pointer to buffer
;         Parm#3 = Number of chars to read (limit, but not for edit)
;         Parm#4 = Pointer to returned number of cars read (before ENTER)
;         Parm#5 = Pointer to CONSOLE_READCONSOLE_CONTROL structure, 0=None
; Output: Status, Nonzero=OK, 0=Error
;
; ExitProcess
; Input:  Parm#1 = Exit code for parent process
; No output, because not return control to caller
;
;------------------------------------------------------------------------------;
