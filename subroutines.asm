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
  
;  LDA #$00
;  STA $0202
  
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
  RTS


;;;;;;;;;;;;;;;

DrawScore:
  ;;draw score on screen using background tiles
  ;;or using many sprites
  RTS
 
 
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