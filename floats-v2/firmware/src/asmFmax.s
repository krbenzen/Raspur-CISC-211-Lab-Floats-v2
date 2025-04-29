/*** asmFmax.s   ***/
#include <xc.h>
.syntax unified

@ Declare the following to be in data memory
.data  
.align

@ Define the globals so that the C code can access them

/* create a string */
.global nameStr
.type nameStr,%gnu_unique_object
    
/*** STUDENTS: Change the next line to your name!  **/
nameStr: .asciz "Benzen Raspur"  
 
.align

/* initialize a global variable that C can access to print the nameStr */
.global nameStrPtr
.type nameStrPtr,%gnu_unique_object
nameStrPtr: .word nameStr   /* Assign the mem loc of nameStr to nameStrPtr */

.global f0,f1,fMax,signBitMax,storedExpMax,realExpMax,mantMax
.type f0,%gnu_unique_object
.type f1,%gnu_unique_object
.type fMax,%gnu_unique_object
.type sbMax,%gnu_unique_object
.type storedExpMax,%gnu_unique_object
.type realExpMax,%gnu_unique_object
.type mantMax,%gnu_unique_object

.global sb0,sb1,storedExp0,storedExp1,realExp0,realExp1,mant0,mant1
.type sb0,%gnu_unique_object
.type sb1,%gnu_unique_object
.type storedExp0,%gnu_unique_object
.type storedExp1,%gnu_unique_object
.type realExp0,%gnu_unique_object
.type realExp1,%gnu_unique_object
.type mant0,%gnu_unique_object
.type mant1,%gnu_unique_object
 
.align
@ use these locations to store f0 values
f0: .word 0
sb0: .word 0
storedExp0: .word 0  /* the unmodified 8b exp value extracted from the float */
realExp0: .word 0
mant0: .word 0
 
@ use these locations to store f1 values
f1: .word 0
sb1: .word 0
realExp1: .word 0
storedExp1: .word 0  /* the unmodified 8b exp value extracted from the float */
mant1: .word 0
 
@ use these locations to store fMax values
fMax: .word 0
sbMax: .word 0
storedExpMax: .word 0
realExpMax: .word 0
mantMax: .word 0

.global nanValue 
.type nanValue,%gnu_unique_object
nanValue: .word 0x7FFFFFFF            

@ Tell the assembler that what follows is in instruction memory    
.text
.align

/********************************************************************
 function name: initVariables
    input:  none
    output: initializes all f0*, f1*, and *Max varibales to 0
********************************************************************/
.global initVariables
 .type initVariables,%function
initVariables:
    /* YOUR initVariables CODE BELOW THIS LINE! Don't forget to push and pop! */
    push {r4-r7, LR}
    movs r0, #0

    ldr  r4, =f0              /*first*/
    ldr  r5, =mantMax         /*last*/
zero_loop:
    str  r0, [r4], #4         /*store 0*/
    cmp  r4, r5
    ble  zero_loop
    pop  {r4-r7, LR}
    BX   LR
    
    /* YOUR initVariables CODE ABOVE THIS LINE! Don't forget to push and pop! */

    
/********************************************************************
 function name: getSignBit
    input:  r0: address of mem containing 32b float to be unpacked
            r1: address of mem to store sign bit (bit 31).
                Store a 1 if the sign bit is negative,
                Store a 0 if the sign bit is positive
                use sb0, sb1, or signBitMax for storage, as needed
    output: [r1]: mem location given by r1 contains the sign bit
********************************************************************/
.global getSignBit
.type getSignBit,%function
getSignBit:
    /* YOUR getSignBit CODE BELOW THIS LINE! Don't forget to push and pop! */
    push {LR}
    ldr  r2, [r0]
    lsrs r2, r2, #31
    str  r2, [r1]
    pop  {LR}
    BX   LR
    /* YOUR getSignBit CODE ABOVE THIS LINE! Don't forget to push and pop! */
    

    
/********************************************************************
 function name: getExponent
    input:  r0: address of mem containing 32b float to be unpacked
      
    output: r0: contains the unpacked original STORED exponent bits,
                shifted into the lower 8b of the register. Range 0-255.
            r1: always contains the REAL exponent, equal to r0 - 127.
                It is a signed 32b value. This function doesn't
                check for +/-Inf or +/-0, so r1 always contains
                r0 - 127.
                
********************************************************************/
.global getExponent
.type getExponent,%function
getExponent:
    /* YOUR getExponent CODE BELOW THIS LINE! Don't forget to push and pop! */
    push {LR}
    ldr   r2, [r0]
    lsrs  r0, r2, #23
    ands  r0, r0, #0xFF
    subs  r1, r0, #127
    pop   {LR}
    bx    LR    
    /* YOUR getExponent CODE ABOVE THIS LINE! Don't forget to push and pop! */
   

    
/********************************************************************
 function name: getMantissa
    input:  r0: address of mem containing 32b float to be unpacked
      
    output: r0: contains the mantissa WITHOUT the implied 1 bit added
                to bit 23. The upper bits must all be set to 0.
            r1: contains the mantissa WITH the implied 1 bit added
                to bit 23. Upper bits are set to 0. 
********************************************************************/
.global getMantissa
.type getMantissa,%function
getMantissa:
    /* YOUR getMantissa CODE BELOW THIS LINE! Don't forget to push and pop! */
    push {r2-r3, LR}
    ldr   r2, [r0]
    ubfx  r0, r2, #0, #23     /*22-0*/
    mov   r1, r0
    lsrs  r3, r2, #23        
    ands  r3, r3, #0xFF
    cmp   r3, #0
    beq   doneMant            
    cmp   r3, #0xFF
    beq   doneMant            
    ldr   r12, =0x00800000
    orr   r1, r1, r12         /*add the hidden1*/
doneMant:
    pop   {r2-r3, LR}
    BX    LR   
    /* YOUR getMantissa CODE ABOVE THIS LINE! Don't forget to push and pop! */
   


    
/********************************************************************
 function name: asmIsZero
    input:  r0: address of mem containing 32b float to be checked
                for +/- 0
      
    output: r0:  0 if floating point value is NOT +/- 0
                 1 if floating point value is +0
                -1 if floating point value is -0
      
********************************************************************/
.global asmIsZero
.type asmIsZero,%function
asmIsZero:
    /* YOUR asmIsZero CODE BELOW THIS LINE! Don't forget to push and pop! */
asmIsZero:
    push {LR}
    ldr   r1, [r0]
    cmp   r1, #0x00000000
    beq   plusZ
    cmp   r1, #0x80000000
    beq   minusZ
    movs  r0, #0
    pop   {LR}
    bx    LR
plusZ:
    movs  r0, #1
    pop   {LR}
    bx    LR
minusZ:
    movs  r0, #-1
    pop   {LR}
BX LR    
    /* YOUR asmIsZero CODE ABOVE THIS LINE! Don't forget to push and pop! */
   


    
/********************************************************************
 function name: asmIsInf
    input:  r0: address of mem containing 32b float to be checked
                for +/- infinity
      
    output: r0:  0 if floating point value is NOT +/- infinity
                 1 if floating point value is +infinity
                -1 if floating point value is -infinity
      
********************************************************************/
.global asmIsInf
.type asmIsInf,%function
asmIsInf:
    /* YOUR asmIsInf CODE BELOW THIS LINE! Don't forget to push and pop! */
.global asmIsInf
.type   asmIsInf,%function
asmIsInf:
    push {r2-r3, r12, lr}
    ldr   r2, [r0]
    lsrs  r3, r2, #23
    ands  r3, r3, #0xFF
    cmp   r3, #0xFF
    bne   notInf
    ldr   r12, =0x007FFFFF
    ands  r3, r2, r12
    bne   notInf                
    lsrs  r3, r2, #31  
    cmp   r3, #0
    it    eq
    moveq r0, #1
    movne r0, #-1
    pop   {r2-r3, r12, lr}
    bx    lr
notInf:
    movs  r0, #0
    pop   {r2-r3, r12, lr}
BX LR    
    /* YOUR asmIsInf CODE ABOVE THIS LINE! Don't forget to push and pop! */
   


    
/********************************************************************
function name: asmFmax
function description:
     max = asmFmax ( f0 , f1 )
     
where:
     f0, f1 are 32b floating point values passed in by the C caller
     max is the ADDRESS of fMax, where the greater of (f0,f1) must be stored
     
     if f0 equals f1, return either one
     notes:
        "greater than" means the most positive number.
        For example, -1 is greater than -200
     
     The function must also unpack the greater number and update the 
     following global variables prior to returning to the caller:
     
     signBitMax: 0 if the larger number is positive, otherwise 1
     realExpMax: The REAL exponent of the max value, adjusted for
                 (i.e. the STORED exponent - (127 o 126), see lab instructions)
                 The value must be a signed 32b number
     mantMax:    The lower 23b unpacked from the larger number.
                 If not +/-INF and not +/- 0, the mantissa MUST ALSO include
                 the implied "1" in bit 23! (So the student's code
                 must make sure to set that bit).
                 All bits above bit 23 must always be set to 0.     

********************************************************************/    
.global asmFmax
.type asmFmax,%function
asmFmax:   

    /* YOUR asmFmax CODE BELOW THIS LINE! VVVVVVVVVVVVVVVVVVVVV  */
    push {r4-r7, lr}

    /* store incoming operands for autograder */
    ldr  r2, =f0
    str  r0, [r2]
    ldr  r2, =f1
    str  r1, [r2]

    mov  r4, r0               /*0*/
    mov  r5, r1               /*1*/

    cmp  r4, r5               /*equal choose r5*/
    beq  choose_r4

    lsrs r6, r4, #31          /*0*/
    lsrs r7, r5, #31          /*1*/
    cmp  r6, r7
    bne  diffSigns

    cmp  r6, #0               
    beq  bothPos
    cmp  r4, r5              
    blt  choose_r4           /*smaller ones wins*/
    b    choose_r5
bothPos:
    cmp  r4, r5
    bgt  choose_r4
    b    choose_r5
diffSigns:
    cmp  r6, #0               
    beq  choose_r4
    b    choose_r5

    
    
choose_r4:
    ldr  r2, =fMax
    str  r4, [r2]
    mov  r3, r4
    b    unpack
choose_r5:
    ldr  r2, =fMax
    str  r5, [r2]
    mov  r3, r5

/*unpack the winner*/
unpack:
    lsrs r0, r3, #31
    ldr  r1, =sbMax
    str  r0, [r1]
    lsrs r0, r3, #23
    ands r0, r0, #0xFF
    ldr  r1, =storedExpMax
    str  r0, [r1]
    subs r1, r0, #127
    ldr  r2, =realExpMax
    str  r1, [r2]

    /*mantissa*/
    ubfx r1, r3, #0, #23
    mov  r0, r1
    lsrs r0, r3, #23
    ands r0, r0, #0xFF
    cmp  r0, #0
    beq  storeMant
    cmp  r0, #0xFF
    beq  storeMant
    ldr  r12, =0x00800000
    orr  r1, r1, r12
storeMant:
    ldr  r2, =mantMax
    str  r1, [r2]

    ldr  r0, =fMax           
    pop  {r4-r7, lr}
    bx   lr

BX LR    
    /* YOUR asmFmax CODE ABOVE THIS LINE! ^^^^^^^^^^^^^^^^^^^^^  */

   

/**********************************************************************/   
.end  /* The assembler will not process anything after this directive!!! */
