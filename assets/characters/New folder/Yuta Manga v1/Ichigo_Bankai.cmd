;===============================================================================
;-------------------------------Comandos----------------------------------------
;===============================================================================
[Remap]
x = x
y = y
z = z
a = a
b = b
c = c
s = s

[Command]
name = "Super Jump"
command = ~D,U
time = 10

;-| Supers |-------------------------------------------------------

[command]
name = "SUPER2"
command = y
time = 50

[command]
name = "SUPER1"
command = x
time = 50

;-| Specials |-------------------------------------------------------
[command]
name = "SPECIAL 1"
command = ~D,DF,F,a
time = 15

[command]
name = "SPECIAL 2"
command = ~D,DB,B,a
time = 15

[command]
name = "SPECIAL 3"
command = ~D,DF,F,b
time = 15

[command]
name = "SPECIAL 4"
command = ~D,DB,B,b
time = 15

[command]
name = "SPECIAL 5"
command = ~D,DF,F,c
time = 15

[command]
name = "SPECIAL 6"
command = ~D,DB,B,c
time = 15

[command]
name = "S1"
command = ~D,DB,B,y
time = 15

[command]
name = "S2"
command = ~D,DF,F,y
time = 15

[command]
name = "S3"
command = ~D,DB,B,z
time = 15

[command]
name = "S4"
command = ~D,DF,F,z
time = 15

[command]
name = "StrikeA+B"
command = a+b
time = 30

[command]
name = "StrikeB+C"
command = b+c
time = 30

[command]
name = "StrikeA+C"
command = a+c
time = 30

[command]
name = "StrikeY+Z"
command = a+b
time = 30

[command]
name = "SPECIAL 7"
command = ~B,DB,D,DF,F,a
time = 30

[command]
name = "SPECIAL 8"
command = ~F,DF,D,DB,B,a
time = 30

[command]
name = "SPECIAL 9"
command = ~B,DB,D,DF,F,b
time = 30

[command]
name = "SPECIAL 10"
command = ~F,DF,D,DB,B,b
time = 30

[command]
name = "SPECIAL 11"
command = ~B,DB,D,DF,F,c
time = 30

[command]
name = "SPECIAL 12"
command = ~F,DF,D,DB,B,c
time = 30

[Defaults]

;-| Double Tap |-----------------------------------------------------------
[Command]
name = "FF"     ;Required (do not remove)
command = F, F
time = 10

[Command]
name = "BB"     ;Required (do not remove)
command = B, B
time = 10
;-| 2/3 Button Combination |-----------------------------------------------
[Command]
name = "recovery" ;Required (do not remove)
command = x+y
time = 1

[Command]
name = "recovery"
command = y+z
time = 1

[Command]
name = "recovery"
command = x+z
time = 1

[Command]
name = "recovery"
command = a+b
time = 1

[Command]
name = "recovery"
command = b+c
time = 1

[Command]
name = "recovery"
command = a+c
time = 1
;-| Single Button |---------------------------------------------------------
[Command]
name = "a"
command = a
time = 1

[Command]
name = "b"
command = b
time = 1

[Command]
name = "c"
command = c
time = 1

[Command]
name = "x"
command = x
time = 1

[Command]
name = "y"
command = y
time = 1

[Command]
name = "z"
command = z
time = 1

[Command]
name = "s"
command = s
time = 1
;-| Single Dir |------------------------------------------------------------
[Command]
name = "fwd" ;Required (do not remove)
command = $F
time = 1

[Command]
name = "downfwd"
command = $DF
time = 1

[Command]
name = "down" ;Required (do not remove)
command = $D
time = 1

[Command]
name = "downback"
command = $DB
time = 1

[Command]
name = "back" ;Required (do not remove)
command = $B
time = 1

[Command]
name = "upback"
command = $UB
time = 1

[Command]
name = "up" ;Required (do not remove)
command = $U
time = 1

[Command]
name = "upfwd"
command = $UF
time = 1
;-| Hold Button |--------------------------------------------------------------
[Command]
name = "hold_x"
command = /x
time = 1

[Command]
name = "hold_y"
command = /y
time = 1

[Command]
name = "hold_z"
command = /z
time = 1

[Command]
name = "hold_a"
command = /a
time = 1

[Command]
name = "hold_b"
command = /b
time = 1

[Command]
name = "hold_c"
command = /c
time = 1

[Command]
name = "hold_s"
command = /s
time = 1
;-| Hold Dir |--------------------------------------------------------------
[Command]
name = "holdfwd" ;Required (do not remove)
command = /$F
time = 1

[Command]
name = "holddownfwd"
command = /$DF
time = 1

[Command]
name = "holddown" ;Required (do not remove)
command = /$D
time = 1

[Command]
name = "holddownback"
command = /$DB
time = 1

[Command]
name = "holdback" ;Required (do not remove)
command = /$B
time = 1

[Command]
name = "holdupback"
command = /$UB
time = 1

[Command]
name = "holdup" ;Required (do not remove)
command = /$U
time = 1

[Command]
name = "holdupfwd"
command = /$UF
time = 1
;---------- Comandos de la Inteligencia Artificial-----------------
; Comandos activadores
[Command]
name = "AI Prueba"
command = y+z ; con el botón A+B activamos la AI
time = 1

[Command]
name = "AI desactivado"
command = b+c ; Con el boton B+C desactivamos la AI
time = 1
;---------------------------------------------------------------------------
[Statedef -1]
;===========================================================================
;---------------------------Basicos-----------------------------------------
;---------------------------------------------------------------------------
; Correr Adelante
[State -1, Correr Adelante]
type = ChangeState
triggerall = stateno != 60
triggerall = stateno != 70
value = 60
trigger1 = command = "FF"
trigger1 = statetype != C
trigger1 = ctrl
;---------------------------------------------------------------------------
; Correr Atras
[State -1, Correr Atras]
type = ChangeState
triggerall = stateno != 60
triggerall = stateno != 70
value = 70
trigger1 = command = "BB"
trigger1 = statetype != C
trigger1 = ctrl
;---------------------------------------------------------------------------
; Super Jump
[State -1, Super Jump]
type = ChangeState
value = 80
trigger1 = command = "Super Jump"
trigger1 = statetype = S
trigger1 = ctrl
;===========================================================================
;SUPERS:
;===========================================================================
; Saigo no Getsuga Tenshou
[State -1, DOMINIO]
type = ChangeState
Triggerall = var(2) = 0
Triggerall = numhelper(3050) = 0
triggerall = numhelper(7999)=0
Triggerall = power >= 0
value = 153000
triggerall = command = "SUPER1"
Triggerall = statetype != A
trigger1 = ctrl
;===========================================================================
[State -1, Escada de jac�]
type = ChangeState
Triggerall = var(2) = 1
triggerall = numhelper(7999)=1
Triggerall = power >= 3000
value = 153002
triggerall = command = "SUPER1"
Triggerall = statetype != A
trigger1 = ctrl
;===========================================================================
; RIKA LIBERATION
[State -1, RIKA LIBERATION]
type = ChangeState
Triggerall = var(2) = 2
triggerall = numhelper(7999)= 0
Triggerall = power >= 3000
value = 4500
triggerall = command = "SUPER1"
Triggerall = statetype != A
trigger1 = ctrl
;===========================================================================
;SPECIALS:
;===========================================================================
; Don't Move/Stop
[State -1, Don't Move/Stop]
type = ChangeState
triggerall = numhelper(7999)=0
Triggerall = var(2) = 0
Triggerall = power >= 500
value = 61702
triggerall = command = "SPECIAL 1"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1, Slash air ]
type = ChangeState
triggerall = numhelper(7999)=0
Triggerall = var(2) = 0
Triggerall = numhelper(1450) = 0
Triggerall = power >= 500
value = 176301
triggerall = command = "SPECIAL 2"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1, Dai Shinkan]
type = ChangeState
Triggerall = var(2) = 0
triggerall = numhelper(7999)=0
value = 4609
triggerall = command = "SPECIAL 3"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1, Shinkan]
type = ChangeState
Triggerall = var(2) = 0
triggerall = numhelper(7999)=0
value = 1100
triggerall = command = "SPECIAL 4"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1, Rika]
type = ChangeState
triggerall = numhelper(7999)=0
Triggerall = var(2) = 0
Triggerall = power >= 100
value = 450
triggerall = command = "SPECIAL 5"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1, Rika]
type = ChangeState
triggerall = numhelper(7999)=0
Triggerall = var(2) = 0
Triggerall = power >= 100
value = 10090
triggerall = command = "SPECIAL 6"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Reverse cursed
[State -1, Reverse cursed]
type = ChangeState
triggerall = numhelper(7999)=0
Triggerall = var(2) = 0
Triggerall = power >= 500
value = 661101
triggerall = command = "holddown"
triggerall = command = "a"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Counter
[State -1, Counter]
type = ChangeState
Triggerall = var(2) = 0
triggerall = numhelper(7999)=0
value = 1000
triggerall = command = "holddown"
triggerall = command = "b"
Triggerall = statetype != A
trigger1 = ctrl


;===========================================================================
;SPECIALS Dominio:
;===========================================================================
;---------------------------------------------------------------------------
; Don't Move/Stop
[State -1, Don't Move/Stop]
type = ChangeState
Triggerall = var(2) = 1
triggerall = numhelper(7999)=1
Triggerall = power >= 500
value = 61702
triggerall = command = "holddown"
triggerall = command = "a"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1, Rika]
type = ChangeState
triggerall = numhelper(7999)=1
Triggerall = var(2) = 1
Triggerall = power >= 100
value = 450
triggerall = command = "holddown"
triggerall = command = "b"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
[State -1, itadori]
type = ChangeState
triggerall = numhelper(7999)=1
Triggerall = var(2) = 1
Triggerall = power >= 100
value = 1500
triggerall = command = "holddown"
triggerall = command = "c"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1, Cursed]
type = ChangeState
Triggerall = var(2) = 1
triggerall = numhelper(7999)=1
Triggerall = power >= 500
value = 67205
triggerall = command = "StrikeB+C"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Counter
[State -1, Counter]
type = ChangeState
Triggerall = var(2) = 1
triggerall = numhelper(7999)=1
value = 35400
triggerall = command = "StrikeA+B"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Reverse cursed
[State -1, Reverse cursed]
type = ChangeState
Triggerall = var(2) = 1
triggerall = numhelper(7999)=1
Triggerall = power >= 1000
value = 661101
triggerall = command = "y"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1, Dai Shinkan]
type = ChangeState
Triggerall = var(2) = 1
triggerall = numhelper(7999)=1
value = 4609
triggerall = command = "SPECIAL 1"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1, Attack jab air]
type = ChangeState
Triggerall = var(2) = 1
triggerall = numhelper(7999)=1
Triggerall = power >= 500
value = 1125
triggerall = command = "SPECIAL 2"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1, Shinkan]
type = ChangeState
Triggerall = var(2) = 1
triggerall = numhelper(7999)=1
value = 1100
triggerall = command = "SPECIAL 3"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1, Punchs atack]
type = ChangeState
Triggerall = power >= 1000
triggerall = numhelper(7999)=1
Triggerall = var(2) = 1
value = 3200
triggerall = command = "SPECIAL 4"
triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
;  Missil de gelo fino!!!
[State -1, Missil de gelo fino!!!]
type = ChangeState
triggerall = var(2) = 1
triggerall = numhelper(7999)=1
Triggerall = power >= 1000
value = 3220
triggerall = command = "SPECIAL 5"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
;===========================================================================
; RIKA LIBERATION
[State -1, RIKA LIBERATION]
type = ChangeState
Triggerall = var(2) = 1
triggerall = numhelper(7999)= 1
Triggerall = power >= 1000
value = 4500
triggerall = command = "SPECIAL 6"
Triggerall = statetype != A
trigger1 = ctrl
;===========================================================================
;SPECIALS Dominio:
;===========================================================================
;---------------------------------------------------------------------------
; Don't Move/Stop
[State -1, Don't Move/Stop]
type = ChangeState
Triggerall = var(2) = 1
Triggerall = power >= 500
value = 61702
triggerall = command = "holddown"
triggerall = command = "a"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1, Rika]
type = ChangeState
Triggerall = var(2) = 1
Triggerall = power >= 100
value = 450
triggerall = command = "holddown"
triggerall = command = "b"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
[State -1, itadori]
type = ChangeState
Triggerall = var(2) = 1
Triggerall = power >= 100
value = 1500
triggerall = command = "holddown"
triggerall = command = "c"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1, Cursed]
type = ChangeState
Triggerall = var(2) = 1
Triggerall = power >= 500
value = 67205
triggerall = command = "StrikeB+C"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Counter
[State -1, Counter]
type = ChangeState
Triggerall = var(2) = 1
value = 35400
triggerall = command = "StrikeA+B"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Reverse cursed
[State -1, Reverse cursed]
type = ChangeState
Triggerall = var(2) = 1
Triggerall = power >= 1000
value = 661101
triggerall = command = "y"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1, Dai Shinkan]
type = ChangeState
Triggerall = var(2) = 1
value = 4609
triggerall = command = "SPECIAL 1"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1, Attack jab air]
type = ChangeState
Triggerall = var(2) = 1
Triggerall = power >= 500
value = 1125
triggerall = command = "SPECIAL 2"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1, Shinkan]
type = ChangeState
Triggerall = var(2) = 1
value = 1100
triggerall = command = "SPECIAL 3"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1, Punchs atack]
type = ChangeState
Triggerall = power >= 1000
Triggerall = var(2) = 1
value = 3200
triggerall = command = "SPECIAL 4"
triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
;  Missil de gelo fino!!!
[State -1, Missil de gelo fino!!!]
type = ChangeState
triggerall = var(2) = 1
Triggerall = power >= 1000
value = 3220
triggerall = command = "SPECIAL 5"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
;===========================================================================
; RIKA LIBERATION
[State -1, RIKA LIBERATION]
type = ChangeState
Triggerall = var(2) = 1
Triggerall = power >= 1000
value = 4500
triggerall = command = "SPECIAL 6"
Triggerall = statetype != A
trigger1 = ctrl

;===========================================================================
; Sem Espada:
;===========================================================================
;Don't Move/Stop
[State -1, Don't Move/Stop]
type = ChangeState
Triggerall = var(2) = 2
triggerall = numhelper(7999)=0
Triggerall = power >= 1000
value = 61705
triggerall = command = "SPECIAL 1"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1, Serie punch ]
type = ChangeState
triggerall = numhelper(7999)=0
Triggerall = var(2) = 2
Triggerall = numhelper(1450) = 0
Triggerall = power >= 500
value = 1200
triggerall = command = "SPECIAL 2"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; energia
[State -1,Venha, Raio de energia do ceu]
type = ChangeState
triggerall = var(2) = 2
triggerall = numhelper(7999)=0
Triggerall = power >= 1000
value = 1503
triggerall = command = "SPECIAL 3"
Triggerall = statetype != A
trigger1 = ctrl

;---------------------------------------------------------------------------
[State -1, Punchs atack]
type = ChangeState
Triggerall = power >= 1000
triggerall = numhelper(7999)=0
Triggerall = var(2) = 2
value = 3200
triggerall = command = "SPECIAL 4"
triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; 
[State -1, Liberar]
type = ChangeState
triggerall = numhelper(7999)=0
Triggerall = var(2) = 2
Triggerall = power >= 500
value = 1434
triggerall = command = "SPECIAL 5"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Venha, Rika. Completa
[State -1,Venha, Rika. Completa]
type = ChangeState
triggerall = var(2) = 2
triggerall = numhelper(7999)=0
Triggerall = power >= 1000
value = 188100
triggerall = command = "SPECIAL 6"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Reverse Cursed
[State -1, Reverse Cursed]
type = ChangeState
triggerall = var(2) = 2
triggerall = numhelper(7999)=0
Triggerall = power >= 500
value = 661101
triggerall = command = "holddown"
triggerall = command = "a"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Manopla punch
[State -1,Manopla punch]
type = ChangeState
triggerall = var(2) = 2
triggerall = numhelper(7999)=0
Triggerall = power >= 1000
value = 3500
triggerall = command = "holddown"
triggerall = command = "b"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
[State -1, Cursed]
type = ChangeState
Triggerall = var(2) = 2
triggerall = numhelper(7999)=0
Triggerall = power >= 500
value = 67205
triggerall = command = "y"
Triggerall = statetype != A
trigger1 = ctrl

; Reiatsu Liberation
[State -1, Reiatsu Liberation]
type = ChangeState
Triggerall = numhelper(1060) = 0
Triggerall = numhelper(1060) = 1
Triggerall = power >= 500
value = 67206
triggerall = command = "holddown"
triggerall = command = "a"
Triggerall = statetype != A
trigger1 = ctrl


;---------------------------------------------------------------------------
; A - Vizard
[State -1, A - Vizard]
type = ChangeState
triggerall = var(2) = 2
triggerall = numhelper(7999)=0
value = 66200
triggerall = command = "a"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; B - Vizard
[State -1, A - Vizard]
type = ChangeState
triggerall = var(2) = 2
triggerall = numhelper(7999)=0
value = 61200
triggerall = command = "b"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Cursed puch
[State -1,Cursed puch]
type = ChangeState
triggerall = var(2) = 2
triggerall = numhelper(7999)=0
Triggerall = power >= 100
value = 229
triggerall = command = "c"
triggerall = statetype != A
trigger1 = ctrl 
trigger2 = numhelper(700) > 0
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; A - Domain
[State -1, A - Vizard]
type = ChangeState
Triggerall = var(2) = 1
value = 312
triggerall = command = "c"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; B - Domain
[State -1, A - Vizard]
type = ChangeState
Triggerall = var(2) = 1
value = 11300
triggerall = command = "a"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; C - Domain
[State -1, A - Vizard]
type = ChangeState
Triggerall = var(2) = 1
value = 400
triggerall = command = "b"
Triggerall = statetype != A
trigger1 = ctrl
;------------------------------------------------------------------------
;---------------------------------------------------------------------------
; A - Domain
[State -1, A - Vizard]
type = ChangeState
triggerall = numhelper(7999)=1
Triggerall = var(2) = 1
value = 312
triggerall = command = "c"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; B - Domain
[State -1, A - Vizard]
type = ChangeState
Triggerall = var(2) = 1
triggerall = numhelper(7999)=1
value = 11300
triggerall = command = "a"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; C - Domain
[State -1, A - Vizard]
type = ChangeState
Triggerall = var(2) = 1
triggerall = numhelper(7999)=1
value = 400
triggerall = command = "b"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; A Aire - Vizard
[State -1, A Aire - Vizard]
type = ChangeState
triggerall = var(2) = 2
value = 312
triggerall = command = "a"
Triggerall = statetype = A
trigger1 = ctrl
;---------------------------------------------------------------------------
; B Aire - Vizard
[State -1, B Aire - Vizard]
type = ChangeState
triggerall = var(2) = 2
value = 312
triggerall = command = "b"
Triggerall = statetype = A
trigger1 = ctrl
;---------------------------------------------------------------------------
; C Aire - Vizard
[State -1, C Aire - Vizard]
type = ChangeState
triggerall = var(2) = 2
Triggerall = numhelper(405) = 0
value = 400
triggerall = power >= 200
triggerall = command = "c"
Triggerall = statetype = A
trigger1 = ctrl
;===========================================================================
;--------------------------------Ataques Normales---------------------------
;--------------------------------------------------------------------------
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; HOS Cancelar Cancelar
[State -1, HOS Cancelar]
type = ChangeState
triggerall = var(2) = 1
triggerall = numhelper(7999)=1
value = 906
triggerall = command = "holddown"
triggerall = command = "s"
Triggerall = statetype != A
trigger2 = (stateNo=200 ||stateNo=210 ||stateNo=310 ||stateNo=300 ||stateNo=400||stateNo=610 ||stateNo=1100) && movecontact
trigger1 = ctrl
trigger3 =  stateNo=1300 >= 80 
trigger4 =  stateNo=1600 && movecontact
;----------------------------------------------------------------------------
;--------------------------------------------------------------------------
; BANKAI
[State -1, BANKAI]
type = ChangeState
TRIGGERALL = AILEVEL = 0
Triggerall = var(2) = 0
triggerall = numhelper(7999)=0
triggerall = Power >= 1000
value = 910
triggerall = command = "y"
Triggerall = statetype != A
trigger2 = (stateNo=200 ||stateNo=210 ||stateNo=310 ||stateNo=300 ||stateNo=400||stateNo=610 ||stateNo=1100) && movecontact
trigger1 = ctrl
trigger3 =  stateNo=1300 >= 80 
trigger4 =  stateNo=1600 && movecontact
;---------------------------------------------------------------------------
; BANKAI Cancelar
[State -1, BANKAI Cancelar]
type = ChangeState
TRIGGERALL = AILEVEL = 0
Triggerall = var(2) = 2
triggerall = numhelper(7999)=0
value = 915
triggerall = command = "holddown"
triggerall = command = "s"
Triggerall = statetype != A
trigger2 = (stateNo=200 ||stateNo=210 ||stateNo=310 ||stateNo=300 ||stateNo=400||stateNo=610 ||stateNo=1100) && movecontact
trigger1 = ctrl
trigger3 =  stateNo=1300 >= 80 
trigger4 =  stateNo=1600 && movecontact
;---------------------------------------------------------------------------
; A
[State -1, A]
type = ChangeState
triggerall = ailevel = 0
Triggerall = var(2) = 0
triggerall = numhelper(7999)=0
value = 200
triggerall = command = "a"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; B
[State -1, B]
type = ChangeState
triggerall = numhelper(7999)=0
Triggerall = var(2) = 0
value = 300
triggerall = command = "b"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; C
[State -1, C]
type = ChangeState
Triggerall = numhelper(405) = 0
triggerall = numhelper(7999)=0
Triggerall = var(2) = 0
value = 312
triggerall = command = "c"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Power Charge
[State -1, Power Charge]
type = ChangeState
triggerall = var(2) = 0
triggerall = numhelper(7999)=0
Triggerall = power < 8000
value = 500
triggerall = command = "s"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Power Charge
[State -1, Power Charge]
type = ChangeState
triggerall = var(2) = 2
triggerall = numhelper(7999)=0
Triggerall = power < 8000
value = 600
triggerall = command = "s"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; Power Charge
[State -1, Power Charge]
type = ChangeState
Triggerall = var(2) = 1
triggerall = numhelper(7999)=1
Triggerall = power < 8000
value = 500
triggerall = command = "s"
Triggerall = statetype != A
trigger1 = ctrl
;---------------------------------------------------------------------------
; A Aire
[State -1, A Aire]
type = ChangeState
triggerall = var(2) = 0
value = 600
triggerall = command = "a"
Triggerall = statetype = A
trigger1 = ctrl
;---------------------------------------------------------------------------
; B Aire
[State -1, B Aire]
type = ChangeState
triggerall = var(2) = 0
value = 610
triggerall = command = "b"
Triggerall = statetype = A
trigger1 = ctrl
;---------------------------------------------------------------------------
; C Aire
[State -1, C Aire]
type = ChangeState
triggerall = var(2) = 0
Triggerall = numhelper(405) = 0
value = 620
triggerall = power >= 200
triggerall = command = "c"
Triggerall = statetype = A
trigger1 = ctrl

