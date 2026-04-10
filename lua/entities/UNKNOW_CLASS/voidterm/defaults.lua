VOIDTERM = VOIDTERM or {}
VOIDTERM.Defaults = {}
VOIDTERM.Defaults["snake.void"] = [[
GFX 160 100
-- Snake head
SET X = 80
SET Y = 50
SET DX = 1
SET DY = 0
SET SPEED = 2
-- Food
RND 10 150
SET FX = %RND%
RND 15 90
SET FY = %RND%
SET SCORE = 0
SET FRAME = 0
-- Tail segments (up to 20)
SET TLEN = 3
SET T0X = 78
SET T0Y = 50
SET T1X = 76
SET T1Y = 50
SET T2X = 74
SET T2Y = 50
SET T3X = 0
SET T3Y = 0
SET T4X = 0
SET T4Y = 0
SET T5X = 0
SET T5Y = 0
SET T6X = 0
SET T6Y = 0
SET T7X = 0
SET T7Y = 0
SET T8X = 0
SET T8Y = 0
SET T9X = 0
SET T9Y = 0
SET T10X = 0
SET T10Y = 0
SET T11X = 0
SET T11Y = 0
SET T12X = 0
SET T12Y = 0
SET T13X = 0
SET T13Y = 0
SET T14X = 0
SET T14Y = 0
SET T15X = 0
SET T15Y = 0
SET T16X = 0
SET T16Y = 0
SET T17X = 0
SET T17Y = 0
SET T18X = 0
SET T18Y = 0
SET T19X = 0
SET T19Y = 0
MARK LOOP
    FILL
    ADD FRAME 1
    -- Draw decorative border (double line)
    RECT 0 0 160 100 GREEN
    RECT 2 2 156 96 DARKGREEN
    -- Corner decorations
    FRECT 0 0 4 4 GREEN
    FRECT 156 0 4 4 GREEN
    FRECT 0 96 4 4 GREEN
    FRECT 156 96 4 4 GREEN
    -- Read input (buffered)
    KEY K
    IF %K%==W THEN JUMP UP
    IF %K%==A THEN JUMP LEFT
    IF %K%==S THEN JUMP DOWN
    IF %K%==D THEN JUMP RIGHT
    JUMP MOVE
    MARK UP
    IF %DY%==1 THEN JUMP MOVE
    SET DX = 0
    SET DY = -1
    JUMP MOVE
    MARK DOWN
    IF %DY%==-1 THEN JUMP MOVE
    SET DX = 0
    SET DY = 1
    JUMP MOVE
    MARK LEFT
    IF %DX%==1 THEN JUMP MOVE
    SET DX = -1
    SET DY = 0
    JUMP MOVE
    MARK RIGHT
    IF %DX%==-1 THEN JUMP MOVE
    SET DX = 1
    SET DY = 0
    JUMP MOVE
    MARK MOVE
    -- Shift tail
    SET T19X = %T18X%
    SET T19Y = %T18Y%
    SET T18X = %T17X%
    SET T18Y = %T17Y%
    SET T17X = %T16X%
    SET T17Y = %T16Y%
    SET T16X = %T15X%
    SET T16Y = %T15Y%
    SET T15X = %T14X%
    SET T15Y = %T14Y%
    SET T14X = %T13X%
    SET T14Y = %T13Y%
    SET T13X = %T12X%
    SET T13Y = %T12Y%
    SET T12X = %T11X%
    SET T12Y = %T11Y%
    SET T11X = %T10X%
    SET T11Y = %T10Y%
    SET T10X = %T9X%
    SET T10Y = %T9Y%
    SET T9X = %T8X%
    SET T9Y = %T8Y%
    SET T8X = %T7X%
    SET T8Y = %T7Y%
    SET T7X = %T6X%
    SET T7Y = %T6Y%
    SET T6X = %T5X%
    SET T6Y = %T5Y%
    SET T5X = %T4X%
    SET T5Y = %T4Y%
    SET T4X = %T3X%
    SET T4Y = %T3Y%
    SET T3X = %T2X%
    SET T3Y = %T2Y%
    SET T2X = %T1X%
    SET T2Y = %T1Y%
    SET T1X = %T0X%
    SET T1Y = %T0Y%
    SET T0X = %X%
    SET T0Y = %Y%
    -- Move head
    SET X = %X% + %DX% * %SPEED%
    SET Y = %Y% + %DY% * %SPEED%
    -- Wrap edges (within border)
    IF %X% < 4 THEN SET X = 154
    IF %X% > 154 THEN SET X = 4
    IF %Y% < 4 THEN SET Y = 94
    IF %Y% > 94 THEN SET Y = 4
    -- Draw food (animated pulsing ring)
    CIRC %FX% %FY% 5 DARKRED
    FCIRC %FX% %FY% 3 RED
    FCIRC %FX% %FY% 1 ORANGE
    PX %FX% %FY% YELLOW
    -- Draw tail gradient (far=dark, near=bright)
    IF %TLEN% > 19 THEN PX %T19X% %T19Y% DARKGREEN
    IF %TLEN% > 18 THEN PX %T18X% %T18Y% DARKGREEN
    IF %TLEN% > 17 THEN PX %T17X% %T17Y% DARKGREEN
    IF %TLEN% > 16 THEN PX %T16X% %T16Y% DARKGREEN
    IF %TLEN% > 15 THEN FCIRC %T15X% %T15Y% 1 DARKGREEN
    IF %TLEN% > 14 THEN FCIRC %T14X% %T14Y% 1 DARKGREEN
    IF %TLEN% > 13 THEN FCIRC %T13X% %T13Y% 1 DARKGREEN
    IF %TLEN% > 12 THEN FCIRC %T12X% %T12Y% 1 DARKGREEN
    IF %TLEN% > 11 THEN FCIRC %T11X% %T11Y% 1 GREEN
    IF %TLEN% > 10 THEN FCIRC %T10X% %T10Y% 1 GREEN
    IF %TLEN% > 9 THEN FCIRC %T9X% %T9Y% 1 GREEN
    IF %TLEN% > 8 THEN FCIRC %T8X% %T8Y% 1 GREEN
    IF %TLEN% > 7 THEN FCIRC %T7X% %T7Y% 1 GREEN
    IF %TLEN% > 6 THEN FCIRC %T6X% %T6Y% 1 GREEN
    IF %TLEN% > 5 THEN FCIRC %T5X% %T5Y% 1 GREEN
    IF %TLEN% > 4 THEN FCIRC %T4X% %T4Y% 1 CYAN
    IF %TLEN% > 3 THEN FCIRC %T3X% %T3Y% 1 CYAN
    IF %TLEN% > 2 THEN FCIRC %T2X% %T2Y% 1 CYAN
    IF %TLEN% > 1 THEN FCIRC %T1X% %T1Y% 1 CYAN
    IF %TLEN% > 0 THEN FCIRC %T0X% %T0Y% 1 WHITE
    -- Draw head (big and bright)
    FCIRC %X% %Y% 3 GREEN
    FCIRC %X% %Y% 2 CYAN
    FCIRC %X% %Y% 1 WHITE
    -- Score panel (top bar)
    FRECT 5 4 70 10 DARKGREEN
    TEXT 7 5 WHITE SCORE: %SCORE%
    -- Check food collision
    SET CDX = %X% - %FX%
    SET CDY = %Y% - %FY%
    IF %CDX% > 5 THEN JUMP WAIT
    IF %CDX% < -5 THEN JUMP WAIT
    IF %CDY% > 5 THEN JUMP WAIT
    IF %CDY% < -5 THEN JUMP WAIT
    -- EAT!
    ADD SCORE 10
    ADD TLEN 1
    TONE 800 30
    TONE 1200 30
    -- New food position
    RND 10 150
    SET FX = %RND%
    RND 15 90
    SET FY = %RND%
    MARK WAIT
    WAIT 0.05
    JUMP LOOP
]]
VOIDTERM.Defaults["matrix.void"] = [[
GFX 160 100
-- Camera rotation (WASD to look around)
SET RX = 0
SET RY = 0
-- Rain drops spread in ALL directions (16 drops)
-- Front (+Z)
SET R0X = -40
SET R0Z = 80
SET R0Y = 50
SET R1X = 30
SET R1Z = 60
SET R1Y = -20
SET R2X = 60
SET R2Z = 100
SET R2Y = 30
SET R3X = -10
SET R3Z = 120
SET R3Y = -10
-- Behind (-Z)
SET R4X = -30
SET R4Z = -70
SET R4Y = 40
SET R5X = 20
SET R5Z = -90
SET R5Y = -30
SET R6X = 50
SET R6Z = -60
SET R6Y = 20
SET R7X = -50
SET R7Z = -110
SET R7Y = 50
-- Left (-X, +Z)
SET R8X = -90
SET R8Z = 40
SET R8Y = 0
SET R9X = -80
SET R9Z = -30
SET R9Y = 35
-- Right (+X, +Z)
SET R10X = 90
SET R10Z = 50
SET R10Y = -15
SET R11X = 80
SET R11Z = -40
SET R11Y = 25
-- More scattered
SET R12X = 0
SET R12Z = -50
SET R12Y = 60
SET R13X = -60
SET R13Z = 30
SET R13Y = -40
SET R14X = 70
SET R14Z = -80
SET R14Y = 10
SET R15X = -20
SET R15Z = 140
SET R15Y = -50
MARK LOOP
    FILL
    -- Read input for camera rotation (W=up, S=down)
    KEY K
    IF %K%==A THEN ADD RY -0.1
    IF %K%==D THEN ADD RY 0.1
    IF %K%==W THEN ADD RX 0.1
    IF %K%==S THEN ADD RX -0.1
    -- Set camera (position origin, look with rotation)
    CAM 0 0 0 %RX% %RY%
    -- Cubes in ALL directions (24 cubes surrounding camera)
    -- Front
    CUBE3 -40 -20 80 12 GREEN
    CUBE3 50 10 100 8 GREEN
    CUBE3 0 30 60 10 DARKGREEN
    CUBE3 30 -35 130 15 GREEN
    CUBE3 -20 0 150 6 DARKGREEN
    CUBE3 70 25 70 9 GREEN
    -- Behind
    CUBE3 -30 -15 -80 12 GREEN
    CUBE3 40 20 -100 10 GREEN
    CUBE3 -10 -30 -60 8 DARKGREEN
    CUBE3 20 10 -130 14 GREEN
    CUBE3 -50 35 -70 7 DARKGREEN
    CUBE3 60 -20 -90 11 GREEN
    -- Left
    CUBE3 -80 -10 30 10 GREEN
    CUBE3 -100 20 -20 8 DARKGREEN
    CUBE3 -70 -25 -50 12 GREEN
    CUBE3 -90 15 60 6 GREEN
    -- Right
    CUBE3 80 -10 30 10 GREEN
    CUBE3 100 20 -20 8 DARKGREEN
    CUBE3 70 -25 -50 12 GREEN
    CUBE3 90 15 60 6 GREEN
    -- Above/Below
    CUBE3 0 60 50 8 GREEN
    CUBE3 -30 -50 -40 10 DARKGREEN
    CUBE3 20 55 -60 7 GREEN
    CUBE3 -40 -45 80 9 DARKGREEN
    -- Animate rain drops (all fall down)
    SUB R0Y 2
    IF %R0Y% < -60 THEN SET R0Y = 60
    SET RBY = %R0Y% + 12
    LN3 %R0X% %R0Y% %R0Z% %R0X% %RBY% %R0Z% WHITE
    SET RBY = %R0Y% + 15
    SET RCY = %R0Y% + 25
    LN3 %R0X% %RBY% %R0Z% %R0X% %RCY% %R0Z% GREEN
    SUB R1Y 3
    IF %R1Y% < -60 THEN SET R1Y = 60
    SET RBY = %R1Y% + 10
    LN3 %R1X% %R1Y% %R1Z% %R1X% %RBY% %R1Z% WHITE
    SET RBY = %R1Y% + 14
    SET RCY = %R1Y% + 22
    LN3 %R1X% %RBY% %R1Z% %R1X% %RCY% %R1Z% GREEN
    SUB R2Y 1
    IF %R2Y% < -60 THEN SET R2Y = 60
    SET RBY = %R2Y% + 8
    LN3 %R2X% %R2Y% %R2Z% %R2X% %RBY% %R2Z% WHITE
    SET RBY = %R2Y% + 12
    SET RCY = %R2Y% + 20
    LN3 %R2X% %RBY% %R2Z% %R2X% %RCY% %R2Z% DARKGREEN
    SUB R3Y 2
    IF %R3Y% < -60 THEN SET R3Y = 60
    SET RBY = %R3Y% + 10
    LN3 %R3X% %R3Y% %R3Z% %R3X% %RBY% %R3Z% WHITE
    SUB R4Y 3
    IF %R4Y% < -60 THEN SET R4Y = 60
    SET RBY = %R4Y% + 12
    LN3 %R4X% %R4Y% %R4Z% %R4X% %RBY% %R4Z% WHITE
    SET RBY = %R4Y% + 16
    SET RCY = %R4Y% + 28
    LN3 %R4X% %RBY% %R4Z% %R4X% %RCY% %R4Z% GREEN
    SUB R5Y 2
    IF %R5Y% < -60 THEN SET R5Y = 60
    SET RBY = %R5Y% + 8
    LN3 %R5X% %R5Y% %R5Z% %R5X% %RBY% %R5Z% WHITE
    SET RBY = %R5Y% + 12
    SET RCY = %R5Y% + 18
    LN3 %R5X% %RBY% %R5Z% %R5X% %RCY% %R5Z% DARKGREEN
    SUB R6Y 4
    IF %R6Y% < -60 THEN SET R6Y = 60
    SET RBY = %R6Y% + 6
    LN3 %R6X% %R6Y% %R6Z% %R6X% %RBY% %R6Z% WHITE
    SUB R7Y 1
    IF %R7Y% < -60 THEN SET R7Y = 60
    SET RBY = %R7Y% + 14
    LN3 %R7X% %R7Y% %R7Z% %R7X% %RBY% %R7Z% WHITE
    SET RBY = %R7Y% + 18
    SET RCY = %R7Y% + 30
    LN3 %R7X% %RBY% %R7Z% %R7X% %RCY% %R7Z% GREEN
    SUB R8Y 2
    IF %R8Y% < -60 THEN SET R8Y = 60
    SET RBY = %R8Y% + 10
    LN3 %R8X% %R8Y% %R8Z% %R8X% %RBY% %R8Z% WHITE
    SUB R9Y 3
    IF %R9Y% < -60 THEN SET R9Y = 60
    SET RBY = %R9Y% + 12
    LN3 %R9X% %R9Y% %R9Z% %R9X% %RBY% %R9Z% GREEN
    SUB R10Y 2
    IF %R10Y% < -60 THEN SET R10Y = 60
    SET RBY = %R10Y% + 8
    LN3 %R10X% %R10Y% %R10Z% %R10X% %RBY% %R10Z% WHITE
    SUB R11Y 4
    IF %R11Y% < -60 THEN SET R11Y = 60
    SET RBY = %R11Y% + 6
    LN3 %R11X% %R11Y% %R11Z% %R11X% %RBY% %R11Z% GREEN
    SUB R12Y 1
    IF %R12Y% < -60 THEN SET R12Y = 60
    SET RBY = %R12Y% + 15
    LN3 %R12X% %R12Y% %R12Z% %R12X% %RBY% %R12Z% WHITE
    SUB R13Y 3
    IF %R13Y% < -60 THEN SET R13Y = 60
    SET RBY = %R13Y% + 10
    LN3 %R13X% %R13Y% %R13Z% %R13X% %RBY% %R13Z% GREEN
    SUB R14Y 2
    IF %R14Y% < -60 THEN SET R14Y = 60
    SET RBY = %R14Y% + 8
    LN3 %R14X% %R14Y% %R14Z% %R14X% %RBY% %R14Z% WHITE
    SUB R15Y 4
    IF %R15Y% < -60 THEN SET R15Y = 60
    SET RBY = %R15Y% + 12
    LN3 %R15X% %R15Y% %R15Z% %R15X% %RBY% %R15Z% DARKGREEN
    -- Floating triangles in all directions
    TRI3 -20 -10 90 -15 0 95 -25 5 85 GREEN
    TRI3 40 20 -80 45 15 -75 35 25 -85 DARKGREEN
    TRI3 -60 5 -40 -55 -5 -35 -65 10 -45 GREEN
    TRI3 70 -15 30 75 -10 35 65 -5 25 GREEN
    -- HUD text
    TEXT 2 2 GREEN MATRIX 3D
    TEXT 2 92 DARKGREEN WASD: LOOK
    WAIT 0.03
    JUMP LOOP
]]
VOIDTERM.Defaults["paint.void"] = [[
GFX 160 100
SET COL = 1
SET BRUSHSIZE = 1
SET PREVMB = 0
-- Draw initial UI
FRECT 0 0 160 9 GRAY
FRECT 2 1 7 7 WHITE
FRECT 11 1 7 7 RED
FRECT 20 1 7 7 GREEN
FRECT 29 1 7 7 BLUE
FRECT 38 1 7 7 CYAN
FRECT 47 1 7 7 MAGENTA
FRECT 56 1 7 7 YELLOW
FRECT 65 1 7 7 ORANGE
FRECT 74 1 7 7 PINK
FRECT 83 1 7 7 PURPLE
-- Brush size buttons
FRECT 100 1 7 7 GRAY
TEXT 101 2 WHITE 1
FRECT 109 1 7 7 GRAY
TEXT 110 2 WHITE 3
-- Clear button
FRECT 130 1 28 7 DARKRED
TEXT 132 2 WHITE CLR
-- Selection highlight (COL=1 = RED, starts at x=11, highlight wraps it)
RECT 10 0 9 9 WHITE
MARK LOOP
    MOUSE
    -- Only respond on mouse down
    IF %MB%==0 THEN JUMP IDLE
    -- === UI ZONE (top 9 px) ===
    IF %MY% >= 9 THEN JUMP CANVAS
    -- Color palette clicks
    IF %MX% < 9 THEN SET COL = 0
    IF %MX% >= 11 THEN IF %MX% < 18 THEN SET COL = 1
    IF %MX% >= 20 THEN IF %MX% < 27 THEN SET COL = 2
    IF %MX% >= 29 THEN IF %MX% < 36 THEN SET COL = 3
    IF %MX% >= 38 THEN IF %MX% < 45 THEN SET COL = 4
    IF %MX% >= 47 THEN IF %MX% < 54 THEN SET COL = 5
    IF %MX% >= 56 THEN IF %MX% < 63 THEN SET COL = 6
    IF %MX% >= 65 THEN IF %MX% < 72 THEN SET COL = 7
    IF %MX% >= 74 THEN IF %MX% < 81 THEN SET COL = 8
    IF %MX% >= 83 THEN IF %MX% < 90 THEN SET COL = 9
    -- Brush size
    IF %MX% >= 100 THEN IF %MX% < 107 THEN SET BRUSHSIZE = 1
    IF %MX% >= 109 THEN IF %MX% < 116 THEN SET BRUSHSIZE = 3
    -- Clear
    IF %MX% >= 130 THEN JUMP CLEARALL
    -- Redraw palette with new highlight
    FRECT 0 0 95 9 GRAY
    FRECT 2 1 7 7 WHITE
    FRECT 11 1 7 7 RED
    FRECT 20 1 7 7 GREEN
    FRECT 29 1 7 7 BLUE
    FRECT 38 1 7 7 CYAN
    FRECT 47 1 7 7 MAGENTA
    FRECT 56 1 7 7 YELLOW
    FRECT 65 1 7 7 ORANGE
    FRECT 74 1 7 7 PINK
    FRECT 83 1 7 7 PURPLE
    -- Highlight properly centered around selected swatch
    SET HX = 1 + %COL% * 9
    RECT %HX% 0 9 9 WHITE
    JUMP IDLE
    -- === CANVAS ZONE ===
    MARK CANVAS
    IF %BRUSHSIZE%==1 THEN JUMP SMALLBRUSH
    JUMP BIGBRUSH
    MARK SMALLBRUSH
    IF %COL%==0 THEN PX %MX% %MY% WHITE
    IF %COL%==1 THEN PX %MX% %MY% RED
    IF %COL%==2 THEN PX %MX% %MY% GREEN
    IF %COL%==3 THEN PX %MX% %MY% BLUE
    IF %COL%==4 THEN PX %MX% %MY% CYAN
    IF %COL%==5 THEN PX %MX% %MY% MAGENTA
    IF %COL%==6 THEN PX %MX% %MY% YELLOW
    IF %COL%==7 THEN PX %MX% %MY% ORANGE
    IF %COL%==8 THEN PX %MX% %MY% PINK
    IF %COL%==9 THEN PX %MX% %MY% PURPLE
    JUMP IDLE
    MARK BIGBRUSH
    IF %COL%==0 THEN FCIRC %MX% %MY% 2 WHITE
    IF %COL%==1 THEN FCIRC %MX% %MY% 2 RED
    IF %COL%==2 THEN FCIRC %MX% %MY% 2 GREEN
    IF %COL%==3 THEN FCIRC %MX% %MY% 2 BLUE
    IF %COL%==4 THEN FCIRC %MX% %MY% 2 CYAN
    IF %COL%==5 THEN FCIRC %MX% %MY% 2 MAGENTA
    IF %COL%==6 THEN FCIRC %MX% %MY% 2 YELLOW
    IF %COL%==7 THEN FCIRC %MX% %MY% 2 ORANGE
    IF %COL%==8 THEN FCIRC %MX% %MY% 2 PINK
    IF %COL%==9 THEN FCIRC %MX% %MY% 2 PURPLE
    JUMP IDLE
    MARK CLEARALL
    FILL
    -- Redraw full UI after clear
    FRECT 0 0 160 9 GRAY
    FRECT 2 1 7 7 WHITE
    FRECT 11 1 7 7 RED
    FRECT 20 1 7 7 GREEN
    FRECT 29 1 7 7 BLUE
    FRECT 38 1 7 7 CYAN
    FRECT 47 1 7 7 MAGENTA
    FRECT 56 1 7 7 YELLOW
    FRECT 65 1 7 7 ORANGE
    FRECT 74 1 7 7 PINK
    FRECT 83 1 7 7 PURPLE
    FRECT 100 1 7 7 GRAY
    TEXT 101 2 WHITE 1
    FRECT 109 1 7 7 GRAY
    TEXT 110 2 WHITE 3
    FRECT 130 1 28 7 DARKRED
    TEXT 132 2 WHITE CLR
    SET HX = 1 + %COL% * 9
    RECT %HX% 0 9 9 WHITE
    MARK IDLE
    SET PREVMB = %MB%
    WAIT 0.016
    JUMP LOOP
]]
VOIDTERM.Defaults["pong.void"] = [[
GFX 160 100
-- Ball
SET BX = 80
SET BY = 50
SET BDX = 2
SET BDY = 1
SET BSPD = 2
-- Trail positions (4 ghost frames)
SET T1X = 80
SET T1Y = 50
SET T2X = 80
SET T2Y = 50
SET T3X = 80
SET T3Y = 50
SET T4X = 80
SET T4Y = 50
-- Left paddle (player - W/S)
SET P1Y = 40
SET P1H = 16
-- Right paddle (AI)
SET P2Y = 40
SET P2H = 16
-- Scores (first to 5 wins)
SET S1 = 0
SET S2 = 0
SET WINSC = 5
-- Effects
SET FLASH = 0
SET HITS = 0
SET HITC = 0
MARK LOOP
    FILL
    -- Check win condition
    IF %S1% >= %WINSC% THEN JUMP P1WIN
    IF %S2% >= %WINSC% THEN JUMP P2WIN
    -- Flash effect on goal
    IF %FLASH% > 0 THEN FRECT 0 0 160 100 WHITE
    IF %FLASH% > 0 THEN SUB FLASH 1
    -- Draw decorative border
    RECT 0 0 160 100 DARKGREEN
    -- Center dashed line
    FRECT 79 4 2 4 DARKGREEN
    FRECT 79 12 2 4 DARKGREEN
    FRECT 79 20 2 4 DARKGREEN
    FRECT 79 28 2 4 DARKGREEN
    FRECT 79 36 2 4 DARKGREEN
    FRECT 79 44 2 4 DARKGREEN
    FRECT 79 52 2 4 DARKGREEN
    FRECT 79 60 2 4 DARKGREEN
    FRECT 79 68 2 4 DARKGREEN
    FRECT 79 76 2 4 DARKGREEN
    FRECT 79 84 2 4 DARKGREEN
    FRECT 79 92 2 4 DARKGREEN
    -- Center circle decoration
    CIRC 80 50 12 DARKGREEN
    CIRC 80 50 2 DARKGREEN
    -- Scores
    TEXT 55 3 GREEN %S1%
    TEXT 88 3 DARKGREEN /
    TEXT 92 3 DARKGREEN %WINSC%
    TEXT 95 3 GREEN %S2%
    -- Speed indicator
    TEXT 60 92 DARKGREEN SPD:%BSPD%
    -- Read input (W/S for left paddle)
    KEY K
    IF %K%==W THEN SUB P1Y 3
    IF %K%==S THEN ADD P1Y 3
    -- Clamp paddle 1
    IF %P1Y% < 2 THEN SET P1Y = 2
    IF %P1Y% > 82 THEN SET P1Y = 82
    -- AI for paddle 2 (follows ball)
    SET AIT = %P2Y% + 8
    IF %BY% > %AIT% THEN ADD P2Y 2
    IF %BY% < %AIT% THEN SUB P2Y 2
    IF %P2Y% < 2 THEN SET P2Y = 2
    IF %P2Y% > 82 THEN SET P2Y = 82
    -- Save trail position before moving
    SET T4X = %T3X%
    SET T4Y = %T3Y%
    SET T3X = %T2X%
    SET T3Y = %T2Y%
    SET T2X = %T1X%
    SET T2Y = %T1Y%
    SET T1X = %BX%
    SET T1Y = %BY%
    -- Move ball (speed affects distance)
    IF %BDX% > 0 THEN ADD BX %BSPD%
    IF %BDX% < 0 THEN SUB BX %BSPD%
    IF %BDY% > 0 THEN ADD BY 1
    IF %BDY% < 0 THEN SUB BY 1
    IF %BDY% > 1 THEN ADD BY 1
    IF %BDY% < -1 THEN SUB BY 1
    -- Ball bounce top/bottom
    IF %BY% < 4 THEN SET BDY = 1
    IF %BY% < 4 THEN SET BY = 4
    IF %BY% > 95 THEN SET BDY = -1
    IF %BY% > 95 THEN SET BY = 95
    -- Ball vs left paddle
    IF %BX% > 12 THEN JUMP CHECKP2
    IF %BX% < 5 THEN JUMP CHECKP2
    IF %BY% < %P1Y% THEN JUMP CHECKP2
    SET P1B = %P1Y% + %P1H%
    IF %BY% > %P1B% THEN JUMP CHECKP2
    -- HIT! Speed up every 3 hits
    SET BDX = 2
    SET BX = 13
    ADD HITS 1
    ADD HITC 1
    IF %HITC% >= 3 THEN ADD BSPD 1
    IF %HITC% >= 3 THEN SET HITC = 0
    IF %BSPD% > 5 THEN SET BSPD = 5
    TONE 800 20
    SET HITP = %BY% - %P1Y%
    IF %HITP% < 4 THEN SET BDY = -2
    IF %HITP% > 12 THEN SET BDY = 2
    MARK CHECKP2
    -- Ball vs right paddle
    IF %BX% < 147 THEN JUMP CHECKSCORE
    IF %BX% > 155 THEN JUMP CHECKSCORE
    IF %BY% < %P2Y% THEN JUMP CHECKSCORE
    SET P2B = %P2Y% + %P2H%
    IF %BY% > %P2B% THEN JUMP CHECKSCORE
    -- HIT! Speed up every 3 hits
    SET BDX = -2
    SET BX = 146
    ADD HITS 1
    ADD HITC 1
    IF %HITC% >= 3 THEN ADD BSPD 1
    IF %HITC% >= 3 THEN SET HITC = 0
    IF %BSPD% > 5 THEN SET BSPD = 5
    TONE 600 20
    SET HITP = %BY% - %P2Y%
    IF %HITP% < 4 THEN SET BDY = -2
    IF %HITP% > 12 THEN SET BDY = 2
    MARK CHECKSCORE
    -- Left wall (P2 scores)
    IF %BX% > 2 THEN JUMP CHECKRIGHT
    ADD S2 1
    SET BX = 80
    SET BY = 50
    SET BDX = 2
    SET BDY = 1
    SET BSPD = 2
    SET HITS = 0
    SET HITC = 0
    SET FLASH = 4
    TONE 200 100
    JUMP DRAWGAME
    MARK CHECKRIGHT
    -- Right wall (P1 scores)
    IF %BX% < 158 THEN JUMP DRAWGAME
    ADD S1 1
    SET BX = 80
    SET BY = 50
    SET BDX = -2
    SET BDY = -1
    SET BSPD = 2
    SET HITS = 0
    SET HITC = 0
    SET FLASH = 4
    TONE 200 100
    MARK DRAWGAME
    -- Draw left paddle with rounded caps
    FRECT 6 %P1Y% 4 %P1H% GREEN
    SET PIT = %P1Y% + 1
    SET PIH = %P1H% - 2
    FRECT 7 %PIT% 2 %PIH% CYAN
    SCIRC 8 %P1Y% 2 GREEN
    SET PBT = %P1Y% + %P1H%
    SCIRC 8 %PBT% 2 GREEN
    -- Draw right paddle with rounded caps
    FRECT 150 %P2Y% 4 %P2H% GREEN
    SET PIT = %P2Y% + 1
    SET PIH = %P2H% - 2
    FRECT 151 %PIT% 2 %PIH% CYAN
    SCIRC 152 %P2Y% 2 GREEN
    SET PBT = %P2Y% + %P2H%
    SCIRC 152 %PBT% 2 GREEN
    -- Draw ball trail (longer = faster)
    PX %T4X% %T4Y% DARKGREEN
    FCIRC %T3X% %T3Y% 1 DARKGREEN
    FCIRC %T2X% %T2Y% 2 DARKGREEN
    SCIRC %T1X% %T1Y% 3 DARKGREEN
    -- Draw ball (smooth anti-aliased)
    SCIRC %BX% %BY% 4 GREEN
    SCIRC %BX% %BY% 3 CYAN
    SCIRC %BX% %BY% 2 WHITE
    -- Controls hint
    TEXT 2 92 DARKGREEN W/S: MOVE
    WAIT 0.025
    JUMP LOOP
-- Win screens
MARK P1WIN
    FILL
    RECT 0 0 160 100 GREEN
    RECT 3 3 154 94 DARKGREEN
    TEXT 40 35 GREEN YOU WIN!
    TEXT 35 50 CYAN SCORE: %S1% - %S2%
    TEXT 30 70 DARKGREEN TAB TO EXIT
    WAIT 1
    JUMP P1WIN
MARK P2WIN
    FILL
    RECT 0 0 160 100 RED
    RECT 3 3 154 94 DARKRED
    TEXT 35 35 RED YOU LOSE!
    TEXT 35 50 WHITE SCORE: %S1% - %S2%
    TEXT 30 70 DARKGREEN TAB TO EXIT
    WAIT 1
    JUMP P2WIN
]]
