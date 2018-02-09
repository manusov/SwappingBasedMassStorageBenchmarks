;==============================================================================;
;                                                                              ;
;         DAX-optimized benchmarks for memory mapping files swapping.          ;
;                          (engineering release).                              ;
;                        Win64 Edition, NUMA aware.                            ; 
;                           (C)2018 IC Book Labs.                              ;
;                                                                              ;
;  This file is main module: translation object, interconnecting all modules.  ;
;                                                                              ;
;        Translation by Flat Assembler version 1.72 (Oct 10, 2017)             ;
;           Visit http://flatassembler.net/ for more information.              ;
;           For right tabulations, please edit by FASM Editor 2.0              ;
;                                                                              ;
;==============================================================================;

format PE64 console
entry start
include 'win64a.inc'

;========== Code section ======================================================;

section '.code' code readable executable
start:

;---------- 32 byte parameters shadow and +8 alignment ------------------------;

sub rsp,8*5

;---------- Initializing console input-output ---------------------------------;

mov ecx,STD_INPUT_HANDLE    ; Parm#1 = RCX = Handle ID       
call [GetStdHandle]         ; Initializing input device handle (keyboard)
test rax,rax
jz ExitProgram              ; Silent exit if get input handle failed
mov [InputDevice],rax
mov ecx,STD_OUTPUT_HANDLE   ; Parm#1 = RCX = Handle ID    
call [GetStdHandle]         ; Initializing output device handle (display)
test rax,rax
jz ExitProgram              ; Silent exit if get output handle failed
mov [OutputDevice],rax
lea rcx,[ProductID]         ; Parm#1 = RCX = Pointer to string for output         
call ConsoleStringWrite     ; Visual first message
call [GetCommandLineA]      ; Get command line
test rax,rax
jz ExitProgram              ; Silent exit if get command line failed

;---------- Extract command line parameters as strings ------------------------;

cld
xchg rsi,rax                ; RSI = Pointer to command line string
mov ecx,132                 ; Skip this program name
call ScanForSpace
cmp al,' '
jne DefaultMode             ; Go if command line parameters absent
call SkipExtraSpaces        ; Skip extra spaces
cmp al,0
je DefaultMode              ; Go if command line parameters absent 

lea rdi,[Parameter1]        ; Extract first parameter = file name   
call ExtractParameter
cmp al,0
je ErrorCmdLine
call SkipExtraSpaces        ; Skip extra spaces
cmp al,0
je ErrorCmdLine 

lea rdi,[Parameter2]        ; Extract second parameter = file size, MB
call ExtractParameter
cmp al,0                    ; This used if extra parameters is error
je ErrorCmdLine    
call SkipExtraSpaces        ; Skip extra spaces
cmp al,0
je ErrorCmdLine 

lea rdi,[Parameter3]        ; Extract third parameter = NUMA domain number
call ExtractParameter
cmp al,0                    ; This used if extra parameters is error
je ErrorCmdLine    
call SkipExtraSpaces        ; Skip extra spaces
cmp al,0
je ErrorCmdLine 

lea rdi,[Parameter4]        ; Extract forth parameter = Logical CPU number
call ExtractParameter
cmp al,0                    ; This used if extra parameters is error
jne ErrorCmdLine

jmp VisualPrimary           ; Jump over default mode

;---------- Support default mode for parameters absent in the command line ----;

DefaultMode:

lea rcx,[CmdLineEmpty]
call ConsoleStringWrite     ; Output warning if run without parameters
lea rax,[DefaultPath]
mov [UsedPath],rax          ; Set path = default path
mov rax,[DefaultSize]
mov [UsedSize],rax          ; set size = default size
mov rax,[DefaultNUMA]
mov [UsedNUMA],rax          ; set NUMA domain = default NUMA domain
mov rax,[DefaultCPU]
mov [UsedCPU],rax           ; set CPU affinity = default CPU affinity

lea rcx,[Interpreted1]
call ConsoleStringWrite
mov rcx,[UsedPath]
call ConsoleStringWrite     ; Additional visual interpreted value, for debug

lea rcx,[Interpreted2]
call ConsoleStringWrite
lea rdi,[TextBuffer]        ; RDI = Pointer to destination transit buffer
mov rax,[UsedSize]          ; RAX = size in bytes
mov bl,0FFh                 ; BL = 0FFh means units auto-select
call SizePrint64
mov al,0
stosb
lea rcx,[TextBuffer]
call ConsoleStringWrite     ; Additional visual interpreted value, for debug

lea rcx,[Interpreted3]
call ConsoleStringWrite
lea rdi,[TextBuffer]        ; RDI = Pointer to destination transit buffer
mov eax,dword [UsedNUMA]    ; EAX = NUMA domain number
mov bl,0                    ; BL = 0 means template auto-select
call DecimalPrint32
mov al,0
stosb
lea rcx,[TextBuffer]
call ConsoleStringWrite     ; Additional visual interpreted value, for debug

lea rcx,[Interpreted4]
call ConsoleStringWrite
lea rdi,[TextBuffer]        ; RDI = Pointer to destination transit buffer
mov eax,dword [UsedCPU]     ; EAX = CPU number
mov bl,0                    ; BL = 0 means template auto-select
call DecimalPrint32
mov al,0
stosb
lea rcx,[TextBuffer]
call ConsoleStringWrite     ; Additional visual interpreted value, for debug

jmp RunTest

;---------- Visual command line parameters as strings -------------------------;

VisualPrimary:

lea rcx,[ParmName1]         ; Visual parameter 1 string = File path
call ConsoleStringWrite
lea rcx,[Parameter1]
call ConsoleStringWrite

lea rcx,[ParmName2]         ; Visual parameter 2 string = File size, MB
call ConsoleStringWrite
lea rcx,[Parameter2]
call ConsoleStringWrite

lea rcx,[ParmName3]         ; Visual parameter 3 string = NUMA domain number
call ConsoleStringWrite
lea rcx,[Parameter3]
call ConsoleStringWrite

lea rcx,[ParmName4]         ; Visual parameter 4 string = Logical CPU number
call ConsoleStringWrite
lea rcx,[Parameter4]
call ConsoleStringWrite

;---------- Interpreting and visual parameter #1 = file path ------------------; 

lea rax,[Parameter1]
mov [UsedPath],rax          ; Assign operational value: pointer to path
lea rcx,[Interpreted1]
call ConsoleStringWrite
mov rcx,[UsedPath]
call ConsoleStringWrite     ; Additional visual interpreted value, for debug

;---------- Interpreting and visual parameter #2 = file size ------------------;

lea rsi,[Parameter2]
call StringReadInteger
jc ErrorCmdLine
imul rax,rax,1024*1024       ; Convert from megabytes to bytes
mov [UsedSize],rax           ; Assign operational value: size in bytes
lea rcx,[Interpreted2]
call ConsoleStringWrite
lea rdi,[TextBuffer]         ; RDI = Pointer to destination transit buffer
mov rax,[UsedSize]           ; RAX = size in bytes
mov bl,0FFh                  ; BL = 0FFh means units auto-select
call SizePrint64
mov al,0
stosb
lea rcx,[TextBuffer]
call ConsoleStringWrite     ; Additional visual interpreted value, for debug

;---------- Interpreting and visual parameter #3 = NUMA domain number ---------;

lea rsi,[Parameter3]
call StringReadInteger
jc ErrorCmdLine
mov [UsedNUMA],rax
lea rcx,[Interpreted3]
call ConsoleStringWrite
lea rdi,[TextBuffer]        ; RDI = Pointer to destination transit buffer
mov eax,dword [UsedNUMA]    ; EAX = NUMA domain number
mov bl,0                    ; BL = 0 means template auto-select
call DecimalPrint32
mov al,0
stosb
lea rcx,[TextBuffer]
call ConsoleStringWrite     ; Additional visual interpreted value, for debug

;---------- Interpreting and visual parameter #4 = Thread ideal processor -----;

lea rsi,[Parameter4]
call StringReadInteger
jc ErrorCmdLine
mov [UsedCPU],rax
lea rcx,[Interpreted4]
call ConsoleStringWrite
lea rdi,[TextBuffer]        ; RDI = Pointer to destination transit buffer
mov eax,dword [UsedCPU]     ; EAX = CPU number
mov bl,0                    ; BL = 0 means template auto-select
call DecimalPrint32
mov al,0
stosb
lea rcx,[TextBuffer]
call ConsoleStringWrite     ; Additional visual interpreted value, for debug


;=== WRITE PHASE === 

RunTest:

;---------- Delay before WRITE ------------------------------------------------;

lea rcx,[CrLf2]
call ConsoleStringWrite
lea rcx,[TraceWriteDelay]
call ConsoleStringWrite

mov ecx,40*1000   ; Parm#1 = sleep time, milliseconds, note RCX[63-32] cleared
call [Sleep]      ; This method is simplest and minimum CPU utilization

;---------- Create file -------------------------------------------------------;

lea rcx,[TraceInitWrite]
call ConsoleStringWrite

lea r15,[StepCreateW]                  ; R15 = Step name for errors handling
xor r14d,r14d                          ; R14 = 0, means get status from OS 
mov rcx,[UsedPath]                     ; RCX = Parm#1 = Pointer to file path
mov edx,GENERIC_READ OR GENERIC_WRITE  ; RDX = Parm#2 = Desired access
xor r8d,r8d                            ; R8  = Parm#3 = Share mode = 0
xor r9d,r9d                            ; R9  = Parm#4 = Security attributes = 0
push r9                                ; This for stack alignment
push r9                                ; Parm#7 = Template file handle, not used 
push qword [FileFlags]                 ; Parm#6 = File attribute and flags
push CREATE_ALWAYS                     ; Parm#5 = Creation disposition
sub rsp,32                             ; Make stack frame
call [CreateFileA]
add rsp,32+32                ; Remove stack frame and input parameters
test rax,rax                 ; Check RAX = Handle
jz ErrorProgram              ; Go if error create file
xchg rbx,rax                 ; RBX = File Handle

;---------- Create mapping object for file ------------------------------------;

lea r15,[StepMapW]           ; R15 = Step name for errors handling
; Get thread handle
xor r14d,r14d                ; R14 = 0, means get status from OS
call [GetCurrentThread]
test rax,rax
jz ErrorProgram
mov [ThreadHandle],rax

; Set Thread Ideal Processor (required affinity settings for NUMA node)
mov rcx,rax  ; [ThreadHandle]
mov edx,dword [UsedCPU]
call [SetThreadIdealProcessor]
cmp rax,-1
je ErrorProgram

; Get handle for KERNEL32.DLL
lea rcx,[NameKernel32]       ; RCX = Parm#1 = Pointer to module name string
call [GetModuleHandle]       ; RAX = Return module handle
test rax,rax
jz ErrorProgram

; Get function pointer
mov rcx,rax                  ; RCX = Parm#1 = Module handle
lea rdx,[NameFunction]       ; RDX = Parm#2 = Pointer to function name
call [GetProcAddress]        ; RAX = Return function address
test rax,rax
jz ErrorProgram
mov [Function_CreateFileMappingNumaA],rax

; Call NUMA-oriented mapping function
xor eax,eax                  ; Entire RAX = 0
push rax                     ; Not existed parm #8 for alignment
push [UsedNUMA]              ; Parm#7 = NUMA domain number
push rax                     ; Parm#6 = Name of mapped object, NULL = no name  
mov eax,dword [UsedSize+0]
push rax                     ; Parm#5 = Mapped file size, low 32-bit
mov r9d,dword [UsedSize+4]   ; Parm#4 = Mapped file size, high 32-bit 
mov r8d,PAGE_READWRITE       ; Parm#3 = Memory page protection attribute
xor edx,edx                  ; Parm#2 = Security attributes, not used (NULL)
mov rcx,rbx                  ; Parm#1 = File handle
sub rsp,32                   ; Create stack frame
call [Function_CreateFileMappingNumaA]
add rsp,32+32                ; Remove stack frame and 4 parameters
test rax,rax
jz ErrorProgram              ; Go if error create mapping object
xchg rbp,rax                 ; RBP = Mapping File Object Handle 

;---------- Allocate mapping object at application memory ---------------------;

lea r15,[StepViewW]          ; R15 = Step name for errors handling
xor r14d,r14d                ; R14 = 0, means get status from OS (already 0) 
xor eax,eax                  ; Entire RAX = 0
push rax                     ; This empty parameter #6 for stack alignment
mov rax,[UsedSize]
push rax                     ; Parm#5 = Size of mapping object
xor r9d,r9d                  ; Parm#4 = Offset in the mapped file, low 32-bit 
xor r8d,r8d                  ; Parm#3 = Offset in the mapped file, high 32-bit
mov edx,FILE_MAP_ALL_ACCESS  ; Parm#2 = Access, enable Read and Write
mov rcx,rbp                  ; Parm#1 = Mapping File Object Handle 
sub rsp,32                   ; Create stack frame
call [MapViewOfFile]
add rsp,32+16                ; Remove stack frame and 2 parameters
test rax,rax
jz ErrorProgram              ; Go if mapping error
xchg rsi,rax                 ; RSI = Mapping Object Linear Virtual Address

;---------- Fill buffer for make swapping request -----------------------------; 

lea r15,[StepModifyW]        ; R15 = Step name for errors handling, R14 still 0
cld                          ; Increment mode for string instructions
mov rdi,rsi                  ; RDI = Destination pointer for write array
mov rcx,[UsedSize]
shr rcx,3                    ; RCX = Number of 64-bit quad words
mov rax,'    DATA'           ; RAX = Pattern for write array 
rep stosq                    ; Write array

;---------- Message about WRITE with debug dump -------------------------------;

push rdi
mov rax,rbx
lea rdi,[TWD1]
call HexPrint64
mov rax,rbp
lea rdi,[TWD2]
call HexPrint64
mov rax,rsi
lea rdi,[TWD3]
call HexPrint64
lea rax,[rsi-1]
add rax,[UsedSize] 
lea rdi,[TWD4]
call HexPrint64
lea rcx,[TraceWriteDump]
call ConsoleStringWrite
pop rdi

;---------- Flush buffer (write to disk) with time measurement ----------------;

lea r15,[StepFlushW]         ; R15 = Step name for errors handling, R14 still 0
;--- Start time ---
xor eax,eax                     ; Entire RAX = 0
push rax                        ; Create variable for update by function
mov rcx,rsp                     ; Parm#1 = Pointer to updated variable (time)
push rax                        ; This qword for stack alignment 
sub rsp,32                      ; Create stack frame
call [GetSystemTimeAsFileTime]  ; Update variable time stamp, units = 100 ns
add rsp,32+8                    ; Remove stack frame and alignment variable
pop r13                         ; R13 = Returned time stamp value, before op.

;--- Target measured operation ---
mov rcx,rsi                    ; Parm#1 = Mapping Object Linear Virtual Address 
mov rdx,[UsedSize]             ; Parm#2 = Size of flushed region
call [FlushViewOfFile]
test rax,rax
jz ErrorProgram                 ; Go if flush operation error
;--- End measured time ---

xor eax,eax                     ; Entire RAX = 0
push rax                        ; Create variable for update by function
mov rcx,rsp                     ; Parm#1 = Pointer to updated variable (time)
push rax                        ; This qword for stack alignment
sub rsp,32                      ; Create stack frame
call [GetSystemTimeAsFileTime]  ; Update variable time stamp, units = 100 ns
add rsp,32+8                    ; Remove stack frame and alignment variable
pop r12                         ; R12 = Returned time stamp value, after op.
;--- Delta time = T_after - T_before ---
sub r12,r13                     ; R12 = Time interval, units = 100 ns
mov [ResultWrite],r12           ; Save result for WRITE

;---------- Close mapping object ----------------------------------------------;

lea r15,[StepCloseMapW]    ; R15 = Step name for errors handling, R14 still 0
mov rcx,rbp                ; Parm#1 = Mapping File Object Handle
call [CloseHandle]
test rax,rax
jz ErrorProgram            ; Go if close mapping object error

;---------- Close file --------------------------------------------------------;

lea r15,[StepCloseFileW]   ; R15 = Step name for errors handling, R14 still 0
mov rcx,rbx                ; Parm#1 = File handle
call [CloseHandle]
test rax,rax
jz ErrorProgram            ; Go if close file error

;---------- Unmap view of file ------------------------------------------------;
; This step added at v0.02, otherwise cannot delete file with access denied

lea r15,[StepUnmapW]       ; R15 = Step name for errors handling, R14 still 0
mov rcx,rsi                ; Parm#1 = Base virtual address of unmapped range
call [UnmapViewOfFile]
test rax,rax
jz ErrorProgram            ; Go if unmap operation error


;=== READ PHASE ===

;---------- Delay before READ -------------------------------------------------;

lea rcx,[TraceReadDelay]
call ConsoleStringWrite

mov ecx,40*1000   ; Parm#1 = sleep time, milliseconds, note RCX[63-32] cleared
call [Sleep]      ; This method is simplest and minimum CPU utilization

;---------- Open file ---------------------------------------------------------;

lea rcx,[TraceInitRead]
call ConsoleStringWrite

lea r15,[StepOpenR]                    ; R15 = Step name for errors handling
xor r14d,r14d                          ; R14 = 0, means get status from OS 
mov rcx,[UsedPath]                     ; RCX = Parm#1 = Pointer to file path
mov edx,GENERIC_READ OR GENERIC_WRITE  ; RDX = Parm#2 = Desired access
xor r8d,r8d                            ; R8  = Parm#3 = Share mode = 0
xor r9d,r9d                            ; R9  = Parm#4 = Security attributes = 0
push r9                                ; This for stack alignment
push r9                                ; Parm#7 = Template file handle, not used 
push qword [FileFlags]                 ; Parm#6 = File attribute and flags
push OPEN_ALWAYS ; CREATE_ALWAYS       ; Parm#5 = Creation disposition
sub rsp,32
call [CreateFileA]
add rsp,32+32                ; Remove stack frame and 2 parameters
test rax,rax                 ; Check RAX = Handle
jz ErrorProgram              ; Go if error create file
xchg rbx,rax                 ; RBX = File Handle

;---------- Create mapping object for file ------------------------------------;

lea r15,[StepMapR]           ; R15 = Step name for errors handling
xor r14d,r14d                ; R14 = 0, means get status from OS (already 0) 

; Call NUMA-oriented mapping function
xor eax,eax                  ; Entire RAX = 0
push rax                     ; Not existed parm #8 for alignment
push [UsedNUMA]              ; Parm#7 = NUMA domain number
push rax                     ; Parm#6 = Name of mapped object, NULL = no name  
mov eax,dword [UsedSize+0]
push rax                     ; Parm#5 = Mapped file size, low 32-bit
mov r9d,dword [UsedSize+4]   ; Parm#4 = Mapped file size, high 32-bit 
mov r8d,PAGE_READWRITE       ; Parm#3 = Memory page protection attribute
xor edx,edx                  ; Parm#2 = Security attributes, not used (NULL)
mov rcx,rbx                  ; Parm#1 = File handle
sub rsp,32                   ; Create stack frame
call [Function_CreateFileMappingNumaA]
add rsp,32+32                ; Remove stack frame and 4 parameters
test rax,rax
jz ErrorProgram              ; Go if error create mapping object
xchg rbp,rax                 ; RBP = Mapping File Object Handle 

;---------- Allocate mapping object at application memory ---------------------;

lea r15,[StepViewR]          ; R15 = Step name for errors handling, R14 still 0
xor eax,eax                  ; Entire RAX = 0
push rax                     ; This empty parameter #6 for stack alignment
mov rax,[UsedSize]
push rax                     ; Parm#5 = Size of mapping object
xor r9d,r9d                  ; Parm#4 = Offset in the mapped file, low 32-bit
xor r8d,r8d                  ; Parm#3 = Offset in the mapped file, high 32-bit
mov edx,FILE_MAP_ALL_ACCESS  ; Parm#2 = Access, enable Read and Write
mov rcx,rbp                  ; Parm#1 = Mapping File Object Handle
sub rsp,32                   ; Create stack frame
call [MapViewOfFile]
add rsp,32+16                ; Remove stack frame and 2 parameters
test rax,rax
jz ErrorProgram              ; Go if mapping error
xchg rsi,rax                 ; RSI = Mapping Object Address

;---------- Message about READ with debug dump --------------------------------;

push rdi
mov rax,rbx
lea rdi,[TRD1]
call HexPrint64
mov rax,rbp
lea rdi,[TRD2]
call HexPrint64
mov rax,rsi
lea rdi,[TRD3]
call HexPrint64
lea rax,[rsi-1]
add rax,[UsedSize] 
lea rdi,[TRD4]
call HexPrint64
lea rcx,[TraceReadDump]
call ConsoleStringWrite
pop rdi

;---------- Memory read for make swapping request, measure time ---------------;

lea r15,[StepLoadR]          ; R15 = Step name for errors handling, R14 still 0
;--- Start time ---
xor eax,eax                     ; Entire RAX = 0
push rax                        ; Create variable for update by function
mov rcx,rsp                     ; Parm#1 = Pointer to updated variable (time)
push rax                        ; This qword for stack alignment
sub rsp,32                      ; Create stack frame
call [GetSystemTimeAsFileTime]  ; Return time stamp, units = 100 ns
add rsp,32+8                    ; Remove stack frame and alignment variable
pop r13                         ; R13 = Returned time stamp value, before op.

;--- Target measured operation ---
mov rdi,rsi                 ; RDI = Pointer to mapped region
mov rcx,[UsedSize]          ; RCX = Mapped File size
shr rcx,9                   ; Convert to 512-byte units
xor eax,eax                 ; Pre-clear RAX
@@:
add eax,[rdi]   ; Load memory mapped file, ADD(not MOV) to prevent speculative
add rdi,512     ; Granularity = 1 minimal sector, minimum for swapping occured 
dec rcx
jnz @b
;--- End measured time ---

xor eax,eax                     ; Entire RAX = 0
push rax                        ; Create variable for update by function
mov rcx,rsp                     ; Parm#1 = Pointer to updated variable (time)
push rax                        ; This qword for stack alignment
sub rsp,32                      ; Create stack frame
call [GetSystemTimeAsFileTime]  ; Update variable time stamp, units = 100 ns
add rsp,32+8                    ; Remove stack frame and alignment variable
pop r12                         ; R12 = Returned time stamp value, after op.
;--- Delta time = T_after - T_before ---
sub r12,r13                     ; R12 = Time interval, units = 100 ns
mov [ResultRead],r12            ; Save result for READ

;---------- Close mapping object ----------------------------------------------;

lea r15,[StepCloseMapR]    ; R15 = Step name for errors handling, R14 still 0
mov rcx,rbp                ; Parm#1 = Mapping File Object Handle
call [CloseHandle]
test rax,rax
jz ErrorProgram            ; Go if close mapping object error

;---------- Close file --------------------------------------------------------;

lea r15,[StepCloseFileR]   ; R15 = Step name for errors handling, R14 still 0
mov rcx,rbx                ; Parm#1 = File handle
call [CloseHandle]
test rax,rax
jz ErrorProgram            ; Go if close file error

;---------- Unmap view of file ------------------------------------------------;
; This step added at v0.02, otherwise cannot delete file with access denied

lea r15,[StepUnmapR]       ; R15 = Step name for errors handling, R14 still 0
mov rcx,rsi                ; Parm#1 = Base virtual address of unmapped range
call [UnmapViewOfFile]
test rax,rax
jz ErrorProgram            ; Go if unmap operation error

;---------- Delete file -------------------------------------------------------;
; This step added at v0.02, only possible if file unmapped

lea r15,[StepDeleteFileR]  ; R15 = Step name for errors handling, R14 still 0
mov rcx,[UsedPath]         ; RCX = Parm#1 = Pointer to file path
call [DeleteFile]
test rax,rax
jz ErrorProgram           ; Go if delete operation error


;=== CALCULATIONS PHASE ===

lea rcx,[TraceBuildResult]
call ConsoleStringWrite

;---------- Detect x87 FPU ----------------------------------------------------;

lea r15,[StepFPU]
mov r14d,1             ; R14 = 1, means status code for this step
call CheckCpuId
jc ErrorProgram        ; Go if CPUID not supported, for example some virtual m.
cmp eax,1
jb ErrorProgram        ; Go if CPUID function 1 not supported
mov eax,1              ; CPUID function 1, get base features
cpuid
test dl,00000001b
jz ErrorProgram         ; Go if x87 FPU absent

;---------- Calculate disk read and write speed -------------------------------;

finit                 ; Initialize x87 FPU
fild [ConstK100]      ; ST0 = 1024*100
fild [UsedSize]       ; ST0 = file size , ST1 = 1024*100
fild [WinSeconds]     ; ST0 = 10000000 , ST1 = file size , ST2 = 1024*100

lea r15,[StepCalc]
xor r14d,r14d         ; R14 = 0, prepare for cycle
lea rbx,[ResultRead]  ; RBX = Pointer to 2 results: Read and Write
@@:                   ; cycle for 2 items, interval input units = 100 ns
inc r14d              ; R14 = 1(4), means status code for this step/sub step
mov rax,[rbx]
test rax,rax
jz ErrorProgram       ; Go error if time interval zero
inc r14d              ; R14 = 2(5), means status code for this step/sub step
test rax,rax
js ErrorProgram       ; Go error if time interval negative
inc r14d              ; R14 = 3(6), means too big result
fild qword [rbx]      ; ST0 = time interval, ST1,ST2,ST3 = shifted ST0,ST1,ST2
fdiv st0,st1          ; ST0 = Seconds
fdivr st0,st2         ; ST0 = Bytes per second
fdiv st0,st3          ; ST0 = Units per second, unit = 100KB
fistp qword [rbx]     ; Write FPU result to variable, 100KB units per second
cmp qword [rbx],10000000
jae ErrorProgram      ; Go error if unexcepted high speed
add rbx,8             ; Next variable from 2
cmp r14,6
jb @b                 ; Cycle for 2 items: load (read) and store (write) 

;---------- Prepare text strings for show -------------------------------------;

lea rsi,[ResultPhaseString]  ; RSI = Pointer to parameter name
lea rdi,[TextBuffer]         ; RDI = Buffer destination pointer
lea rbx,[ResultRead]         ; RBX = Pointer to 2 results: Read and Write
mov ecx,2                    ; 2 items: load (read) and store (write)
@@:                          ; cycle for 2 items
mov rax,[rbx]                ; RAX = numeric value of parameter to visual
call ItemWrite               ; Write parameter name and " = ", update RSI,RDI
call FloatPrintP1            ; Write parameter numeric value, update RDI
call ItemWrite               ; Write parameter units, update RSI, RDI
add rbx,8
loop @b                      ; Cycle for 2 items: load (read) and store (write) 
mov al,0
stosb                        ; Write strings sequence terminator = 0

;---------- Output results ----------------------------------------------------;

lea rcx,[TextBuffer]
call ConsoleStringWrite    ; Output prepared result strings
lea rcx,[CrLf2]
call ConsoleStringWrite    ; Make one string interval before OS output

;---------- Exit program ------------------------------------------------------;

ExitProgram:               ; Common entry point for exit to OS
xor ecx,ecx                ; RCX = Parm#1 = Exit code
call [ExitProcess]         ; No return from this function

ErrorCmdLine:              ; This entry point for command line errors
lea rcx,[CmdLineError]
call ConsoleStringWrite
jmp ExitProgram

;---------- Exit points for execution errors exit -----------------------------;
; Reserved for add functionality, restore system context:
; release memory, close handles, restore affinity
; Terminology notes: MB = Message Box
; R15 = Pointer to action phase description string
; R14 = Error code, 0 means required get from OS API
;-

ErrorProgram:              ; This entry point used for operaional errors
;--- Write operation phase description string ---
cld                          ; Clear direction for string instructions
lea rsi,[ErrorPhaseString]   ; RSI = Begin of error phase description string
lea rdi,[TextBuffer]         ; RDI = Buffer destination pointer
@@:
movsb
cmp byte [rsi],0
jne @b
mov rsi,r15    ; RSI = Name of executed step for phase description
@@:
movsb
cmp byte [rsi],0
jne @b
mov ax,0A0Dh
stosw
;--- Write status code string ---
lea rsi,[ErrorStatusString]    ; RSI = Begin of error status string
@@:
movsb
cmp byte [rsi],0
jne @b
xchg rax,r14           ; RAX = Additional status code for error description
test rax,rax           ; if RAX=0, get OS status, otherwise RAX=status
jnz @f                 ; Skip get OS status if non-API error cause
call [GetLastError]    ; RAX = Get last error code, caused by OS API call
@@:
call HexPrint64
mov eax,000A0D00h + 'h'
stosd                      ; "h" after hex number, CR, LF and 0 = terminator
lea rcx,[TextBuffer]
call ConsoleStringWrite    ; Output prepared error report
jmp ExitProgram


;---------- Subroutines for console input-output support ----------------------;
                                                        
include 'console\scanforspace.inc'        ; Scan string for first space
include 'console\skipextraspaces.inc'     ; Skip left spaces in the string
include 'console\extractparameter.inc'    ; Copy parm. from the command line
include 'console\consolestringwrite.inc'  ; Console output
; This modules reserved, not used yet:
; include 'console\waitkey.inc'            ; Wait input, get to buffer
; include 'console\createandwritefile.inc' ; Create and Write file
; include 'console\openandreadfile.inc'    ; Open and Read file

;---------- Subroutines for output strings build and input strings parse ------;

include 'strings\stringwrite.inc'         ; Write string, incl. selector-based
include 'strings\itemwrite.inc'           ; Write string with CR,LF and spaces 
include 'strings\decprint.inc'            ; Build string for decimal numbers 
include 'strings\hexprint.inc'            ; Build string for hexadecimal num.
include 'strings\floatprint.inc'          ; Build string for float numbers
include 'strings\sizeprint.inc'           ; Build string for memory block size
include 'strings\stringreadinteger.inc'   ; Parse integer from text string

;---------- Subroutines for system information --------------------------------;

include 'system\checkcpuid.inc'           ; Verify CPUID support, max. function
; This modules reserved, not used yet:
; include 'system\measurecpuclk.inc'      ; Measure CPU TSC clock frequency
; include 'system\delay.inc'              ; Time delay

;========== Data section ======================================================;

section '.data' data readable writeable
;--- Console Input and Output devices handles, pre-blanked NULL for debug ---
InputDevice   DQ  0     ; Handle for Input Device (example=keyboard)
OutputDevice  DQ  0     ; Handle for Output Device (example=display)
;--- Current settings for parameters, pre-blanked NULL for debug ---
UsedPath      DQ  0     ; Pointer to path string
UsedSize      DQ  0     ; File size value, bytes
UsedNUMA      DQ  0     ; NUMA domain number
UsedCPU       DQ  0     ; Thread Ideal Processor
;--- Default settings for parameters ---
DefaultPath   DB  'myfile.bin',0   ; default name, current directory
DefaultSize   DQ  1024*1024*1024   ; 1 GB default size
DefaultNUMA   DQ  0                ; default NUMA domain number
DefaultCPU    DQ  0                ; default Thread Ideal Processor
;--- Benchmarks results, sequental addressing used, +8 ---
ResultRead    DQ  0
ResultWrite   DQ  0
;--- File performance flags ---
FILE_FLAGS  EQU  FILE_ATTRIBUTE_NORMAL     \
               + FILE_FLAG_WRITE_THROUGH   \
               + FILE_FLAG_NO_BUFFERING    \
               + FILE_FLAG_SEQUENTIAL_SCAN
;--- Variable with previous definition ---              
FileFlags         DQ  FILE_FLAGS
;--- Product ID string ---
ProductID         DB  0Ah,0Dh
                  DB  'Swapping/DAX benchmarks v0.13 (Windows x64 console)'
                  DB  0Ah,0Dh
                  DB  'NUMA edition'                  
                  DB  0Ah,0Dh
                  DB  '(C) 2018 IC Book Labs.',0  
;--- Parameters names strings ---              
ParmName1         DB  0Ah,0Dh,'Parameter #1 : ',0
ParmName2         DB  0Ah,0Dh,'Parameter #2 : ',0 
ParmName3         DB  0Ah,0Dh,'Parameter #3 : ',0
ParmName4         DB  0Ah,0Dh,'Parameter #4 : ',0
Interpreted1      DB  0Ah,0Dh,'File path    : ',0
Interpreted2      DB  0Ah,0Dh,'File size    : ',0
Interpreted3      DB  0Ah,0Dh,'NUMA domain  : ',0
Interpreted4      DB  0Ah,0Dh,'Processor    : ',0
;--- Console trace messages ---
TraceWriteDelay   DB  'Delay before write...'    , 0Ah , 0Dh , 0
TraceInitWrite    DB  'Initializing write...'    , 0Ah , 0Dh , 0
TraceReadDelay    DB  'Delay before read...'     , 0Ah , 0Dh , 0
TraceInitRead     DB  'Initializing read...'     , 0Ah , 0Dh , 0
TraceBuildResult  DB  'Build result strings...'  , 0Ah , 0Dh , 0
;--- Console trace messages with debug dump ---
TraceWriteDump    DB  'Write ( '                            ; Write parameters
TWD1:             DB  '________________, '                  ; File handle
TWD2:             DB  '________________, '                  ; Map handle 
TWD3:             DB  '________________-'                   ; Map start
TWD4:             DB  '________________ )...', 0Ah, 0Dh, 0  ; Map end                   
TraceReadDump     DB  'Read ( '                             ; Read parameters
TRD1:             DB  '________________, '                  ; File handle
TRD2:             DB  '________________, '                  ; Map handle 
TRD3:             DB  '________________-'                   ; Map start
TRD4:             DB  '________________ )...', 0Ah, 0Dh, 0  ; Map end                   
;--- Names for operations steps ---
; Write phase steps
StepCreateW        DB  'Create file for write',0
StepMapW           DB  'Create file mapping for write',0
StepViewW          DB  'Map view of file for write',0
StepModifyW        DB  'Modify memory mapped buffer before flush',0
StepFlushW         DB  'Flush view of file means write',0
StepCloseMapW      DB  'Close mapping handle after write',0
StepCloseFileW     DB  'Close file handle after write',0
StepUnmapW         DB  'Unmap view of file after write',0
StepDeleteFileW    DB  'Delete file after write',0
; Read phase steps
StepOpenR          DB  'Open file for read',0
StepMapR           DB  'Create file mapping for read',0
StepViewR          DB  'Map view of file for read',0
StepLoadR          DB  'Load view of file',0
StepCloseMapR      DB  'Close mapping handle after read',0
StepCloseFileR     DB  'Close file handle after read',0
StepUnmapR         DB  'Unmap view of file after read',0
StepDeleteFileR    DB  'Delete file after read',0
; Results phase steps
StepFPU            DB  'Detect FPU',0
StepCalc           DB  'Calculate speed at MBPS',0
;--- Result messages ---
ResultPhaseString  DB  'READ ', 0
                   DB  ' MBPS', 0
                   DB  0Ah, 0Dh, 'WRITE', 0
                   DB  ' MBPS', 0
;--- Errors messages ---
ErrorPhaseString   DB  'Benchmarks failed', 0Ah, 0Dh
                   DB  'Error phase: ',0
ErrorStatusString  DB  'Error status: ',0
;--- Error messages for command line parameters error ---
CmdLineError:
DB  0Ah, 0Dh
DB  'ERROR in command line, usage:'                     , 0Ah , 0Dh
DB  'daxbench <path> <size in MB> <domain> <processor>' , 0Ah , 0Dh
DB  'Example default:'                                  , 0Ah , 0Dh
DB  './daxbench_numa myfile.bin 1024 0 0'               , 0Ah , 0Dh , 0
;--- Warning messages for default mode, command line parameters absent ---
CmdLineEmpty:
DB  0Ah, 0Dh 
DB  'WARNING: command line empty, defaults used,'       , 0Ah , 0Dh
DB  'can accept parameters:'                            , 0Ah , 0Dh           
DB  'daxbench <path> <size in MB> <domain> <processor>' , 0Ah , 0Dh
DB  'Example:'                                          , 0Ah , 0Dh
DB  './daxbench_numa myfile.bin 1024 0 0'               , 0
;--- Carriage Return, Line Feed, service for text output ---
CrLf2:
DB  0Ah,0Dh
CrLf:
DB  0Ah,0Dh,0
;--- Memory size units ---
U_B   DB  'Bytes',0
U_KB  DB  'KB',0
U_MB  DB  'MB',0
U_GB  DB  'GB',0
U_TB  DB  'TB',0
;--- Constants for calculations ---
WinSeconds  DD 10000000    ; 100ns units / this = 1s units
ConstK100   DD 1024*100
;--- Support NUMA-oriented functions --- 
Function_CreateFileMappingNumaA  DQ  0             ; Function pointer
ThreadHandle  DQ  0                                ; Thread handle
NameKernel32  DB  'KERNEL32.DLL',0                 ; Library name
NameFunction  DB  'CreateFileMappingNumaA',0       ; Function name
;--- Buffers ---
; This buffers must be last data objects for file size optimization,
; because allocated only, data pattern not defined.
;---
ReadBuffer    DB  512 DUP (?)     ; Get data from console input
Parameter1    DB  512 DUP (?)     ; Extract command line parameter #1
Parameter2    DB  512 DUP (?)     ; Extract command line parameter #2
Parameter3    DB  512 DUP (?)     ; Extract command line parameter #3
Parameter4    DB  512 DUP (?)     ; Extract command line parameter #4
TextBuffer    DB  512 DUP (?)     ; Transit buffer for text block build

;========== Import data section ===============================================;

section '.idata' import data readable writeable
library kernel32 , 'KERNEL32.DLL'
include 'api\kernel32.inc'
