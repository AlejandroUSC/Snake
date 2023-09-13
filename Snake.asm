; Alejandro Martinez
; SNAKE! Started 11-15-2021

INCLUDE Irvine32.inc

COORDNATE STRUCT		; Self made coord-struct
						; Is compossed of SBYTE rather than BYTE in the coord struct
	X	SBYTE ?
	Y	SBYTE ?
	
COORDNATE ENDS			; make a struct to avoid making 2 arrays for x and y


.data
	; declare variables here

;Menu Prompts
	menuCaption		BYTE	"Snake Game	Menu", 0
	gridMenu		BYTE	"Would you like to play with a grid? (Yes)", 13, "Or, play with no grid (No)", 0
	selfPlayMsg		BYTE	"Would you like to play Snake?..",0
	compPlayMsg		BYTE	"Would you like to watch the computer play?..",0	; Wont be used now but will be used when 0 player mode is implemented
	userChoice		DWORD	6	; Want to play?
	gridChoice		DWORD	6	; Grid or no grid?
	gameBoard		BYTE	0	; 0 = with board 1 = no board
	scoreBoard		DWORD	0	; Keeps track of the total points

;Grid display stuff
						   ; 3   4   5   6   7   8   9   10  11  12  13  14
	grid			BYTE	'X','X','X','X','X','X','X','X','X','X','X','X'			;	A <---------- Y --------->
	gridSize = ($ - grid)															;	|
					BYTE	'X',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ','X'			;	|  
					BYTE	'X',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ','X'			;	X
					BYTE	'X',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ','X'			;	|	
					BYTE	'X',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ','X'			;	|
					BYTE	'X',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ','X'			;	V
					BYTE    'X',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ','X'
					BYTE    'X',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ','X'
					BYTE    'X',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ','X'			; head = 5	snake = 5 , 4 , 3
					BYTE    'X',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ','X'			; head = 6	snake = 6 , 5 , 4
					BYTE    'X',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ','X'
					BYTE	'X','X','X','X','X','X','X','X','X','X','X','X'			;	A <---------- Y --------->

	RowSize = 12	; 12 x 12 Grid

;Boardless
	farY	BYTE	50
	farX	BYTE	20

;Snake
	snake		COORDNATE	100 DUP(<?,?>)		; To be used
	snakeSize	BYTE		1				; Will keep track of the snake size
	head		COORDNATE	<0,0>			; Keeps track of snakes head, only to be incremented/decremented when moved
	tail		COORDNATE	<2,4>
	delaySpeed	DWORD		100				; Default speed for game with a boarder


; Exit Prompt
	collision	BYTE	0				; 0 = false, 1 = true you lost
	outOfBounds	BYTE	0
	lost		BYTE	"You lost", 0
	lostG		BYTE	"Game Over! Play Again! ", 0

; Keyboard
	inputKey	BYTE	?
	keyPrompt	BYTE	"Key Pressed:", 0
	keyMove		BYTE	? , 0
	scorePrompt	BYTE	"Score: ", 0

; Apple
	apple		COORDNATE <?,?>		; Will hold the apples coordnates

.code
main proc
	; write your code here
	pushad

;~~~~~~~~~~~~~~ M E N U ~ S T A R T ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	call menuScreen
	.IF (userChoice == 7)		; User entered no, go to endSnake 
		jmp	endSnake
	.ENDIF

	.IF (gridChoice == 7)		; User entered no, play boarderless 
		mov gameBoard, 1
		mov delaySpeed, 30
	.ENDIF

;~~~~~~~~~~~~~~ A C T U A L ~ G A M E ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ; ~~~~~~~~~~~ M A K E ~ A ~ L I L ~ S N A K E ~ H E A D ~~~~~~~~~~~~

  .IF gameBoard == 0		; If gameboard = 0 then say play with board
  	mov ecx, RowSize			; Equivalent for(int i = 0; i < 12; i++)
	mov eax, 0									
	loopPrintGrid:	
		push ecx				; push ecx to keep track of iterations		
		mov ebx, OFFSET grid	; set ebx to grid address				
		mov ecx, RowSize		; mov 12 into ecx, to print the cols
		push eax
		call printGrid			; for(int j = 0, j < 12; j++)
		pop eax
		call Crlf				; jump to next line
		add eax,1				; inc row 
		pop ecx					; restore ecx to go down an iteration
	loop loopPrintGrid
  .ENDIF

  mov esi, 0
  mov (snake[esi]).X, 2		; Snake0 will begin at coord X 2
  mov (snake[esi]).Y, 3		; Snake0 will begin at coord Y 2
  add snakeSize, 1
  add esi, TYPE COORDNATE
  mov (snake[esi]).X, 2		; Snake1 will begin at coord X 2
  mov (snake[esi]).Y, 4		; Snake1 will begin at coord Y 4

  call createApple			; Generate an apple

  ; ~~~~~~~~~~~ G A M E ~ P L A Y ~~~~~~~~~~~~~~~~~~

gamePlay:

  call ReadKey				; Initial read
  mov inputKey, al			; pass al into input key to determine what will happen

 moveTo:					; movements will return here once a key is pressed

  cmp inputKey, "w"				; 'W' inserted - snake will point up
  je  moveUp

  cmp inputKey, "a"				; 'A' inserted - snake will point left
  je  moveLeft

  cmp inputKey, "s"				; 'S' inserted - snake will point down
  je  moveDown

  cmp inputKey, "d"				; 'D' inserted - snake will point right
  je  moveRight

  jmp gamePlay				; Nothing was called or inserted, jmp to the top of the loop

  moveDown:					; Move down
    mov head.X,1					; move the snake down 1
	mov head.Y,0					; snake y remains the same
	mov keyMove, "v"

	call moveSnake				; Shifts the snake towards the head

	call checkBounds			; Checks if the snake needs to move across or if walls were hit
	.IF outOfBounds == 1		; If a wall was hit, end snake
		jmp endSnake
	.ENDIF

	call DrawSnake				; draw the snake and updates the removes position
	call consumeApple			; Checks if an apple has been consumed
	call checkCollision			; Checks if the snake has collided with either walls or self
	.IF collision == 1			; If collision == 1, then end snake (true)
		jmp	endSnake
	.ENDIF

	mov eax, delaySpeed			; delay purposed
	call Delay
	call ReadKey			  ; Check for key input
	mov inputKey, al
	jnz moveTo					; if not 0 (a key was pressed) go to moveTo
	jmp moveDown				; else loop

  moveRight:				; Move right
    mov head.X,0					; head x remains the same
	mov head.Y,1					; move the snake right 1
	mov keyMove, ">"

	call moveSnake				; Shifts the snake towards the head

	call checkBounds			; Checks if the snake needs to move across or if walls were hit
	.IF outOfBounds == 1		; If a wall was hit, end snake
		jmp endSnake
	.ENDIF

	call DrawSnake				; draw the snake and updates the removes position
	call consumeApple			; Checks if an apple has been consumed
	call checkCollision			; Checks if the snake has collided with either walls or self
	.IF collision == 1			; If collision == 1, then end snake (true)
		jmp	endSnake
	.ENDIF

	mov eax, delaySpeed			;delay by 250ms
	call Delay
	call ReadKey			 ; Check for key input 
	mov inputKey, al
	jnz moveTo					; if not 0 (a key was pressed) go to moveTo
	jmp moveRight				; else loop

  moveUp:					; Move up
    mov head.X,-1					; move the snake down -1 <- this is why we use SBYTEs
	mov head.Y,0					; head remains the same
	mov keyMove, "^"

	call moveSnake				; Shifts the snake towards the head

	call checkBounds			; Checks if the snake needs to move across or if walls were hit
	.IF outOfBounds == 1		; If a wall was hit, end snake
		jmp endSnake
	.ENDIF

	call DrawSnake				; draw the snake and updates the removes position
	call consumeApple			; Checks if an apple has been consumed
	call checkCollision			; Checks if the snake has collided with either walls or self
	.IF collision == 1			; If collision == 1, then end snake (true)
		jmp	endSnake
	.ENDIF

	mov eax, delaySpeed			; delay by 250ms
	call Delay
	call ReadKey			 ; Check for key input
	mov inputKey, al
	jnz moveTo					; if not 0 (a key was pressed) go to moveTo
	jmp moveUp					; else loop

  moveLeft:					; Move left
    mov head.X,0					; head remains the same
	mov head.Y,-1					; decrementing same situation, screen coords flipped
	mov keyMove, "<"

	call moveSnake				; Shifts the snake towards the head
	
	call checkBounds			; Checks if the snake needs to move across or if walls were hit
	.IF outOfBounds == 1		; If a wall was hit, end snake
		jmp endSnake
	.ENDIF

	call DrawSnake				; draw the snake and updates the removes position
	call consumeApple			; Checks if an apple has been consumed
	call checkCollision			; Checks if the snake has collided with either walls or self
	.IF collision == 1			; If collision == 1, then end snake (true)
		jmp	endSnake
	.ENDIF

	mov eax, delaySpeed			; delay by 250 ms
	call Delay
	call ReadKey			 ; Check for key input
	mov inputKey, al
	jnz moveTo					; if not 0 (a key was pressed) go to moveTo
	jmp moveLeft				; else loop

  jmp gamePlay

;~~~~~~~~~~~~~~ E N D ~ S N A K E ~ G A M E  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

endSnake:									; Ends the program regardless of the call this will be entered
	popad									; return all the original registers	
	mov eax, 100
	call Delay								; Screen will be delayed by 100 ms
	call exitScreen							; Displays the you lose screen
	call Clrscr								; Clears screen and done
	invoke ExitProcess,0
main endp

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;~~~~~~~~~~~~~~ S E L F ~ M A D E ~ P R O C E D U R E S ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

menuScreen proc
	pushad

	mov ebx, OFFSET menuCaption			; Display title
	mov edx, OFFSET	selfPlayMsg			; Display screenmsg
	call MsgBoxAsk

	.IF (EAX == 7)						; User entered no, end
		mov userChoice, eax
	.ENDIF

	mov ebx, OFFSET menuCaption			; Display title
	mov edx, OFFSET	gridMenu			; Display screenmsg
	call MsgBoxAsk
	
	.IF (EAX == 7)						; User entered no, end
		mov gridChoice, eax
	.ENDIF

	popad
	ret
menuScreen ENDP

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

exitScreen proc
	pushad

	mov ebx, OFFSET lost			; Display title
	mov edx, OFFSET	lostG			; Display screenmsg
	call MsgBox

	popad
	ret
exitScreen ENDP

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

printGrid proc
	pushad

	mul ecx						; row index * row size
	add ebx, eax				; row offset
	mov esi, 0					; column index

	L1:										; Print col
		movzx edx, BYTE PTR [ebx + esi]		; This iterates through each col of
		mov eax, edx						; the current row we are at
		call WriteChar						; Prints the char
		inc esi								; col++
		loop L1

	popad
	ret
printGrid ENDP

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

moveSnake proc				; Procedure shifts the snake towards head, and will draw it at the same time		
	pushad

	movzx esi, snakeSize					; This right here will record the last value of the snake, aka the tail
	sub esi, 1
	mov ah, (snake[esi * (TYPE COORDNATE)]).X					; Grabs the snakes last x	
	mov al, (snake[esi * (TYPE COORDNATE)]).Y					; Grabs the snakes last y
	mov tail.X, ah
	mov tail.Y, al
	call updateSnake

	.IF snakeSize == 1							; There is only 1 block in the snake
		
		.IF head.X == -1
			add snake[0].X, -1
		.ELSEIF head.Y == -1
			add snake[0].Y, -1
		.ELSE
			mov ah, head.x
			mov al, head.y
			add snake[0].X, ah
			add snake[0].Y, al
		.ENDIF

	.ELSE

		; This will print the array of snake

		movzx ecx, snakeSize							; <2,2> <2,1>
		sub ecx, 1										; 2,2	2,2

		movzx esi, snakeSize
		sub esi, 1
		
	  shift:						; for(int i = snake.size -1 ; i > 0; i--)
		mov ah, (snake[esi * TYPE COORDNATE - TYPE COORDNATE]).X	; 3 [2] 1 ---> 3 2 [2]
		mov al, (snake[esi * TYPE COORDNATE - TYPE COORDNATE]).Y
										
		mov (snake[esi * TYPE COORDNATE]).X, ah				; 3 2 1 ; 3 3 2
		mov (snake[esi * TYPE COORDNATE]).Y, al
		sub esi, 1				

	  loop shift
									; 4 3 2 
		.IF head.X == -1								; This if else statememnt adds the head to snake head
			add (snake[0]).X, -1
		.ELSEIF head.Y == -1
			add (snake[0]).Y, -1
		.ELSE
			mov ah, head.x
			mov al, head.y
			add (snake[0]).X, ah
			add (snake[0]).Y, al
		.ENDIF
	.ENDIF

	popad
	ret
moveSnake ENDP

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	;

updateSnake proc					
	pushad

	mov dh, tail.X					; DH will hold the value of our tails X
	mov dl, tail.Y					; DH will hold the value of our tails Y
	call Gotoxy
	mov eax, white + (black*16)		; This will take our cursors to said x and y postion
	call SetTextColor				; And set the snakes tail to black, as we have now left that position
	mov al, ' '
	call WriteChar

	popad
	ret
updateSnake ENDP

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	;

drawSnake proc
	pushad

	movzx ecx, snakeSize							; <5,5> <5,4>
	movzx esi, snakeSize							; snakesize into esi
	sub esi, 1
	 shift:
	 	;sub esi, TYPE snake						; Goes through the snake array
		mov dh, (snake[esi * TYPE COORDNATE]).X		; Prints out each and every one
		mov dl, (snake[esi * TYPE COORDNATE]).Y
		sub esi, 1
		call Gotoxy			
		mov eax, black + (green*16)
		call SetTextColor
		mov al, ' '											
		call WriteChar							
	  loop shift

	mov dh, 30						; This set the key pressed prompt
	mov dl, 10
	call Gotoxy
	mov eax, white + (black*16)
	call SetTextColor
	mov edx, OFFSET keyPrompt
	call Writestring

	mov dh, 30						; this sets the key prompt
	mov dl, 25
	call Gotoxy
	mov eax, white + (black*16)
	call SetTextColor
	mov edx, OFFSET keyMove
	call Writestring

	mov dh, 32						; this sets the score prompt
	mov dl, 10
	call Gotoxy
	mov eax, white + (black*16)
	call SetTextColor
	mov edx, OFFSET scorePrompt
	call Writestring

	mov dh, 32						; this sets the score prompt
	mov dl, 20
	call Gotoxy
	mov eax, white + (black*16)
	call SetTextColor
	mov eax, scoreBoard
	call WriteInt

	popad
	ret
drawSnake ENDP

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	;

checkBounds PROC
	pushad
	; This commented out section is if you want to play with a boarder

	.IF gameboard == 0
		.IF snake.X == 0 || snake.X == 11		; Checks if the snake has hit the top or bottom wall
			mov outOfBounds, 1
		.ENDIF
	
		.IF snake.Y == 0 || snake.Y == 11		; Checks if the snake has hit the left or right wall
			mov outOfBounds, 1
		.ENDIF
	.ELSE

		mov ah, farX
		mov al, farY
		.IF snake.X == -1		; If the snake head goes past the top of the screen
			sub ah, 1			;	dec ah by 1 so snake wont glitch
			mov snake.X, ah		;
		.ELSEIF snake.X == ah	; If the snake hits the bottom of the "grid" move to 0
			mov snake.X, 0
		.ELSEIF snake.Y == -1	; if the snake hits the left of the screen move to grid edge y -1
			sub al, 1
			mov snake.Y, al
		.ELSEIF snake.Y == al	; if the snake hits the right of the screen move to 0
			mov snake.Y, 0
		.ENDIF

	.ENDIF
	popad
	ret
checkBounds ENDP

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	;

createApple PROC
	pushad

 makeApple:
	call Randomize
	.IF gameboard == 0
		mov eax, 10				; This works with the board
	.ELSE
		movzx eax, farX			; This is for boarderless
		sub eax, 2				; This is for boarderless
	.ENDIF
	call RandomRange		; X coord - Generates a random x coord
	mov dh, al
	add dh, 1
	mov apple.x, dh

	call Randomize

	.IF gameboard == 0
		mov eax, 10				; This works with the board
	.ELSE
		movzx eax, farY			; This is for boarderless
		sub eax, 2				; This is for boarderless
	.ENDIF
	call RandomRange		; Y coord - Generates a random y coord
	mov dl, al
	add dl, 1
	mov apple.y, dl

	movzx ecx, snakeSize
	movzx esi, snakeSize	; snakesize into esi
	sub esi, 1
  checkValid:										;; This loop checks if the placement of the apple
		mov ah, (snake[esi * TYPE COORDNATE]).X		;; is not within the snake
		mov al, (snake[esi * TYPE COORDNATE]).Y		;; Iterates through whole snake and checks its coords
		sub esi, 1									;; with the apples coords
		
		.IF ah == apple.x && al == apple.y			;; If there is a match, restart the function
			jmp makeApple							;; and create a new apple
		.ENDIF
	  loop checkValid

	call Gotoxy					; The following code draws the apple
	mov eax, black + (red*16)
	call SetTextColor
	mov al, ' '											
	call WriteChar
	popad
	ret
createApple ENDP

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

consumeApple PROC
	pushad

	; This function will only work if there has been a collision betwen the snakes head and an apple
	; Add 1 to the end of snake and create a new apple
	mov ah, apple.X
	mov al, apple.Y
	.IF snake.X == ah && snake.Y == al
		movzx esi, snakeSize						; Move the size of snake into esi, this will cause us to insert at snake[size]

		mov ah, tail.X								; Move the tail.X into ah
		mov al, tail.Y								; Move the tail.Y into ah

		mov (snake[esi * TYPE COORDNATE]).X, ah		; Move the tail memory into snakes new last pos	
		mov (snake[esi * TYPE COORDNATE]).Y, al		; {0,1,2} = size of 3 -> snake[3] = new pos

		mov  ah, (snake[esi* TYPE COORDNATE]).X		; Move this new pos.x into ah
		mov  al, (snake[esi*TYPE COORDNATE]).Y		; Move this new pos.y into al

		mov tail.X, ah								; Move ah into tail.x
		mov tail.Y, al								; Move al into tail.y

		add snakeSize, 1							; Inc snake size
		add scoreBoard, 100							; Add 100 to the scoreboard
		call createApple
	.ENDIF

	popad
	ret
consumeApple ENDP

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

checkCollision PROC			;  1 2 3 4 5
	pushad					;  2 1 3 4 5

	movzx ecx, snakeSize
	sub ecx, 1
	movzx esi, snakeSize	; snakesize into esi
	sub esi, 1
checkValid:
		mov ah, (snake[esi * TYPE COORDNATE]).X		;This is the snakes bodies x
		mov al, (snake[esi * TYPE COORDNATE]).Y		; this is the snakes bodies y
		sub esi, 1
		
		.IF ah == snake.x && al == snake.y			; if the head is the same coords as any body piece
			mov collision, 1						; you lose
			popad
			ret
		.ENDIF
	  loop checkValid
	popad
	ret
checkCollision ENDP
end main