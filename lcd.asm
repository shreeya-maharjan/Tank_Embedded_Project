public init_lcd, refresh_screen, blank_screen, screen, font5x8

?PR?lcd segment code
rseg ?PR?lcd

$include (c8051f020.inc)

LCD_CMD   equ 08000H    ; command register address
LCD_DAT   equ 08001H    ; data register address
LCD_RESET equ 10H       ; P4.4 reset

;
; subroutines wcom and w_com_a
;   Writes a byte to the LCD command register after checking the busy flag first
;   Assumes the external memory inter/./
;face is configured for split mode with bank
;   select.
; inputs:
;   wcom:   r0  = byte to write to command register
;   wcom_a: acc = byte to write to command register
; outputs: none
; destroys:
;   wcom:   EMI0CN, r1
;   wcom_a: EMI0CN, r0, r1
;
wcom_a:
mov r0,a ; save acc in R0 while we check BUSY
wcom:
mov EMI0CN,#HIGH LCD_CMD ; command/status register
mov r1,#LOW LCD_CMD
wcom1:
movx a,@r1 ; get status register
jb acc.7,wcom1 ; wait for not BUSY
mov a,r0 ; get the actual data to write
movx @r1,a ; write the command
ret

;
; subroutines wdat and w_dat_a and w_datc
;   Writes a byte to the LCD data register after checking the busy flag first
;   Assumes the external memory interface is configured for split mode with bank
;   select.
; inputs:
;   wdat:   r0  = byte to write to data register
;   wdat_a: acc = byte to write to data register
;   wdat_c: acc = dptr-relative index (dptr[acc]) of byte to write to data register
; outputs: none
; destroys:
;   wdat:   EMI0CN, r1
;   wdat_a: EMI0CN, r0, r1
;   wdat_c: EMI0CN, r0, r1
;
wdat_c:
movc a,@a+dptr ; lookup byte to write (handy for fonts)
wdat_a:
mov r0,a ; save it in R0 while we check BUSY
wdat:
mov EMI0CN,#HIGH LCD_CMD ; command/status register
mov r1,#LOW LCD_CMD
wdat1:
movx a,@r1 ; get status register
jb acc.7,wdat1 ; wait for not BUSY
inc r1 ; point to data register
mov a,r0 ; actual data to write
movx @r1,a ; write the data
ret

;
; Initialize controller for S64128N LCD module
;   inputs: none
;   outputs: none
;   destroys: r0, r2, r3, dptr
;
init_lcd:
mov p4,#not LCD_RESET
mov emi0cf,#038H     ; P4-7, non-muxed, split bank
mov emi0tc,#00CH     ; pulse width 4 sysclock cycles
mov p74out,#0FFH     ; push-pull
orl p4,#LCD_RESET     ; assert then deassert reset

mov R0,#02FH ; Boost on, voltage Reg and follower on
call wcom
mov R0,#0A2H ; 1/9 bias selected
call wcom
mov R0,#0A1H ; reverse segment driver output seg131-seg0
call wcom
mov R0,#0C0H ; common output mode com0 to com63
call wcom
mov R0,#024H ; Ra/Rb ratio
call wcom
mov R0,#081H ; electronic volume mode set
call wcom
mov R0,#028H ; contrast
call wcom
mov R0,#040H ; display line address = 0
call wcom
mov R0,#0A6H ; normal video
call wcom
mov R0,#0AFH ; display on
call wcom
call blank_screen ; fall through to refresh_screen

;
; subroutine refresh_screen
;   Copies 1k bytes of data from external address 0 to the LCD. Bytes 0-7F go
;   into page 0, bytes 80-FF go to page 1 etc.
; inputs: none
; outputs: none
; destroys: r0, r2, r3, dptr, EMI0CN
;
refresh_screen:
    mov dptr,#screen
    mov r2,#0B0H              ; page 0
page_loop:
    mov a,r2
    call wcom_a               ; set page

    mov a,#04H
    call wcom_a               ; lower column nibble
    mov a,#10H
    call wcom_a               ; upper column nibble

    mov r3,#128
byte_loop:
    movx a,@dptr
    call wdat_a
    inc dptr
    djnz r3,byte_loop

    inc r2
    cjne r2,#0B8H,page_loop
    ret


blank_screen:
    mov dptr,#screen
    clr a
blank_loop:
    movx @dptr,a
    inc dptr
    mov b,dph
    jnb b.2,blank_loop
    ret

font5x8:
  db  000H, 000H, 000H, 000H, 000H ;  
  db  000H, 006H, 05FH, 006H, 000H ; !
  db  007H, 003H, 000H, 007H, 003H ; "
  db  024H, 07EH, 024H, 07EH, 024H ; #
  db  024H, 02BH, 06AH, 012H, 000H ; $
  db  063H, 013H, 008H, 064H, 063H ; %
  db  036H, 049H, 056H, 020H, 050H ; &
  db  000H, 007H, 003H, 000H, 000H ; '
  db  000H, 03EH, 041H, 000H, 000H ; (
  db  000H, 041H, 03EH, 000H, 000H ; )
  db  008H, 03EH, 01CH, 03EH, 008H ; *
  db  008H, 008H, 03EH, 008H, 008H ; +
  db  000H, 0E0H, 060H, 000H, 000H ; ,
  db  008H, 008H, 008H, 008H, 008H ; -
  db  000H, 060H, 060H, 000H, 000H ; .
  db  020H, 010H, 008H, 004H, 002H ; /
  db  03EH, 051H, 049H, 045H, 03EH ; 0
  db  000H, 042H, 07FH, 040H, 000H ; 1
  db  062H, 051H, 049H, 049H, 046H ; 2
  db  022H, 049H, 049H, 049H, 036H ; 3
  db  018H, 014H, 012H, 07FH, 010H ; 4
  db  02FH, 049H, 049H, 049H, 031H ; 5
  db  03CH, 04AH, 049H, 049H, 030H ; 6
  db  001H, 071H, 009H, 005H, 003H ; 7
  db  036H, 049H, 049H, 049H, 036H ; 8
  db  006H, 049H, 049H, 029H, 01EH ; 9
  db  000H, 06CH, 06CH, 000H, 000H ; :
  db  000H, 0ECH, 06CH, 000H, 000H ; ;
  db  008H, 014H, 022H, 041H, 000H ; <
  db  024H, 024H, 024H, 024H, 024H ; =
  db  000H, 041H, 022H, 014H, 008H ; >
  db  002H, 001H, 059H, 009H, 006H ; ?
  db  03EH, 041H, 05DH, 055H, 01EH ; @
  db  07EH, 011H, 011H, 011H, 07EH ; A
  db  07FH, 049H, 049H, 049H, 036H ; B
  db  03EH, 041H, 041H, 041H, 022H ; C
  db  07FH, 041H, 041H, 041H, 03EH ; D
  db  07FH, 049H, 049H, 049H, 041H ; E
  db  07FH, 009H, 009H, 009H, 001H ; F
  db  03EH, 041H, 049H, 049H, 07AH ; G
  db  07FH, 008H, 008H, 008H, 07FH ; H
  db  000H, 041H, 07FH, 041H, 000H ; I
  db  030H, 040H, 040H, 040H, 03FH ; J
  db  07FH, 008H, 014H, 022H, 041H ; K
  db  07FH, 040H, 040H, 040H, 040H ; L
  db  07FH, 002H, 004H, 002H, 07FH ; M
  db  07FH, 002H, 004H, 008H, 07FH ; N
  db  03EH, 041H, 041H, 041H, 03EH ; O
  db  07FH, 009H, 009H, 009H, 006H ; P
  db  03EH, 041H, 051H, 021H, 05EH ; Q
  db  07FH, 009H, 009H, 019H, 066H ; R
  db  026H, 049H, 049H, 049H, 032H ; S
  db  001H, 001H, 07FH, 001H, 001H ; T
  db  03FH, 040H, 040H, 040H, 03FH ; U
  db  01FH, 020H, 040H, 020H, 01FH ; V
  db  03FH, 040H, 03CH, 040H, 03FH ; W
  db  063H, 014H, 008H, 014H, 063H ; X
  db  007H, 008H, 070H, 008H, 007H ; Y
  db  071H, 049H, 045H, 043H, 000H ; Z


xseg
screen: ds 1024

end