;==============================================================================;
;                                                                              ;
;         DAX-optimized benchmarks for memory mapping files swapping.          ;
;                          (engineering release).                              ;
;                         Win32 Edition, NUMA aware.                           ; 
;                           (C)2018 IC Book Labs.                              ;
;                                                                              ;
;  This file is main module: translation object, interconnecting all modules.  ;
;                                                                              ;
;        Translation by Flat Assembler version 1.72 (Oct 10, 2017)             ;
;           Visit http://flatassembler.net/ for more information.              ;
;           For right tabulations, please edit by FASM Editor 2.0              ;
;                                                                              ;
;==============================================================================;

format PE console
entry start
include 'win32ax.inc'

;========== Code section ======================================================;

section '.code' code readable executable
start:

;---------- Initializing console input-output ---------------------------------;

push STD_INPUT_HANDLE       ; Parm#1 = [esp] = Handle ID       
call [GetStdHandle]         ; Initializing input device handle (keyboard)
test eax,eax
jz ExitProgram              ; Silent exit if get input handle failed
mov [InputDevice],eax
push STD_OUTPUT_HANDLE      ; Parm#1 = [esp] = Handle ID    
call [GetStdHandle]         ; Initializing output device handle (display)
test eax,eax
jz ExitProgram              ; Silent exit if get output handle failed
mov [OutputDevice],eax
lea ecx,[ProductID]         ; ECX = Pointer to string for output         
call ConsoleStringWrite     ; Visual first message
call [GetCommandLineA]      ; Get command line
test eax,eax
jz ExitProgram              ; Silent exit if get command line failed

;---------- Extract command line parameters as strings ------------------------;

cld
xchg esi,eax                ; ESI = Pointer to command line string
mov ecx,132                 ; Skip this program name
call ScanForSpace
cmp al,' '
jne DefaultMode             ; Go if command line parameters absent
call SkipExtraSpaces        ; Skip extra spaces
cmp al,0
je DefaultMode              ; Go if command line parameters absent 

lea edi,[Parameter1]        ; Extract first parameter = file name   
call ExtractParameter
cmp al,0
je ErrorCmdLine
call SkipExtraSpaces        ; Skip extra spaces
cmp al,0
je ErrorCmdLine

lea edi,[Parameter2]        ; Extract second parameter = file size, MB   
call ExtractParameter
cmp al,0
je ErrorCmdLine
call SkipExtraSpaces        ; Skip extra spaces
cmp al,0
je ErrorCmdLine

lea edi,[Parameter3]        ; Extract third parameter = NUMA domain number   
call ExtractParameter
cmp al,0
je ErrorCmdLine
call SkipExtraSpaces        ; Skip extra spaces
cmp al,0
je ErrorCmdLine
 
lea edi,[Parameter4]        ; Extract forth parameter = Logical CPU number
call ExtractParameter
cmp al,0                    ; This used if extra parameters is error
jne ErrorCmdLine

jmp VisualPrimary           ; Jump over default mode

;---------- Support default mode for parameters absent in the command line ----;

DefaultMode:

lea ecx,[CmdLineEmpty]
call ConsoleStringWrite     ; Output warning if run without parameters
lea eax,[DefaultPath]
mov [UsedPath],eax          ; Set path = default path
mov eax,[DefaultSize]
mov [UsedSize],eax          ; set size = default size

lea ecx,[Interpreted1]
call ConsoleStringWrite
mov ecx,[UsedPath]
call ConsoleStringWrite     ; Additional visual interpreted value, for debug

lea ecx,[Interpreted2]
call ConsoleStringWrite
lea edi,[TextBuffer]        ; EDI = Pointer to destination transit buffer
mov eax,[UsedSize]          ; EAX = size in bytes
mov bl,0FFh                 ; BL = 0FFh means units auto-select
call SizePrint32
mov al,0
stosb
lea ecx,[TextBuffer]
call ConsoleStringWrite     ; Additional visual interpreted value, for debug

lea ecx,[Interpreted3]
call ConsoleStringWrite
lea edi,[TextBuffer]        ; EDI = Pointer to destination transit buffer
mov eax,[UsedNUMA]          ; EAX = NUMA domain number
mov bl,0                    ; BL = 0 means template auto-select
call DecimalPrint32
mov al,0
stosb
lea ecx,[TextBuffer]
call ConsoleStringWrite     ; Additional visual interpreted value, for debug

lea ecx,[Interpreted4]
call ConsoleStringWrite
lea edi,[TextBuffer]        ; EDI = Pointer to destination transit buffer
mov eax,[UsedCPU]           ; EAX = CPU number
mov bl,0                    ; BL = 0 means template auto-select
call DecimalPrint32
mov al,0
stosb
lea ecx,[TextBuffer]
call ConsoleStringWrite     ; Additional visual interpreted value, for debug

jmp RunTest

;---------- Visual command line parameters as strings -------------------------;

VisualPrimary:

lea ecx,[ParmName1]         ; Visual parameter 1 string = File path
call ConsoleStringWrite
lea ecx,[Parameter1]
call ConsoleStringWrite

lea ecx,[ParmName2]         ; Visual parameter 2 string = File size, MB
call ConsoleStringWrite
lea ecx,[Parameter2]
call ConsoleStringWrite

lea ecx,[ParmName3]         ; Visual parameter 3 string = NUMA domain number
call ConsoleStringWrite
lea ecx,[Parameter3]
call ConsoleStringWrite

lea ecx,[ParmName4]         ; Visual parameter 4 string = Logical CPU number
call ConsoleStringWrite
lea ecx,[Parameter4]
call ConsoleStringWrite

;---------- Interpreting and visual parameter #1 = file path ------------------; 

lea eax,[Parameter1]
mov [UsedPath],eax          ; Assign operational value: pointer to path
lea ecx,[Interpreted1]
call ConsoleStringWrite
mov ecx,[UsedPath]
call ConsoleStringWrite     ; Additional visual interpreted value, for debug

;---------- Interpreting and visual parameter #2 = file size ------------------;

lea esi,[Parameter2]
call StringReadInteger
jc ErrorCmdLine
imul eax,eax,1024*1024       ; Convert from megabytes to bytes
mov [UsedSize],eax           ; Assign operational value: size in bytes
lea ecx,[Interpreted2]
call ConsoleStringWrite
lea edi,[TextBuffer]         ; EDI = Pointer to destination transit buffer
mov eax,[UsedSize]           ; EAX = size in bytes
mov bl,0FFh                  ; BL = 0FFh means units auto-select
call SizePrint32
mov al,0
stosb
lea ecx,[TextBuffer]
call ConsoleStringWrite     ; Additional visual interpreted value, for debug

;---------- Interpreting and visual parameter #3 = NUMA domain number ---------;

lea esi,[Parameter3]
call StringReadInteger
jc ErrorCmdLine
mov [UsedNUMA],eax
lea ecx,[Interpreted3]
call ConsoleStringWrite
lea edi,[TextBuffer]        ; EDI = Pointer to destination transit buffer
mov eax,[UsedNUMA]          ; EAX = NUMA domain number
mov bl,0                    ; BL = 0 means template auto-select
call DecimalPrint32
mov al,0
stosb
lea ecx,[TextBuffer]
call ConsoleStringWrite     ; Additional visual interpreted value, for debug

;---------- Interpreting and visual parameter #4 = Thread ideal processor -----;

lea esi,[Parameter4]
call StringReadInteger
jc ErrorCmdLine
mov [UsedCPU],eax
lea ecx,[Interpreted4]
call ConsoleStringWrite
lea edi,[TextBuffer]        ; EDI = Pointer to destination transit buffer
mov eax,[UsedCPU]           ; EAX = CPU number
mov bl,0                    ; BL = 0 means template auto-select
call DecimalPrint32
mov al,0
stosb
lea ecx,[TextBuffer]
call ConsoleStringWrite     ; Additional visual interpreted value, for debug


;=== WRITE PHASE === 

RunTest:

;---------- Delay before WRITE ------------------------------------------------;

lea ecx,[CrLf2]
call ConsoleStringWrite
lea ecx,[TraceWriteDelay]
call ConsoleStringWrite

push 40*1000      ; Parm#1 = sleep time, milliseconds
call [Sleep]      ; This method is simplest and minimum CPU utilization

;---------- Create file -------------------------------------------------------;

lea ecx,[TraceInitWrite]
call ConsoleStringWrite

xor eax,eax                         ; EAX = 0
mov [ActionPhase],StepCreateW       ; Step name for errors handling
mov [ErrorCode],eax                 ; 0, means get status from OS 
push eax                            ; Parm#7 = Template file handle, not used 
push [FileFlags]                    ; Parm#6 = File attribute and flags
push CREATE_ALWAYS                  ; Parm#5 = Creation disposition
push eax                            ; Parm#4 = Security attributes = 0
push eax                            ; Parm#3 = Share mode = 0
push GENERIC_READ OR GENERIC_WRITE  ; Parm#2 = Desired access 
push [UsedPath]                     ; Parm#1 = Pointer to file path
call [CreateFileA]
test eax,eax                        ; Check RAX = Handle
jz ErrorProgram                     ; Go if error create file
xchg ebx,eax                        ; EBX = File Handle

;---------- Create mapping object for file ------------------------------------;

mov [ActionPhase],StepMapW          ; Step name for errors handling
; Get thread handle
mov [ErrorCode],0                   ; 0, means get status from OS
call [GetCurrentThread]
test eax,eax
jz ErrorProgram
mov [ThreadHandle],eax
; Set Thread Ideal Processor (required affinity settings for NUMA node)
push [UsedCPU]
push eax                       ; [ThreadHandle]
call [SetThreadIdealProcessor]
cmp eax,-1
je ErrorProgram
; Get handle for KERNEL32.DLL
push NameKernel32              ; Parm#1 = Pointer to module name string
call [GetModuleHandle]         ; EAX = Return module handle
test eax,eax
jz ErrorProgram
; Get function pointer
push NameFunction              ; Parm#2 = Pointer to function name
push eax                       ; Parm#1 = Module handle
call [GetProcAddress]          ; EAX = Return function address
test eax,eax
jz ErrorProgram
mov [Function_CreateFileMappingNumaA],eax

; Call NUMA-oriented mapping function
xor eax,eax                  ; EAX = 0
push [UsedNUMA]              ; Parm#7 = NUMA domain number
push eax                     ; Parm#6 = Name of mapped object, NULL = no name  
push [UsedSize]              ; Parm#5 = Mapped file size, low 32-bit
push eax                     ; Parm#4 = Mapped file size, high 32-bit 
push PAGE_READWRITE          ; Parm#3 = Memory page protection attribute
push eax                     ; Parm#2 = Security attributes, not used (NULL)
push ebx                     ; Parm#1 = File handle
call [Function_CreateFileMappingNumaA]
test eax,eax
jz ErrorProgram              ; Go if error create mapping object
xchg ebp,eax                 ; EBP = Mapping File Object Handle 

;---------- Allocate mapping object at application memory ---------------------;

xor eax,eax                  ; EAX = 0
mov [ActionPhase],StepViewW  ; Step name for errors handling, ErrorCode still 0
push [UsedSize]              ; Parm#5 = Size of mapping object
push eax                     ; Parm#4 = Offset in the mapped file, low 32-bit 
push eax                     ; Parm#3 = Offset in the mapped file, high 32-bit
push FILE_MAP_ALL_ACCESS     ; Parm#2 = Access, enable Read and Write
push ebp                     ; Parm#1 = Mapping File Object Handle 
call [MapViewOfFile]
test eax,eax
jz ErrorProgram              ; Go if mapping error
xchg esi,eax                 ; ESI = Mapping Object Linear Virtual Address

;---------- Fill buffer for make swapping request -----------------------------; 

mov [ActionPhase],StepModifyW ; Step name for err. handling, ErrorCode still 0
cld                           ; Increment mode for string instructions
mov edi,esi                   ; EDI = Destination pointer for write array
mov ecx,[UsedSize]
shr ecx,2                     ; ECX = Number of 32-bit double words
mov eax,'DATA'                ; EAX = Pattern for write array 
rep stosd                     ; Write array

;---------- Message about WRITE with debug dump -------------------------------;

push edi
mov eax,ebx
lea edi,[TWD1]
call HexPrint32           ; Print file handle
mov eax,ebp
lea edi,[TWD2]
call HexPrint32           ; Print mapping object handle
mov eax,esi
lea edi,[TWD3]
call HexPrint32           ; Print mapping region start address
lea eax,[esi-1]
add eax,[UsedSize] 
lea edi,[TWD4]
call HexPrint32           ; Print mapping region end address
lea ecx,[TraceWriteDump]
call ConsoleStringWrite   ; Output prepared string to console
pop edi

;---------- Flush buffer (write to disk) with time measurement ----------------;

xor eax,eax                    ; EAX = 0
mov [ActionPhase],StepFlushW   ; Step name for err. handling, ErrorCode still 0

;--- Start measured time ---
push TimerStart                 ; Parm#1 = Offset vari. for update by function
call [GetSystemTimeAsFileTime]  ; Update variable time stamp, units = 100 ns
;--- Target measured operation ---
push [UsedSize]                ; Parm#2 = Size of flushed region
push esi                       ; Parm#1 = Mapping Object Linear Virtual Address 
call [FlushViewOfFile]
test eax,eax
jz ErrorProgram                 ; Go if flush operation error
;--- End measured time ---
push TimerStop                  ; Parm#1 = Pointer to updated variable (time)
call [GetSystemTimeAsFileTime]  ; Update variable time stamp, units = 100 ns

;--- Delta time = T_after - T_before ---
lea ecx,[TimerStart]
mov eax,[ecx+08]
mov edx,[ecx+12]
sub eax,[ecx+00]
sbb edx,[ecx+04]
lea ecx,[ResultWrite]   ; Save result for WRITE, Time interval, units = 100 ns
mov [ecx+00],eax        ; Result delta, low 32 bits
mov [ecx+04],edx        ; Result delta, high 32 bits 

;---------- Close mapping object ----------------------------------------------;

mov [ActionPhase],StepCloseMapW  ; Step name err. handling, ErrorCode still 0
push ebp                         ; Parm#1 = Mapping File Object Handle
call [CloseHandle]
test eax,eax
jz ErrorProgram                  ; Go if close mapping object error

;---------- Close file --------------------------------------------------------;

mov [ActionPhase],StepCloseFileW  ; Step name err. handling, ErrorCode still 0
push ebx                          ; Parm#1 = File handle
call [CloseHandle]
test eax,eax
jz ErrorProgram                   ; Go if close file error

;---------- Unmap view of file ------------------------------------------------;
; This step added at v0.02, otherwise cannot delete file with access denied

mov [ActionPhase],StepUnmapW  ; Step name err. handling, ErrorCode still 0
push esi                      ; Parm#1 = Base virtual address of unmapped range
call [UnmapViewOfFile]
test eax,eax
jz ErrorProgram               ; Go if unmap operation error


;=== READ PHASE ===

;---------- Delay before READ -------------------------------------------------;

lea ecx,[TraceReadDelay]
call ConsoleStringWrite

push 40*1000      ; Parm#1 = sleep time, milliseconds, note RCX[63-32] cleared
call [Sleep]      ; This method is simplest and minimum CPU utilization

;---------- Open file ---------------------------------------------------------;

lea ecx,[TraceInitRead]
call ConsoleStringWrite

xor eax,eax                  ; EAX = 0
mov [ActionPhase],StepOpenR  ; Step name err. handling
mov [ErrorCode],eax          ; 0, means get status from OS 
push eax                     ; Parm#7 = Template file handle, not used 
push [FileFlags]             ; Parm#6 = File attribute and flags
push OPEN_ALWAYS             ; Parm#5 = Creation disposition
push eax                     ; Parm#4 = Security attributes = 0
push eax                     ; Parm#3 = Share mode = 0 
push GENERIC_READ OR GENERIC_WRITE  ; Parm#2 = Desired access
push [UsedPath]                     ; Parm#1 = Pointer to file path 
call [CreateFileA]
test eax,eax                 ; Check RAX = Handle
jz ErrorProgram              ; Go if error create file
xchg ebx,eax                 ; RBX = File Handle

;---------- Create mapping object for file ------------------------------------;

xor eax,eax                  ; EAX = 0
mov [ActionPhase],StepMapR   ; Step name err. handling, ErrorCode still 0

; Call NUMA-oriented mapping function
xor eax,eax                  ; EAX = 0
push [UsedNUMA]              ; Parm#7 = NUMA domain number
push eax                     ; Parm#6 = Name of mapped object, NULL = no name  
push [UsedSize]              ; Parm#5 = Mapped file size, low 32-bit
push eax                     ; Parm#4 = Mapped file size, high 32-bit 
push PAGE_READWRITE          ; Parm#3 = Memory page protection attribute
push eax                     ; Parm#2 = Security attributes, not used (NULL)
push ebx                     ; Parm#1 = File handle
call [Function_CreateFileMappingNumaA]
test eax,eax
jz ErrorProgram              ; Go if error create mapping object
xchg ebp,eax                 ; EBP = Mapping File Object Handle 

;---------- Allocate mapping object at application memory ---------------------;

xor eax,eax                  ; EAX = 0
mov [ActionPhase],StepViewR  ; Step name err. handling, ErrorCode still 0
push [UsedSize]              ; Parm#5 = Size of mapping object
push eax                     ; Parm#4 = Offset in the mapped file, low 32-bit
push eax                     ; Parm#3 = Offset in the mapped file, high 32-bit
push FILE_MAP_ALL_ACCESS     ; Parm#2 = Access, enable Read and Write
push ebp                     ; Parm#1 = Mapping File Object Handle
call [MapViewOfFile]
test eax,eax
jz ErrorProgram              ; Go if mapping error
xchg esi,eax                 ; ESI = Mapping Object Address

;---------- Message about READ with debug dump --------------------------------;

push edi
mov eax,ebx
lea edi,[TRD1]
call HexPrint32           ; Print file handle
mov eax,ebp
lea edi,[TRD2]
call HexPrint32           ; Print mapping object handle
mov eax,esi
lea edi,[TRD3]
call HexPrint32           ; Print mapping region start address
lea eax,[esi-1]
add eax,[UsedSize] 
lea edi,[TRD4]
call HexPrint32           ; Print mapping region end address
lea ecx,[TraceReadDump]
call ConsoleStringWrite   ; Output prepared string to console
pop edi

;---------- Memory read for make swapping request, measure time ---------------;

mov [ActionPhase],StepLoadR     ; Step name err. handling, ErrorCode still 0

;--- Start measured time ---
push TimerStart                 ; Parm#1 = Pointer to updated variable (time)
call [GetSystemTimeAsFileTime]  ; Return time stamp, units = 100 ns
;--- Target measured operation ---
mov edi,esi                 ; EDI = Pointer to mapped region
mov ecx,[UsedSize]          ; ECX = Mapped File size
shr ecx,9                   ; Convert to 512-byte units
xor eax,eax                 ; Pre-clear RAX
@@:
add eax,[edi]   ; Load memory mapped file, ADD(not MOV) to prevent speculative
add edi,512     ; Granularity = 1 minimal sector, minimum for swapping occured 
dec ecx
jnz @b
;--- End measured time ---
push TimerStop                  ; Parm#1 = Pointer to updated variable (time)
call [GetSystemTimeAsFileTime]  ; Update variable time stamp, units = 100 ns

;--- Delta time = T_after - T_before ---
lea ecx,[TimerStart]
mov eax,[ecx+08]
mov edx,[ecx+12]
sub eax,[ecx+00]
sbb edx,[ecx+04]
lea ecx,[ResultRead]    ; Save result for WRITE, Time interval, units = 100 ns
mov [ecx+00],eax        ; Result delta, low 32 bits
mov [ecx+04],edx        ; Result delta, high 32 bits 

;---------- Close mapping object ----------------------------------------------;

mov [ActionPhase],StepCloseMapR  ; Step name err. handling, ErrorCode still 0
push ebp                         ; Parm#1 = Mapping File Object Handle
call [CloseHandle]
test eax,eax
jz ErrorProgram                  ; Go if close mapping object error

;---------- Close file --------------------------------------------------------;

mov [ActionPhase],StepCloseFileR  ; Step name err. handling, ErrorCode still 0
push ebx                          ; Parm#1 = File handle
call [CloseHandle]
test eax,eax
jz ErrorProgram                   ; Go if close file error

;---------- Unmap view of file ------------------------------------------------;
; This step added at v0.02, otherwise cannot delete file with access denied

mov [ActionPhase],StepUnmapR  ; Step name err. handling, ErrorCode still 0
push esi                      ; Parm#1 = Base virtual address of unmapped range
call [UnmapViewOfFile]
test eax,eax
jz ErrorProgram               ; Go if unmap operation error

;---------- Delete file -------------------------------------------------------;
; This step added at v0.02, only possible if file unmapped

mov [ActionPhase],StepDeleteFileR  ; Step name err. handling, ErrorCode still 0
push [UsedPath]                    ; Parm#1 = Pointer to file path
call [DeleteFile]
test eax,eax
jz ErrorProgram                    ; Go if delete operation error


;=== CALCULATIONS PHASE ===

lea ecx,[TraceBuildResult]
call ConsoleStringWrite

;---------- Detect x87 FPU ----------------------------------------------------;

mov [ActionPhase],StepFPU
mov [ErrorCode],1      ; 1, means status code for this step
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

mov [ActionPhase],StepCalc
mov [ErrorCode],0           ; 0, prepare for cycle
lea ebx,[ResultRead]  ; EBX = Pointer to 2 results: Read and Write
@@:                   ; cycle for 2 items, interval input units = 100 ns
inc [ErrorCode]       ; Code = 1(4), means status code for this step/sub step
mov eax,[ebx+0]
mov edx,[ebx+4]
or eax,edx
jz ErrorProgram       ; Go error if time interval zero
inc [ErrorCode]       ; R14 = 2(5), means status code for this step/sub step
test edx,edx
js ErrorProgram       ; Go error if time interval negative
inc [ErrorCode]       ; Code = 3(6), means too big result
fild qword [ebx]      ; ST0 = time interval, ST1,ST2,ST3 = shifted ST0,ST1,ST2
fdiv st0,st1          ; ST0 = Seconds
fdivr st0,st2         ; ST0 = Bytes per second
fdiv st0,st3          ; ST0 = Units per second, unit = 100KB
fistp qword [ebx]     ; Write FPU result to variable, 100KB units per second
cmp dword [ebx+0],10000000
jae ErrorProgram      ; Go error if unexcepted high speed
cmp dword [ebx+4],0
jne ErrorProgram      ; Go error if unexcepted high speed
add ebx,8             ; Next variable from 2
cmp [ErrorCode],6
jb @b                 ; Cycle for 2 items: load (read) and store (write) 

;---------- Prepare text strings for show -------------------------------------;

lea esi,[ResultPhaseString]  ; ESI = Pointer to parameter name
lea edi,[TextBuffer]         ; EDI = Buffer destination pointer
lea ebx,[ResultRead]         ; EBX = Pointer to 2 results: Read and Write
mov ecx,2                    ; 2 items: load (read) and store (write)
@@:                          ; cycle for 2 items
mov eax,[ebx]                ; EAX = numeric value of parameter to visual
call ItemWrite               ; Write parameter name and " = ", update RSI, RDI
call FloatPrintP1            ; Write parameter numeric value, update RDI
call ItemWrite               ; Write parameter units, update RSI, RDI
add ebx,8
loop @b                      ; Cycle for 2 items: load (read) and store (write) 
mov al,0
stosb                        ; Write strings sequence terminator = 0

;---------- Output results ----------------------------------------------------;

lea ecx,[TextBuffer]
call ConsoleStringWrite    ; Output prepared result strings
lea ecx,[CrLf2]
call ConsoleStringWrite    ; Make one string interval before OS output

;---------- Exit program ------------------------------------------------------;

ExitProgram:               ; Common entry point for exit to OS
push 0                     ; Parm#1 = Exit code
call [ExitProcess]         ; No return from this function

ErrorCmdLine:              ; This entry point for command line errors
lea ecx,[CmdLineError]
call ConsoleStringWrite
jmp ExitProgram

;---------- Exit points for execution errors exit -----------------------------;
; Reserved for add functionality, restore system context:
; release memory, close handles, restore affinity
; [ActionPhase] = Pointer to action phase description string
; [ErrorCode]   = Error code, 0 means required get from OS API
;-

ErrorProgram:              ; This entry point used for operaional errors
;--- Write operation phase description string ---
cld                          ; Clear direction for string instructions
lea esi,[ErrorPhaseString]   ; ESI = Begin of error phase description string
lea edi,[TextBuffer]         ; EDI = Buffer destination pointer
@@:
movsb
cmp byte [esi],0
jne @b
mov esi,[ActionPhase]    ; ESI = Name of executed step for phase description
@@:
movsb
cmp byte [esi],0
jne @b
mov ax,0A0Dh
stosw
;--- Write status code string ---
lea esi,[ErrorStatusString]    ; ESI = Begin of error status string
@@:
movsb
cmp byte [esi],0
jne @b
xchg eax,[ErrorCode]   ; EAX = Additional status code for error description
test eax,eax           ; if EAX=0, get OS status, otherwise RAX=status
jnz @f                 ; Skip get OS status if non-API error cause
call [GetLastError]    ; RAX = Get last error code, caused by OS API call
@@:
call HexPrint32
mov eax,000A0D00h + 'h'
stosd                      ; "h" after hex number, CR, LF and 0 = terminator
lea ecx,[TextBuffer]
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
InputDevice   DD  0     ; Handle for Input Device (example=keyboard)
OutputDevice  DD  0     ; Handle for Output Device (example=display)
;--- Current settings for parameters, pre-blanked NULL for debug ---
UsedPath      DD  0     ; Pointer to path string
UsedSize      DD  0     ; File size value, bytes
UsedNUMA      DD  0     ; NUMA domain number
UsedCPU       DD  0     ; Thread Ideal Processor
;--- Default settings for parameters ---
DefaultPath   DB  'myfile.bin',0   ; default name, current directory
DefaultSize   DD  1024*1024*1024   ; 1 GB default size
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
FileFlags         DD FILE_FLAGS
;--- Product ID string ---
ProductID         DB  0Ah,0Dh
                  DB  'Swapping/DAX benchmarks v0.14 (Windows ia32 console)'
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
TWD1:             DB  '________, '                          ; File handle
TWD2:             DB  '________, '                          ; Map handle 
TWD3:             DB  '________-'                           ; Map start
TWD4:             DB  '________ )...', 0Ah, 0Dh, 0          ; Map end                   
TraceReadDump     DB  'Read ( '                             ; Read parameters
TRD1:             DB  '________, '                          ; File handle
TRD2:             DB  '________, '                          ; Map handle 
TRD3:             DB  '________-'                           ; Map start
TRD4:             DB  '________ )...', 0Ah, 0Dh, 0          ; Map end                   
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
;--- Status ---
ActionPhase  DD  0
ErrorCode    DD  0
;--- OS timers support ---
align 8
TimerStart   DQ  0
TimerStop    DQ  0
;--- Support NUMA-oriented functions --- 
Function_CreateFileMappingNumaA  DD  0             ; Function pointer
ThreadHandle  DD  0                                ; Thread handle
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
