	AREA	Rpn, CODE, READONLY
	IMPORT	main
	EXPORT	start

start
;Student name: William Browne
;Student number: 09389822
;Program purpose: Evaluates an RPN expression

	LDR	R1, =rpnexp1   ; Stores the RPN expression address
	LDR R10, =0		   ; Variable = 0
	LDR R3, =0xa	   ; Divisor used in the var branch
	BL rpn			   ; Invoke rpn subroutine
	
stop	B	stop

; rpn Subroutine
; Evaluates an RPN expression represented as an ASCII string, returning a
; word-size value which is the result of the evaluated expression.
; Parameters : R0 : result (variable)
;              R1 : pString (value) address of ("pointer to") ASCII NULL-terminated string
;                   containing the RPN expression
;			  R10 : Variable used for values greater than 9	(will be either 1 or 0)
rpn
	STMFD sp!, {lr, R3-R12}		  ; Store registers and link register
while
	LDRB R0, [R1]				  ; Loads string from memory
	CMP R0,#0					  ; If (character != 0) 
	BEQ endwhile			      ; {
	CMP R10, #1					  ; If (variable != 1)
	BEQ	variable				  ; {
	LDR R10, =0					  ; Variable = 0
	CMP R0, #' '				  ;	If (character != ' ') 						  	  ;  
	BEQ endif					  ;	{

	CMP R0, #'0'				  ; If (character >= 0) 
	BLO else1					  ;	{
	CMP R0, #'9'				  ;	If (character <= 9)
	BHI else1					  ;	{
	LDR R10, =1					  ;	Variable = 1
	SUB R2, R0, #0x30			  ; Converting digit to decimal value
	STR R2, [sp, #-4]!			  ;	Pushing digit onto stack
 	B endif 					  ;	Get next character 

variable	
	CMP R0, #' '   				  ; If (character = ' ')
	BNE over9					  ; {
	LDR R10, =0					  ;	Variable = 0
	B endif					  	  ;	Get next character	
				  
over9
;A branch to deal with values greater than 9
	LDR R2, [sp], #4			  ;	Pop value off the stack
	MUL R2, R3, R2				  ;	Multiply this value by 10
	SUB R0, R0, #0x30			  ;	Convert to decimal value
	ADD R2, R2, R0				  ;	Add current digit with value multiplied by ten
	STR R2, [sp, #-4]!			  ;	Push the result onto the stack
	B endif						  ;	Get next character

else1	
	CMP R0, #'+'				   ; If character != '+' operator..
	BNE else2					   ; Check for another operator
	LDR R5, [sp], #4			   ; If R1 = '+'.. Pop value off the stack
	LDR R6, [sp], #4			   ;..Pop another value off the stack 
	ADD R2, R5, R6				   ; Add the two operands together (what was just popped off the stack)
	STR R2, [sp, #-4]!			   ; Push result of addition onto the stack
	B endif						   ; Move onto next character
else2
	CMP R0, #'-'				   ; If character != '-' operator..		
	BNE else3					   ; Check for another operator
	LDR R5, [sp], #4			   ; If character ='-'.. Pop value off the stack 
	LDR R6, [sp], #4			   ;.. Pop another value off the stack
	SUB R2, R5, R6				   ; Subtract the operands (what was just popped off the stack)
	STR R2, [sp, #-4]!			   ; Push result of subtraction onto the stack
	B endif						   ; Move onto next character
else3
	CMP R0, #'*'				   ; If character != '*' operator..
	BNE else4				  	   ; Branch to find another operator
	LDR R5, [sp], #4			   ; If character = '*'.. Pop value off the stack 
	LDR R6, [sp], #4			   ;.. Pop another value off the stack  
	MUL R2, R5, R6				   ; Multiply the operands (what was just popped off the stack)
	STR R2, [sp, #-4]!			   ; Push the result of multiplication onto the stack
	B endif						   ; Move onto next character
else4
	CMP R0, #'!'				   ; If character != '!' operator..
	BNE else5					   ; Check for another operator
	LDR R5, [sp], #4			   ; If character = '*'.. Pop value off the stack 
	SUB R6, R5, #1				   ; Subtract 1 from the value popped off the stack and store it in new tmp register
	MUL R0, R5, R6				   ; Multiply tmp value by the original
wh1
		CMP R6, #1				   ; While (temp value > 1)
		BLE endwh1				   ; {
		SUB R6, R6, #1			   ; tmp value = temp value - 1
		MUL R0, R6, R0 			   ; result = temp value * result
		B wh1					   ; }
else5
	CMP R0, #'n'				   ; If character != 'n' operator..
	BNE else6					   ; Check for another operator
	LDR R0, [sp], #4			   ; Otherwise.. Pop value off stack
; Implementing 2's complement to negate
	MVN R2, R0					   ; Invert the bits
	ADD R2, R2, #1				   ; Add 1 to the inverted value
	STR R2, [sp, #-4]!			   ; Push value onto the stack
	B endif						   ; Move onto next character
else6
	CMP R0, #'^'				   ; If character != '^' operator..
	BNE else7					   ; Check for another operator
	LDR R5, [sp], #4			   ; If character = '^'.. Pop value off stack
	LDR R6, [sp], #4			   ;.. Pop value off stack
	MOV R8, R5					   ; Store popped value in temp	storage
	MOV R9, R6					   ; Store popped value in temp storage
wh2
	CMP R8, #1					   ; while (3(R8) > 1)
	BLE endwh2					   ; {
 	MUL R2, R9, R6				   ; R2 = 5 * 5
	SUB R8, R8, #1				   ; R8 = R8 - 1   (temp power = temp power - 1)       
	MOV R9, R2					   ; R9 becomes result of calculating power
	B wh2						   ; }
endwh2
	STR R2, [sp, #-4]!			   ; Push value onto stack
	B endif						   ; Move onto next character

else7
	CMP R0, #'/'				   ; If character != '/' operator..
	BNE endif					   ; Check for another operator
	LDR R6, [sp], #4			   ; If character = '/'.. Pop value off stack - R6 = divisor
	LDR R5, [sp], #4			   ; Pop value off stack - R5 = dividend
	LDR R7, =0					   ; R7 = quotient

; R7 = quotient
; A = dividend
; B = divisor
; Note: R5 will contain the remainder
wh3
	CMP R5, R6		; If (a < b) 
	BLO endwh3		; {
	ADD R7, R7, #1	; quotient = quotient + 1
	SUB R5, R5, R6	; a = a - b
	B wh3			;}

endwh3
	STR R7, [sp, #-4]!	 ; Push quotient value onto stack
	B endif				 ; Move onto next character

endwh1
	STR R0, [sp, #-4]!			   ; Push value onto stack

endif 	
	ADD R1, R1, #1				   ; Move onto next character in memory
	B while						   ; Branch to beginning

endif2
	LDR R10, =0					   ; Variable = 0
	ADD R1, R1, #1				   ; Move onto next character
	B while						   ; Branch to beginning

; Main end to program where we have reached a zero in the string					
endwhile
	LDR R0, [sp], #4			   ; Pop value off stack
	LDMFD sp!, {R3-R12, PC}	       ; Restore registers

	AREA	TestData, DATA, READWRITE
	
rpnexp1	DCB	"33 4 ! n + 100 n 5 3 ^ + *",0

	END	