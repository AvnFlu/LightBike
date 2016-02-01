vblankwait:              ; Wait for vblank to make sure PPU is ready
  BIT $2002
  BPL vblankwait
  RTS


;;;;;;;;;;;;;;;

UpdateSprites:
  LDA bikeY1             ;;update all bike sprite info
  STA $0200
  
;  LDA #$40
;  STA $0201
  
  LDA attributes1
  STA $0202
  
  LDA bikeX1
  STA $0203
  
  ;;update paddle sprites
  RTS


;;;;;;;;;;;;;;;

LoadBackground:
  LDA $2002                ; read PPU status to reset the high/low latch
  LDA #$20
  STA $2006                ; write the high byte of $2000 address
  LDA #$00
  STA $2006                ; write the low byte of $2000 address
  LDX #$00                 ; start out at 0
  LDY #$00

  LDA #LOW(background)
  STA pointerLo            ; put the low byte of the address of background into pointer
  LDA #HIGH(background)
  STA pointerHi            ; put the high byte of the address into pointer

OuterLoop:
InnerLoop:
  LDA [pointerLo], y
  STA $2007                ; copy one background byte
  INY
  CPY #$00                 ; increment the offset for the low byte pointer of the background.
  BNE InnerLoop            

  INC pointerHi            ; increment the high byte pointer for the background
  INX
  CPX #$04                 
  BNE OuterLoop            ; the outer loop has to run four times to fully draw the background
 LoadBackgroundDone:

  JSR UpdateScore

  RTS


;;;;;;;;;;;;;;;

UpdateScore:               ;;update score on screen using background tiles             
  LDA score2
  CMP #$0A
  BCS TwoDigits            ; if the player's score is greater than or equal to 10, skip the next part

OneDigit:
  LDA #$20
  STA $2006
  LDA #$38
  STA $2006

  LDA score2
  CLC
  ADC #$B2
  STA $2007

  JSR RestorePPUADDR

  RTS                      ; return




TwoDigits:

UpdateTensDigit:
  LDA #$20
  STA $2006
  LDA #$37
  STA $2006

  LDA #$B3                 ; set the tens digit to 1
  STA $2007
UpdateTensDigitDone:

  LDA score2
  SEC
  SBC #$0A                 ; set the ones digit to [score2 - 10]
  CLC
  ADC #$B2                 ; add the offset for the tile's location in the PPU's tile memory
  STA $2007                

  JSR RestorePPUADDR

  RTS                      ; return
 
 
;;;;;;;;;;;;;;;

EnableRendering:
  LDA #%10010000       ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA $2000

  LDA #%00011110       ; enable sprites, enable background, no clipping on left side
  STA $2001
  RTS


;;;;;;;;;;;;;;;

DisableRendering:
  LDA #$00       
  STA $2000      ; disable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA $2001      ; disable sprites, disable background
  RTS


;;;;;;;;;;;;;;;

; restore the PPU address register ($2006) to its idle address ($0800) in order to render the next frame properly
RestorePPUADDR:
  LDA #$08             
  STA $2006
  LDA #$00
  STA $2006
  RTS


;;;;;;;;;;;;;;;

SetUp:

  LDA #$60
  STA wait                ;;start the waiting timer for the next round

  LDA #$00
  STA currDir1           ;; clear the current direction
  STA nextDir1           ;; clear the next planned direction
  STA startDir1          ;; dont let the selected starting direction carryover into the next round
  STA square1            ;; set bike1 the a top left square of a tile
  STA attributes1        ;; set bike1 to a light blue color

  LDA #$21
  STA tilePointer1Lo
  STA nxtTilePoint1Lo
  LDA #$00
  STA tilePointer1Hi
  STA nxtTilePoint1Hi
  STA nxtSquare1

  ;; aligns the bike's screen location with the tile+square location
  LDA #$18
  STA bikeY1
  
  LDA #$08
  STA bikeX1


  ;; clears the grid of all walls
  LDA #LOW(grid)
  STA pointerLo            ; put the low byte of the address of background into pointer
  LDA #HIGH(grid)
  STA pointerHi            ; put the high byte of the address into pointer

  LDX #$00                 ; start out at 0
  LDY #$00
ResetGridOuterLoop:
ResetGridInnerLoop:
  LDA #$00
  STA [pointerLo], y              ; copy one background byte
  INY
  CPY #$00                 ; increment the offset for the low byte pointer of the background.
  BNE ResetGridInnerLoop            

  INC pointerHi            ; increment the high byte pointer for the background
  INX
  CPX #$04                 
  BNE ResetGridOuterLoop            ; the outer loop has to run four times to fully draw the background
ResetGridDone:

SetUpDone:
  RTS


;;;;;;;;;;;;;;;

Tick:
  LDA #$01
  STA flag                  ; set the flag to update the background next NMI call

  LDA nextDir1              ; if no change was requested, skip the next part
  BEQ ChangeDirection1Done

ChangeDirection1:
  STA currDir1
  LDA #$00
  STA nextDir1
ChangeDirection1Done:

UpdateLocation:
  LDA nxtTilePoint1Hi
  STA tilePointer1Hi
  LDA nxtTilePoint1Lo
  STA tilePointer1Lo
  LDA nxtSquare1
  STA square1

  LDA currDir1
  CMP #UP
  BNE MovingUpDone
MovingUp:
  LDA square1
  AND #BOTTOMSQUARE   ; if the player is on a top square in the tile
  BEQ NextTileUp      ; fetch the tile above the current one
  
  LDA square1
  AND #%00000001   
  STA nxtSquare1         ; otherwise set the player on the upper square

  JMP UpdateLocationDone
MovingUpDone:


  CMP #DOWN
  BNE MovingDownDone
MovingDown:
  LDA square1
  AND #BOTTOMSQUARE    ; if the player is on a bottom square in the tile
  BNE NextTileDown     ; fetch the tile bellow the current one
  
  LDA square1
  ORA #%00000010    
  STA nxtSquare1          ; otherwise set the player on the bottom square
 
  JMP UpdateLocationDone
MovingDownDone:


  CMP #LEFT
  BNE MovingLeftDone
MovingLeft:
  LDA square1
  AND #RIGHTSQUARE     ; if the player is on a left square in the tile
  BEQ NextTileLeft     ; fetch the tile left of the current one
  
  LDA square1
  AND #%00000010    
  STA nxtSquare1          ; otherwise set the player on the left square

  JMP UpdateLocationDone
MovingLeftDone:


  CMP #RIGHT
  BNE MovingRightDone  ; this line should never be reached
MovingRight:
  LDA square1
  AND #RIGHTSQUARE     ; if the player is on a bottom square in the tile
  BNE NextTileRight    ; fetch the tile bellow the current one
  
  LDA square1
  ORA #%00000001  
  STA nxtSquare1          ; otherwise set the player on the right tile

  JMP UpdateLocationDone
MovingRightDone:


NextTileUp:
  SEC
  LDA tilePointer1Lo
  SBC #$20
  STA nxtTilePoint1Lo     ; Hex 20 (Dec 32) is the amount of tiles in a single row on the screen

  LDA tilePointer1Hi
  SBC #$00            
  STA nxtTilePoint1Hi     ; Add the carry bit to the high byte address

  LDA square1
  ORA #%00000010
  STA nxtSquare1          ; set the square to the one on the bottom of the tile, same column

  JMP UpdateLocationDone

NextTileDown:
  CLC
  LDA tilePointer1Lo
  ADC #$20             
  STA nxtTilePoint1Lo     ; Hex 20 (Dec 32) is the amount of tiles in a single row on the screen

  LDA tilePointer1Hi
  ADC #$00            
  STA nxtTilePoint1Hi     ; Add the carry bit to the high byte address

  LDA square1
  AND #%00000001
  STA nxtSquare1          ; set the square to the one on the top of the tile, same column

  JMP UpdateLocationDone

NextTileLeft:
  SEC
  LDA tilePointer1Lo
  SBC #$01
  STA nxtTilePoint1Lo

  LDA tilePointer1Hi
  SBC #$00            
  STA nxtTilePoint1Hi     ; Add the carry bit to the high byte address

  LDA square1
  ORA #%00000001
  STA nxtSquare1          ; set the square to the one on the right of the tile, same height

  JMP UpdateLocationDone 

NextTileRight:
  CLC
  LDA tilePointer1Lo
  ADC #$01
  STA nxtTilePoint1Lo

  LDA tilePointer1Hi
  ADC #$00             
  STA nxtTilePoint1Hi     ; Add the carry bit to the high byte address

  LDA square1
  AND #%00000010
  STA nxtSquare1          ; set the square to the one on the left of the tile, same height

UpdateLocationDone:

CheckCrash:
  CLC
  LDA #LOW(grid)
  STA pointerLo
  LDA #HIGH(grid)
  STA pointerHi

  LDA #%00000011
  LDX nxtSquare1
SetNextTileOperator:
  BEQ LocateNextGridTile
  ASL A
  ASL A
  DEX
  JMP SetNextTileOperator

LocateNextGridTile:  
  STA tileOperator
  LDY nxtTilePoint1Lo
  LDX nxtTilePoint1Hi
LocateNextGridTileLoop:
  BEQ FetchNextGridTile
  INC pointerHi
  DEX
  JMP LocateNextGridTileLoop

FetchNextGridTile:
  LDA [pointerLo], y
  AND tileOperator
  BEQ TickDone

  JSR Crashed

TickDone:

  RTS


;;;;;;;;;;;;;;;

Crashed:
  LDA #$50          ; set the wait counter
  STA wait

  LDA #STATECRASH   ; post-game wait, pauses everything to show who crashed.
  STA gamestate

WhoCrashed:
  LDA attributes1
  ORA #%00000011
  STA attributes1   ;set the color of the player who crashed to red

  RTS


;;;;;;;;;;;;;;;

ReadController1:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016
  LDX #$08
ReadController1Loop:  ; stores the input from controller1 in a variable so it can be read multiple times
  LDA $4016        
  LSR A               ; bit0 -> Carry
  ROL buttons1        ; bit0 <- Carry
  DEX
  BNE ReadController1Loop

CheckHeld:
  LDA heldDir1
  BEQ CheckAll                ;; if there was no pressed button from last read (heldDir = 0), read all buttons

;; if a button is held down
CheckPerpendiculars:
  AND #%00001100              ;; if the held direction is either up or down
  BNE HoldingVert

  LDA heldDir1
  AND #%00000011              ;; if the held direction is either left or right
  BNE HoldingHorz

HoldingVert:
  JSR CheckHorz
  JMP CheckPerpendicularsDone
HoldingHorz:
  JSR CheckVert
CheckPerpendicularsDone:
 

ReadHeld: 
  LDA buttons1
  AND heldDir1                ;; check if the held button from last contoller read is still being held
  BNE StillHeld

  LDA nextDir1
  STA heldDir1                ;; if held button is no longer held, set second button (or zero in none) as the held button
  JMP ReadController1Done

StillHeld:
  LDA nextDir1
  BNE ReadController1Done     ;; if a second key was pressed, that takes priority over the held button

  LDA heldDir1
  STA nextDir1
  JMP ReadController1Done     ;; if the held key is the only key pressed, set that as the next direction



;; if no button was held down
CheckAll:
  JSR CheckVert
  JSR CheckHorz
  LDA nextDir1
  STA heldDir1                ;; store any key pressed (or zero if none) as the held button
  JMP ReadController1Done


CheckVert:
ReadUp:
  LDA buttons1        ; player 1 - D-Pad Up
  AND #UP             ; only look at bit 3
  BEQ ReadUpDone      ; branch to ReadUpDone if button is NOT pressed (0)

  LDA currDir1
  CMP #DOWN
  BEQ ReadUpDone      ; ignore if moving down, bike cannot make 180 degree turns

  LDA #UP
  STA nextDir1 
ReadUpDone:           ; handling this button is done

ReadDown:
  LDA buttons1        ; player 1 - D-Pad Down
  AND #DOWN           ; only look at bit 2
  BEQ ReadDownDone    ; branch to ReadDownDone if button is NOT pressed (0)

  LDA currDir1
  CMP #UP
  BEQ ReadDownDone    ; ignore if moving up, bike cannot make 180 degree turns

  LDA buttons1
  AND #UP
  BNE NoDirection     ; if both up and down are held down they cancel out, do not change direction

  LDA #DOWN
  STA nextDir1 
ReadDownDone:         ; handling this button is done
  RTS

CheckHorz:
ReadLeft:
  LDA buttons1        ; player 1 - D-Pad Left
  AND #LEFT           ; only look at bit 1
  BEQ ReadLeftDone    ; branch to ReadLeftDone if button is NOT pressed (0)
  
  LDA currDir1
  CMP #RIGHT
  BEQ ReadLeftDone    ; ignore if moving right, bike cannot make 180 degree turns

  LDA #LEFT
  STA nextDir1
ReadLeftDone:         ; handling this button is done
  
ReadRight: 
  LDA buttons1        ; player 1 - D-Pad Right
  AND #RIGHT          ; only look at bit 0
  BEQ ReadRightDone   ; branch to ReadRightDone if button is NOT pressed (0)

  LDA currDir1
  CMP #LEFT
  BEQ ReadRightDone   ; ignore if moving right, bike cannot make 180 degree turns

  LDA buttons1
  AND #LEFT
  BNE NoDirection     ; if both left and right are held down they cancel out, do not change direction

  LDA #RIGHT
  STA nextDir1
ReadRightDone:        ; handling this button is done
  RTS



NoDirection:
  LDA #$00
  STA nextDir1
  RTS


ReadController1Done:
  RTS

  
;ReadController2:
;  LDA #$01
;  STA $4016
;  LDA #$00
;  STA $4016
;  LDX #$08
;ReadController2Loop:
;  LDA $4017
;  LSR A              ; bit0 -> Carry
;  ROL buttons2       ; bit0 <- Carry
;  DEX
;  BNE ReadController2Loop
;  RTS  