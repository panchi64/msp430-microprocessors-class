;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
; Codemise Project - INEL4206 Microprocessors
; Prof. Jose Navarro Figueroa
;
; TEAM02:
; 	Victor M. Batista Figueroa
;		-> 11% de contribucion
;
; 	Carlos A. Cabrera Bermudez
;		-> 12% de contribucion
;
; 	Francisco A. Casiano Rosado
;		-> 65% de contribucion
;
; 	Christian J. Collado Rivera
;		-> 12% de contribucion
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file

;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------

; Segmented Display Locations (from left to right)
seg1        .equ    9
seg2        .equ    5
seg3        .equ    3
seg4        .equ    18
seg5        .equ    14
seg6        .equ    7

;-------------------------------------------------------------------------------
;
; FOR RENDERING THE NAMES

s2Disable	.word	0

LBpresses   .word   0
RBpresses   .word   0

nameMenu	.word 	0
timerMenu	.word	0

setTimerON	.word	0						; bool = Are the numbers being setup and needs to flash intermittently?
countdownON	.word	0						; bool = Enable the countdown?
paused		.word	0						; bool = to determine if paused or not
curLCDSeg	.word	1
reachedZero	.word	0

;   				 |-----------------HB----------------|	 LB						LETTERS		   HB         LB
ACEFHSLOhi	.word	0xEF,0x9C,0x9F,0x8F,0x6F,0xB7,0x1C,0xFC,0x00				;A				11101111b, 00000000b
											                                    ;C				10011100b, 00000000b
											                                    ;E				10011111b, 00000000b
											                                    ;F				10001111b, 00000000b
											                                    ;H				01101111b, 00000000b
											                                    ;S				10110111b, 00000000b
											                                    ;L				00011100b, 00000000b
											                                    ;O				11111100b, 00000000b
;					 HB	  HB   LB
IT			.word	0x90,0x80,0x50			                                    ;I				10010000b, 01010000b
											                                    ;T				10000000b, 01010000b

MNRVhi		.word	0x6C,0x6C,0xCF,0x0C			                                ;M				01101100b, 10100000b
MNRVlo		.word	0xA0,0x82,0x02,0x28		                                    ;N				01101100b, 10000010b
											                                    ;R				11001111b, 00000010b
											                                    ;V				00001100b, 00101000b
;					 HB	  LB
ZERO		.word	0xFC,0x28													;	NUMBERS		   HB         LB
ONE			.word	0x60,0x20													;0				11111100b, 00101000b
;					 |--------------HB--------------|	LB						 1				01100000b, 00100000b
TwoToNine	.word	0xDB,0xF3,0x67,0xBF,0xE0,0xFF,0xF7,0x00						;2				11011011b, 00000000b
																				;3				11110011b, 00000000b
																				;4				01100111b, 00000000b
																				;5				Use the S pattern
																				;6				10111111b, 00000000b
																				;7				11100000b, 00000000b
																				;8				11111111b, 00000000b
																				;9				11110111b, 00000000b

;-------------------------------------------------------------------------------

timerNums	.word	0xFC,0x60,0xDB,0xF1,0x67,0xB7,0xBF,0xE0,0xFF,0xF7


RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer

;-------------------------------------------------------------------------------
; Main loop here
;
; Registers used:
; 	R5 = temporary value of the location of an lcd letter/digit in an array
; 	R6 = temporary value to show the letter/digit in the LCD
; 	R7 = holds the address of the desired segmented display
; 	R11 = delay "timer"
;
;	R4 = holds the number on the first lcd segment when using timer
; 	R8 = holds the number on the second lcd segment when using timer
; 	R9 = holds the number on the third lcd segment when using timer
;	R10 = holds the number on the fourth lcd segment when using timer
; 	R12 =
; 	R13 =
;
; 	R14 = used to temporarily place the PC+2 value created when using the CALL command
;
;-------------------------------------------------------------------------------

UnlockGPIO:
			bic.w 	#LOCKLPM5, &PM5CTL0

writeTEAM:
			mov.w 	#0xFFFF, &LCDCPCTL0    	;
			mov.w 	#0xFC3F, &LCDCPCTL1    	; Initialize LCD Segments
			mov.w 	#0x0FFF, &LCDCPCTL2    	;

			mov.w 	#0x041e, &LCDCCTL0		; Initialize LCD_C

			mov.w   #0x0208, &LCDCVCTL		; ACLK, Divider = 1, Pre-divider = 16; 4-pin MUX
											; VLCD generated internally,
  		    								; V2-V4 generated internally, v5 to ground
  		    								; Set VLCD voltage to 2.60v
  		    								; Enable charge pump and select internal reference for it

			mov.w   #0x8000, &LCDCCPCTL   	; Clock synchronization enabled

			mov.w   #2, &LCDCMEMCTL       	; Clear LCD memory

			bis.w   #1, &LCDCCTL0			; Turn LCD on

			bic.b	#0xFF, &P1SEL0
			bic.b	#0xFF, &P1SEL1

			mov.b	#0xF9, &P1DIR			; Set all pins on port 1 for output except the two buttons

            bis.b   #0x06, &P1REN           ; P1.1 & P1.2 Resistor enabled as pullup
			bis.b   #0x06, &P1OUT

            bic.b   #0x06, &P1IFG           ; Reset interrupt flag to avoid issues when turning on and off
            bis.b   #0x02, &P1IE            ; Enable interrupt at S1
            bis.b   #0x04, &P1IE            ; Enable interrupt at S2
            bis.b	#0x02, &P1IES
            bis.b	#0x04, &P1IES

        	mov     #TASSEL_2+MC_1+ID_3, &TA0CTL
        									; Line above sets the timer to SMCLK, Up mode and input divider to 8

			mov		#125000, TA0CCR0			; Set clock cycles (0.5s)

			nop
            bis.w	#GIE, SR				; Global interrupt enable
            nop

            clr		R4						;
            clr		R8						;
            clr		R9						; Reset the values for the timer (the numbers in each LCD and set the number location [when editing] to default)
            clr		R10						;
            mov		#1,	curLCDSeg			;

			mov.b 	#0,	LBpresses			;
			mov.b 	#0,	RBpresses			; Make sure that the counters and toggles are in clean slate
			mov.b 	#0,	s2Disable			;
			mov.b	#0, paused				;

			mov.b 	#0,	nameMenu			; If we arrive back at the team name then no menus should be shown
			mov.b 	#0,	timerMenu			;
			mov.b	#0,	countdownON			;



			push	#seg1					; Push LCD display address to stack
			mov		#3, R5					; Push high
			push	IT(R5)					; &
			push	#1+seg1					; low bytes of a letter/digit to the stack
			mov 	#5, R5					; Prints T on the LCD
			push	IT(R5)					;

			call	#writeToLCD

			push	#seg2					; Push LCD display address to stack
			mov		#5, R5					; Push high
			push	ACEFHSLOhi(R5)			; &
			push	#1+seg2					; low bytes of a letter/digit to the stack
			mov 	#17, R5					; Prints E on the LCD
			push	ACEFHSLOhi(R5)			;

			call	#writeToLCD

			push	#seg3					; Push LCD display address to stack
			mov		#1, R5					; Push high
			push	ACEFHSLOhi(R5)			; &
			push	#1+seg3					; low bytes of a letter/digit to the stack
			mov 	#17, R5					; Prints A on the LCD
			push	ACEFHSLOhi(R5)			;

			call	#writeToLCD

			push	#seg4					; Push LCD display address to stack
			mov		#1, R5					; Push high
			push	MNRVhi(R5)				; &
			push	#1+seg4					; low bytes of a letter/digit to the stack
			mov 	#1, R5					; Prints M on the LCD
			push	MNRVlo(R5)				;

			call	#writeToLCD

			push	#seg5					; Push LCD display address to stack
			mov		#1, R5					; Push high
			push	ZERO(R5)				; &
			push	#1+seg5					; low bytes of a letter/digit to the stack
			mov 	#3, R5					; Prints M on the LCD
			push	ZERO(R5)				;

			call	#writeToLCD

			push	#seg6					; Push LCD display address to stack
			mov		#1, R5					; Push high
			push	TwoToNine(R5)			; &
			push	#1+seg6					; low bytes of a letter/digit to the stack
			mov 	#15, R5					; Prints 2 on the LCD
			push	TwoToNine(R5)			;

			call	#writeToLCD

wait:
			cmp		#1, nameMenu
			jz 		showName

			cmp		#1, timerMenu
			jz		showTimer

			jmp		wait

;-------------------------------------------------------------------------------

showName:
			mov 	#1,	s2Disable

			call	#clearLCD

			cmp		#1, LBpresses
			jz		firstName
			cmp		#2, LBpresses
			jz		secondName
			cmp		#3, LBpresses
			jz		thirdName
			cmp		#4, LBpresses
			jz		fourthName

			cmp		#5, LBpresses			; If we've iterated through all members of the team then
			jz		writeTEAM				; return to writeTEAM label and reset button counts

			ret

firstName:
			call	#clearLCD

			push	#seg1					; Push LCD display address to stack
			mov		#7, R5					; Push high
			push	MNRVhi(R5)				; &
			push	#1+seg1					; low bytes of a letter/digit to the stack
			mov 	#7, R5					; Prints V on the LCD
			push	MNRVlo(R5)				;

			call	#writeToLCD

			push	#seg2					; Push LCD display address to stack
			mov		#1, R5					; Push high
			push	IT(R5)					; &
			push	#1+seg2					; low bytes of a letter/digit to the stack
			mov 	#5, R5					; Prints I on the LCD
			push	IT(R5)					;

			call	#writeToLCD

			push	#seg3					; Push LCD display address to stack
			mov		#3, R5					; Push high
			push	ACEFHSLOhi(R5)			; &
			push	#1+seg3					; low bytes of a letter/digit to the stack
			mov 	#17, R5					; Prints C on the LCD
			push	ACEFHSLOhi(R5)			;

			call	#writeToLCD

			push	#seg4					; Push LCD display address to stack
			mov		#3, R5					; Push high
			push	IT(R5)					; &
			push	#1+seg4					; low bytes of a letter/digit to the stack
			mov 	#5, R5					; Prints T on the LCD
			push	IT(R5)					;

			call	#writeToLCD

			push	#seg5					; Push LCD display address to stack
			mov		#15, R5					; Push high
			push	ACEFHSLOhi(R5)			; &
			push	#1+seg5					; low bytes of a letter/digit to the stack
			mov 	#17, R5					; Prints O on the LCD
			push	ACEFHSLOhi(R5)			;

			call	#writeToLCD

			push	#seg6					; Push LCD display address to stack
			mov		#5, R5					; Push high
			push	MNRVhi(R5)				; &
			push	#1+seg6					; low bytes of a letter/digit to the stack
			mov 	#5, R5					; Prints R on the LCD
			push	MNRVlo(R5)				;

			call	#writeToLCD

			mov.b 	#0,	nameMenu			; Prevents falling into an infinite loop of writing to LCD and getting faded letters

			jmp		wait


secondName:
			call	#clearLCD

			push	#seg1					; Push LCD display address to stack
			mov		#3, R5					; Push high
			push	ACEFHSLOhi(R5)			; &
			push	#1+seg1					; low bytes of a letter/digit to the stack
			mov 	#17, R5					; Prints C on the LCD
			push	ACEFHSLOhi(R5)			;

			call	#writeToLCD

			push	#seg2					; Push LCD display address to stack
			mov		#1, R5					; Push high
			push	ACEFHSLOhi(R5)			; &
			push	#1+seg2					; low bytes of a letter/digit to the stack
			mov 	#17, R5					; Prints A on the LCD
			push	ACEFHSLOhi(R5)			;

			call	#writeToLCD

			push	#seg3					; Push LCD display address to stack
			mov		#5, R5					; Push high
			push	MNRVhi(R5)				; &
			push	#1+seg3					; low bytes of a letter/digit to the stack
			mov 	#5, R5					; Prints R on the LCD
			push	MNRVlo(R5)				;

			call	#writeToLCD

			push	#seg4					; Push LCD display address to stack
			mov		#13, R5					; Push high
			push	ACEFHSLOhi(R5)			; &
			push	#1+seg4					; low bytes of a letter/digit to the stack
			mov 	#17, R5					; Prints L on the LCD
			push	ACEFHSLOhi(R5)			;

			call	#writeToLCD

			push	#seg5					; Push LCD display address to stack
			mov		#15, R5					; Push high
			push	ACEFHSLOhi(R5)			; &
			push	#1+seg5					; low bytes of a letter/digit to the stack
			mov 	#17, R5					; Prints O on the LCD
			push	ACEFHSLOhi(R5)			;

			call	#writeToLCD

			push	#seg6					; Push LCD display address to stack
			mov		#11, R5					; Push high
			push	ACEFHSLOhi(R5)			; &
			push	#1+seg6					; low bytes of a letter/digit to the stack
			mov 	#17, R5					; Prints S on the LCD
			push	ACEFHSLOhi(R5)			;

			call	#writeToLCD

			mov.b	#0, nameMenu			; Prevents falling into an infinite loop of writing to LCD and getting faded letters

			jmp		wait

thirdName:
			call	#clearLCD

			push	#seg1					; Push LCD display address to stack
			mov		#7, R5					; Push high
			push	ACEFHSLOhi(R5)			; &
			push	#1+seg1					; low bytes of a letter/digit to the stack
			mov 	#17, R5					; Prints F on the LCD
			push	ACEFHSLOhi(R5)			;

			call	#writeToLCD

			push	#seg2					; Push LCD display address to stack
			mov		#5, R5					; Push high
			push	MNRVhi(R5)				; &
			push	#1+seg2					; low bytes of a letter/digit to the stack
			mov 	#5, R5					; Prints R on the LCD
			push	MNRVlo(R5)				;

			call	#writeToLCD

			push	#seg3					; Push LCD display address to stack
			mov		#1, R5					; Push high
			push	ACEFHSLOhi(R5)			; &
			push	#1+seg3					; low bytes of a letter/digit to the stack
			mov 	#17, R5					; Prints A on the LCD
			push	ACEFHSLOhi(R5)			;

			call	#writeToLCD

			push	#seg4					; Push LCD display address to stack
			mov		#3, R5					; Push high
			push	MNRVhi(R5)				; &
			push	#1+seg4					; low bytes of a letter/digit to the stack
			mov 	#3, R5					; Prints N on the LCD
			push	MNRVlo(R5)				;

			call	#writeToLCD

			push	#seg5					; Push LCD display address to stack
			mov		#3, R5					; Push high
			push	ACEFHSLOhi(R5)			; &
			push	#1+seg5					; low bytes of a letter/digit to the stack
			mov 	#17, R5					; Prints C on the LCD
			push	ACEFHSLOhi(R5)			;

			call	#writeToLCD

			push	#seg6					; Push LCD display address to stack
			mov		#1, R5					; Push high
			push	IT(R5)					; &
			push	#1+seg6					; low bytes of a letter/digit to the stack
			mov 	#5, R5					; Prints I on the LCD
			push	IT(R5)					;

			call	#writeToLCD

			mov.b	#0, nameMenu			; Prevents falling into an infinite loop of writing to LCD and getting faded letters

			jmp		wait

fourthName:
			call	#clearLCD

			push	#seg1					; Push LCD display address to stack
			mov		#3, R5					; Push high
			push	ACEFHSLOhi(R5)			; &
			push	#1+seg1					; low bytes of a letter/digit to the stack
			mov 	#17, R5					; Prints C on the LCD
			push	ACEFHSLOhi(R5)			;

			call	#writeToLCD

			push	#seg2					; Push LCD display address to stack
			mov		#9, R5					; Push high
			push	ACEFHSLOhi(R5)			; &
			push	#1+seg2					; low bytes of a letter/digit to the stack
			mov 	#17, R5					; Prints H on the LCD
			push	ACEFHSLOhi(R5)			;

			call	#writeToLCD

			push	#seg3					; Push LCD display address to stack
			mov		#5, R5					; Push high
			push	MNRVhi(R5)				; &
			push	#1+seg3					; low bytes of a letter/digit to the stack
			mov 	#5, R5					; Prints R on the LCD
			push	MNRVlo(R5)				;

			call	#writeToLCD

			push	#seg4					; Push LCD display address to stack
			mov		#1, R5					; Push high
			push	IT(R5)					; &
			push	#1+seg4					; low bytes of a letter/digit to the stack
			mov 	#5, R5					; Prints I on the LCD
			push	IT(R5)					;

			call	#writeToLCD

			push	#seg5					; Push LCD display address to stack
			mov		#11, R5					; Push high
			push	ACEFHSLOhi(R5)			; &
			push	#1+seg5					; low bytes of a letter/digit to the stack
			mov 	#17, R5					; Prints S on the LCD
			push	ACEFHSLOhi(R5)			;

			call	#writeToLCD

			push	#seg6					; Push LCD display address to stack
			mov		#3, R5					; Push high
			push	IT(R5)					; &
			push	#1+seg6					; low bytes of a letter/digit to the stack
			mov 	#5, R5					; Prints T on the LCD
			push	IT(R5)					;

			call	#writeToLCD

			mov.b	#0, nameMenu			; Prevents falling into an infinite loop of writing to LCD and getting faded letters

			jmp		wait

;-------------------------------------------------------------------------------

showTimer:
			mov.b	#0, s2Disable

			call 	#clearLCD

			push	#seg3					; Push LCD display address to stack
			mov		#1, R5					; Push high
			push	ZERO(R5)				; &
			push	#1+seg3					; low bytes of a letter/digit to the stack
			push	#0

			call	#writeToLCD

			push	#seg4					; Push LCD display address to stack
			mov		#1, R5					; Push high
			push	ZERO(R5)				; &
			push	#1+seg4					; low bytes of a letter/digit to the stack
			push	#0

			call	#writeToLCD

			bis.b	#BIT2, &0x0A33			; Turn on the colon in the display

			push	#seg5					; Push LCD display address to stack
			mov		#1, R5					; Push high
			push	ZERO(R5)				; &
			push	#1+seg5					; low bytes of a letter/digit to the stack
			push	#0

			call	#writeToLCD

			push	#seg6					; Push LCD display address to stack
			mov		#1, R5					; Push high
			push	ZERO(R5)				; &
			push	#1+seg6					; low bytes of a letter/digit to the stack
			push	#0

			call	#writeToLCD

			call	#setTimerDigits

			jmp 	finalizeIntrp

setTimerDigits:
			;bis.b	#BIT0, &P1OUT			; For debugging - turn on red LED
			mov     #CCIE, &TA0CCTL0        ; Enable TACCR0 interrupt

			mov	#1, setTimerON				; Enable the flag to show number intermittently

			ret

incTimerDigit:
			cmp		#1, curLCDSeg
			jz		incFirstDigit

			cmp		#2, curLCDSeg
			jz		incSecondDigit

			cmp		#3, curLCDSeg
			jz		incThirdDigit

			cmp		#4, curLCDSeg
			jz		incFourthDigit

			ret

incFirstDigit:
			incd 	R4
			call 	#digitOneLimiter

			push	#seg3
			push	timerNums(R4)			; change this and other subroutines to writeNums
			push	#1+seg3
			push	#0

			call	#writeToLCD

			jmp		finalizeIntrp

incSecondDigit:
			incd	R8
			call 	#digitTwoLimiter

			push	#seg4
			push	timerNums(R8)
			push	#1+seg4
			push	#0

			call	#writeToLCD

			jmp		finalizeIntrp

incThirdDigit:
			incd	R9
			call 	#digitThreeLimiter

			push	#seg5
			push	timerNums(R9)
			push	#1+seg5
			push	#0

			call	#writeToLCD

			jmp		finalizeIntrp

incFourthDigit:
			incd	R10
			call 	#digitFourLimiter

			push	#seg6
			push	timerNums(R10)
			push	#1+seg6
			push	#0

			call	#writeToLCD

			jmp		finalizeIntrp

digitOneLimiter:
			cmp 	#0x14, R4				; Uneven numbers because the byte start at 0
			jlo		dontLimit
			mov.b 	#0, R4

			ret

digitTwoLimiter:
			cmp 	#0x14, R8				; Uneven numbers because the byte start at 0
			jlo		dontLimit
			mov.b 	#0, R8

			ret

digitThreeLimiter:
			cmp 	#0x0C, R9				; Uneven numbers because the byte start at 0
			jlo		dontLimit
			mov.b 	#0, R9

			ret

digitFourLimiter:
			cmp 	#0x14, R10				; Uneven numbers because the byte start at 0
			jlo		dontLimit
			mov.b 	#0, R10

			ret

dontLimit:
			ret

switchToNextNumber:
			cmp		#0,	&0x0A23				;
			jz		fixFirstDigit			;
											;
			cmp		#0, &0x0A32				;
			jz		fixSecondDigit			;
											; Prevent the number from staying empty due to flashNum subroutine
			cmp		#0,	&0x0A2E				; FIXME: The second digit is getting stuck (by what seems to be the colon)
			jz		fixThirdDigit			;
											;
			cmp		#0,	&0x0A27				;
			jz		fixFourthDigit			;

			inc		curLCDSeg

			cmp		#5, curLCDSeg
			jz		stopFlashingNum

			jmp 	finalizeIntrp

stopFlashingNum:
			clr		setTimerON				; Set the flag to not have any more intermittent flashing
			bis.b	#BIT2, &0x0A33			; Turn on the colon in the display
			bic.b 	#CCIE, &TA0CCTL0		; Disable the TACCRO Interrupt

			jmp finalizeIntrp

flashNum:
			cmp		#1, curLCDSeg
			jz		clearFirstDigit

			cmp		#2, curLCDSeg
			jz		clearSecondDigit

			cmp		#3, curLCDSeg
			jz		clearThirdDigit

			cmp		#4, curLCDSeg
			jz		clearFourthDigit

			jmp finalizeIntrp


clearFirstDigit:
			mov.b	#seg3, R7				;
			cmp		#0, 0x0A20(R7)			; Check if the first digit segment is empty, if so show the value
			jz		showFirstDigit			;

			mov.b 	0x0A20(R7), R6			; Save the value that was found in the LCD

			mov.b	#0, 0x0A20(R7)			; Clear the LCD Segment

			jmp		finalizeIntrp

showFirstDigit:
			mov.b 	R6, 0x0A20(R7)			; Show the value that was found in the LCD

			jmp		finalizeIntrp

fixFirstDigit:
			mov.b 	R6, 0x0A20(R7)			; Reestablish the value that was found in the LCD

			jmp		switchToNextNumber


clearSecondDigit:
			mov.b	#seg4, R7				;
			cmp		#0, 0x0A20(R7)			; Check if the second digit segment is empty, if so show the value
			jz		showSecondDigit			;

			mov.b 	0x0A20(R7), R6			; Save the value that was found in the LCD

			mov.b	#0, 0x0A20(R7)			; Clear the LCD Segment


			jmp		finalizeIntrp

showSecondDigit:
			mov.b 	R6, 0x0A20(R7)			; Show the value that was found in the LCD

			jmp		finalizeIntrp

fixSecondDigit:
			mov.b 	R6, 0x0A20(R7)			; Reestablish the value that was found in the LCD

			jmp		switchToNextNumber

clearThirdDigit:
			mov.b	#seg5, R7				;
			cmp		#0, 0x0A20(R7)			; Check if the third digit segment is empty, if so show the value
			jz		showThirdDigit			;

			mov.b 	0x0A20(R7), R6			; Save the value that was found in the LCD

			mov.b	#0, 0x0A20(R7)			; Clear the LCD Segment

			jmp		finalizeIntrp

showThirdDigit:
			mov.b 	R6, 0x0A20(R7)			; Show the value that was found in the LCD

			jmp		finalizeIntrp

fixThirdDigit:
			mov.b 	R6, 0x0A20(R7)			; Reestablish the value that was found in the LCD

			jmp		switchToNextNumber

clearFourthDigit:
			mov.b	#seg6, R7				;
			cmp		#0, 0x0A20(R7)			; Check if the fourth digit segment is empty, if so show the value
			jz		showFourthDigit			;

			mov.b 	0x0A20(R7), R6			; Save the value that was found in the LCD

			mov.b	#0, 0x0A20(R7)			; Clear the LCD Segment

			jmp		finalizeIntrp

showFourthDigit:
			mov.b 	R6, 0x0A20(R7)			; Show the value that was found in the LCD

			jmp		finalizeIntrp

fixFourthDigit:
			mov.b 	R6, 0x0A20(R7)			; Reestablish the value that was found in the LCD

			jmp		switchToNextNumber

startCountdown:
			mov		#1, countdownON

			ret

countdownSetup:
			mov		#125000, TA0CCR0		; Set clock cycles (1s)
			;bis.b	#BIT0, &P1OUT			; For debugging - turn on red LED
			mov     #CCIE, &TA0CCTL0        ; Enable TACCR0 interrupt

			mov.b	#1, curLCDSeg			; Reset the lcd location to avoid being unable to pause

			call 	#startCountdown

			jmp		finalizeIntrp

countdownLogic:
			cmp		#1, countdownON
			jz	 	decFourthDigit			; Reduce the lsn of the seconds

			jmp		finalizeIntrp

writeNums:
			push	#seg3
			push	timerNums(R4)
			push	#1+seg3
			push	#0

			call	#writeToLCD

			push	#seg4
			push	timerNums(R8)
			push	#1+seg4
			push	#0

			xor.b	#BIT2, &0x0A33

			call	#writeToLCD

			push	#seg5
			push	timerNums(R9)
			push	#1+seg5
			push	#0

			call	#writeToLCD

			push	#seg6
			push	timerNums(R10)
			push	#1+seg6
			push	#0

			call	#writeToLCD

			ret

decFourthDigit:
			cmp		#1, R10
			jlo		decThirdDigit

			decd	R10
			call 	#writeNums

			jmp		finalizeIntrp

decThirdDigit:
			mov.b	#0x12, R10				; Set the previous number to its max

			cmp		#1, R9
			jlo		decSecondDigit

			decd	R9
			call 	#writeNums

			jmp		finalizeIntrp

decSecondDigit:
			mov.b	#0x0A, R9				; Set the previous number to its max

			cmp		#1, R8
			jlo		decFirstDigit

			decd	R8
			call 	#writeNums

			jmp		finalizeIntrp

decFirstDigit:
			mov.b	#0x12, R8					; Set the previous number to its max

			cmp		#0, R4
			jz		setFirstToZero

			decd	R4
			call 	#writeNums

			jmp		finalizeIntrp

setFirstToZero:
			mov.b	#0, R4

			mov.b	#1, reachedZero

			jmp		timerDone

pauseTimer:
			bic.b 	#CCIE, &TA0CCTL0		; Disable the TACCRO Interrupt
			mov.b	#1, paused

			mov.b	#0, reachedZero

			jmp		finalizeIntrp

reenableTimer:
			mov.b	#0, paused
			mov     #CCIE, &TA0CCTL0        ; Enable TACCR0 interrupt

			jmp finalizeIntrp

timerDone:
			bic.b 	#CCIE, &TA0CCTL0		; Disable the TACCRO Interrupt

			jmp		finalizeIntrp

speedUp:
			rlc		TA0CCR0

			jmp finalizeIntrp

resume:
			mov		#CCIE, TA0CCTL0
			jz		reenableTimer

;-------------------------------------------------------------------------------


writeToLCD:
			pop		R14						; Place PC+2 value into a Register temporarily

			pop		R6						;
			pop		R7						; Printing the low byte to LCD
			mov.b 	R6, 0x0a20(R7)			;

			pop		R6						;
			pop		R7						; Printing the high byte to LCD
			mov.b 	R6, 0x0a20(R7)			;

			push 	R14						; Return PC+2 value to the stack

			ret

clearLCD:
			mov.w	#2, &LCDCMEMCTL
			ret

;-------------------------------------------------------------------------------

S1Logic:
			call	#delay					; For debouncing purposes

			cmp		#1, paused
			jz		writeTEAM

			cmp		#1, countdownON
			jz		speedUp


			cmp		#1, timerMenu			; If we're in the timer menu, increment current num
			jz		incTimerDigit


			mov.b 	#1, s2Disable

			mov.b 	#0,	timerMenu
			mov.b 	#1,	nameMenu

			inc 	LBpresses

			jmp		finalizeIntrp

S2Logic:
			call	#delay					; For debouncing purposes

			cmp		#5, curLCDSeg
			jhs		countdownSetup

			cmp		#1,	paused
			jz		resume

			cmp		#1, reachedZero
			jz		pauseTimer

			cmp		#1, countdownON
			jz 		pauseTimer

			cmp		#1, timerMenu			; If we're in the timer menu, switch to the following number
			jz		switchToNextNumber

			mov.b 	#0,	s2Disable

			mov.b 	#0,	nameMenu
			mov.b 	#1,	timerMenu

			inc		RBpresses

			jmp		finalizeIntrp

;-------------------------------------------------------------------------------

delay:
			mov		#65000, R11
loop		dec		R11
			jnz		loop
			ret

;-------------------------------------------------------------------------------


			.sect	".text:_isr:PORT1_ISR"
			.align	2
			.global	PORT1_ISR

PORT1_ISR:
			bit.b	#00000010b, &P1IFG		; Check for S1/P1.1 button pressing
			jnz		S1Logic

			call	#delay					; To prevent weird behavior when both buttons are pressed
			cmp		#1, s2Disable
			jz		finalizeIntrp

			bit.b	#00000100b, &P1IFG		; Check for S3/P1.2 button pressing
			jnz		S2Logic

			reti

finalizeIntrp:
			bic 	#00000010b, &P1IFG		;Borrar flag de P1.1
			bic 	#00000100b, &P1IFG		;Borrar flag de P1.2

			reti

;-------------------------------------------------------------------------------

TIMER_A0_ISR:
			;xor.b	#00000001b, P1OUT

			cmp		#1, countdownON
			jz		countdownLogic

			cmp 	#1, setTimerON
			jz		flashNum


			reti

;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack

;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect	".int37"
            .short	PORT1_ISR

			.sect   ".int44"
            .short  TIMER_A0_ISR

            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
			.end
