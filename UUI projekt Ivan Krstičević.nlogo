extensions [ matrix ]
globals [ generation
          newspecies ;brojač najnovije generacije
          x
          y
          ]

breed [ neurons neuron ]
breed [ ducks duck ]
breed [ testers tester ]
breed [ grannies granny ]
ducks-own [
              energy       ;energija
              steps        ;broj koraka
              w1           ;matrica težina input-hidden
              w2           ;matrica težina hidden-hidden
              w3           ;matrica težina hidden-output
              in           ;input matrica
              a1           ;hidden matrica
              out          ;output matrica
              g            ;generacija
              speed        ;brzina - agenti moraju imati, osim kill = 1, i određenu brzinu
              show_brain   ;za označavanje čija mreža se prikazuje
            ]
;--- setup -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

to setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  ask patches [ set pcolor ifelse-value ( pxcor < 20 ) [ white ] [ 39.9 ] ]
  setup-neurons
  setup-links
  ask patches with [ pxcor < 19 and pxcor > -40 and pycor > -20 and pycor < 20   ][ ;trava raste u početku
    if pcolor = white [
      if random 100 < crumbs-grow-rate
        [ set pcolor 6.9 ]]]
  set-default-shape ducks "default"
  set-default-shape grannies "person"
  set-default-shape testers "person"
  set generation 1
  create-ducks number [
    set w1 matrix:from-column-list  n-values 6 [ n-values 9 [ ifelse-value ( random 4 = 1) [0] [random-float 2 - 1 ] ]]
    set w2 matrix:from-column-list  n-values 6 [ n-values 6 [ ifelse-value ( random 2 = 1) [0] [random-float 2 - 1 ] ]]  ;hidden neuroni među sobom imaju slabije veze
    set w3 matrix:from-column-list  n-values 4 [ n-values 6 [ ifelse-value ( random 4 = 1) [0] [random-float 2 - 1 ] ]]
    set in  matrix:from-column-list  n-values 9 [ n-values 1 [ 0 ]]
    set a1  matrix:from-column-list  n-values 6 [ n-values 1  [ 0 ]]
    set out matrix:from-column-list  n-values 4 [ n-values 1  [ 0 ]]
    matrix:set in 0 0 1
    matrix:set a1 0 0 1
    set color ( random 12 + 1) * 10 + 5
    setxy ( random-float 59 - 40 ) random-ycor
    set energy 10
    set steps -3
    set g 1
    set size 2
    set show_brain 0
  ]
  create-grannies gnumber[
    setxy ( random-float 59 - 40 ) random-ycor
    set size 4.5
    set heading random 360
  ]
  create-testers 1 [ set size 2 ]
  set newspecies number
  setup-plot
  do-plot
end


to setup-neurons     ;prikaz neuronske mreže sa desne strane
  set-default-shape neurons "circle"
  let i 0
  while [i < 5] [
    create-neurons 1 [ setxy ( 26 + ( i * 2 ) ) 16.5 ]
    set i i + 1
  ]
  set i 0
  while [i < 2] [
    create-neurons 1 [ setxy ( 28 * cos ( ( 360 / 90 ) * i + 97 ) + 27 ) ( 28 * sin ( ( 360 / 90 ) * i + 97 ) - 15) ]
    set i i + 1
  ]
  set i 0
  while [i < 2] [
    create-neurons 1 [ setxy  ( 28 * cos ( ( -360 / 90 ) * i + 83 ) + 33 ) ( 28 * sin ( ( -360 / 90 ) * i + 83 ) - 15) ]
    set i i + 1
  ]
  set i 0
  while [i < 6] [
    create-neurons 1 [ setxy ( 8 * cos ( ( 360 / 6 ) * i + 360 / 12 ) + 30 ) ( 6 * sin ( ( 360 / 6 ) * i + 360 / 12 ) - 1.5) ]
    set i i + 1
  ]
  set i 0
  while [i < 4] [
    create-neurons 1 [ setxy ( 27 + ( i * 2 ) ) -16.5 ]
    set i i + 1
  ]
  create-neurons 1 [ setxy 19.5 20.4
    hide-turtle ]
  create-neurons 1 [ setxy 19.5 -20.4
    hide-turtle ]
  ask neurons [ set color blue ]
end

to setup-links
  ask neurons [ create-links-with other neurons [ set thickness 0.1
      set color white ] ]
  ask links [ hide-link ]
  ask link 19 20 [ show-link ;crta koja odvaja svijet od prikaza mreže
    set color black ]
end

;----- kretanje --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

to go
   ifelse not test [
   ask testers [ hide-turtle ]
   ask patches with [ pxcor < 19 and pxcor > -40 and pycor > -20 and pycor < 20   ] [
      if ( random 100 < crumbs-grow-rate ) and ( count patches with [ pcolor < 9.9 and pcolor > 6 ] < 50 )
        [ set pcolor 6.9 ] ]
   ask ducks [ show-turtle ]
   if ( mouse-inside? and mouse-down? and any? ducks-on patch round mouse-xcor round mouse-ycor )
     [ ask ducks [ set show_brain 0 ]  ;resetira prikaz mreže
       watch one-of ducks-on patch round mouse-xcor round mouse-ycor
       ask subject [ set show_brain 1 ] ]
   if not any? ducks [ stop ]
   set generation 1
   ask ducks
    [
      if show_brain = 1 [ activate-network ]
      ifelse ( pxcor = -40 ) or ( pxcor = 19 )      ;zbog prikaza mreže nismo mogli staviti wrap-world, pa smo ovako postigli da se agenti ne "zaglavljuju" na rubovima
      [ face patch ( - pxcor ) pycor
        forward 0.5 ]
      [ move ]
      ifelse ( pycor = 20 ) or ( pycor = -20 )
      [ face patch pxcor ( - pycor )
        forward 0.5 ]
      [ move ]
      if ( g > generation ) [ set generation g ]
      eat-crumbs
      reproduce
      death
      labela
     ]
   grannies-move
   ;grow-crumbs
   tick
   mutants-arrive
   do-plot
   ]
   ; if test = true:
   [ ask ducks [
        ifelse show_brain = 1
         [ set x xcor
           set y ycor
           set xcor -10
           set ycor 0
           facexy -10 10
           activate-network
           reset-perspective
           move ]
         [ hide-turtle ] ]
      ask testers [ ifelse ( test-color = 141 )
        [ show-turtle
          setxy mouse-xcor mouse-ycor
          hide-turtle ]
        [ show-turtle
          setxy mouse-xcor mouse-ycor
          set color test-color ]
        ]
      ask patches [ ifelse any? testers-here and test-color = 141
             [ set pcolor 7  ]
             [ set pcolor white ]
           ]
      ask grannies [
          set hidden? true
      ]
      tick ]
end

;raste trava
to grow-crumbs
  ask patches with [ pxcor < 19 and pxcor > -40 and pycor > -20 and pycor < 20   ] [
    if pcolor = white [
      if random 300000 < crumbs-grow-rate
        [ set pcolor 6.9 ]
  ] ]
  if ( ticks mod 50 ) = 0 [
    ask patches with [ ( pcolor > 10 ) and ( pcolor < 17 ) ] [ set pcolor pcolor - 7 ]
    ask patches with [ pcolor = 17 ] [ set pcolor white ]   ]
end

to grannies-move
  ask grannies
   [
     set hidden? false
     if ( pxcor = -40 ) or ( pxcor = 19 )
      [ set heading heading + 180
        forward 0.5 ]
      if ( pycor = 20 ) or ( pycor = -20 )
      [ set heading heading + 180
        forward 0.5 ]
      forward 0.3
      set heading heading - 180
      ask patches in-cone (visibility * 2) 45 with [ pxcor < 19 and pxcor > -40 and pycor > -20 and pycor < 20  and pcolor = white ]
      [ if random 3000 < gfeed
        [ set pcolor 6.9 ] ]
      set heading heading + 180

   ]
end
;THINKING PART:
to move

 ifelse not test

 [

  matrix:set in 0 1 ( count patches in-radius visibility with [ pcolor < 9.9 and pcolor > 6 ] ) / ( 0.5 * visibility * visibility )
  matrix:set in 0 2 energy / birth-threshold
  matrix:set in 0 3 count grannies in-radius visibility
  matrix:set in 0 4 (sum [heading] of ducks in-radius visibility) / (( count ducks in-radius visibility) * 90)
  ;LIJEVO OKO
  set heading heading - 15
  matrix:set in 0 5 ( count patches in-cone visibility 30 with [ pcolor < 9.9 and pcolor > 6 ] ) / ( 0.2 * visibility * visibility )
  matrix:set in 0 6 (count grannies in-cone (visibility * 2) 30) * visibility
  ;DESNO OKO
  set heading heading + 30
  matrix:set in 0 7 ( count patches in-cone visibility 30 with [ pcolor < 9.9 and pcolor > 6 ] ) / ( 0.2 * visibility * visibility )
  matrix:set in 0 8 (count grannies in-cone (visibility * 2) 30) * visibility
  ;POVRATAK NA STARI SMJER
  set heading heading - 15
 ]

 [

  matrix:set in 0 1 ( count patches in-radius visibility with [ pcolor = 7 ] ) / ( 0.5 * visibility * visibility )
  matrix:set in 0 2 energy / birth-threshold
  matrix:set in 0 3 ifelse-value (test-color != 141 ) [ count testers in-radius visibility ] [0]
  matrix:set in 0 4 0
  ;LIJEVO OKO
  set heading heading - 15
  matrix:set in 0 5 ( count patches in-cone visibility 30 with [ pcolor = 7 ] ) / visibility
  matrix:set in 0 6 ifelse-value ( test-color != 141 ) [ ( count testers in-cone (visibility * 2) 30) * visibility  ] [0]
  ;DESNO OKO
  set heading heading + 30
  matrix:set in 0 7 ( count patches in-cone visibility 30 with [ pcolor = 7 ] ) / visibility
  matrix:set in 0 8 ifelse-value ( test-color != 141 ) [ ( count testers in-cone (visibility * 2) 30) * visibility  ] [0]
  ;DESNO OKO
  ;POVRATAK NA STARI SMJER
  set heading heading - 15

 ]
  ; --------------------------------------------------------------------------------------------------------------
  ;pojačane veze između neurona, to je stavljeno zasebno da se lakše podešava (samo se promjeni 2 u neki drugi broj):
  set w1 matrix:times-scalar w1 2
  set w2 matrix:times-scalar w2 2
  set w3 matrix:times-scalar w3 2

  ;koristi a1 od prošli put, element pamćenja
  let pm1 matrix:times in w1
  let pm2 matrix:times a1 w2
  set pm2 matrix:plus pm1 pm2
  let i 1
  while [i < 6] [
  matrix:set a1 0 i sigmoid ( matrix:get pm2 0 i )
  set i i + 1
  ]

  let pm3 matrix:times a1 w3
  set i 0
  while [i < 4] [
   matrix:set out 0 i sigmoid ( matrix:get pm3 0 i )
  set i i + 1
  ]

  let wheel1 ( matrix:get out 0 0  +  matrix:get out 0 1) / 2
  let wheel2 ( matrix:get out 0 2  +  matrix:get out 0 3) / 2
  set speed wheel1 * wheel2

  if not test [  ;da se agent ne miče kad se testia
  set heading heading - 90 * wheel1 + 90 * wheel2
  fd speed * 0.5

  set steps steps + 0.1 * ( 1 + 0.5 * speed )
 ;kretanje trosi energiju ovisno o brzini
  set energy energy - 0.07 * ( 1 +  0.7 * speed )
    ]

  ;vraća varijacije:
  set w1 matrix:times-scalar w1 0.5
  set w2 matrix:times-scalar w2 0.5
  set w3 matrix:times-scalar w3 0.5
end

;jedenje trave --------------------------------------------------------------------------------------------------

to eat-crumbs
  if ( pcolor < 9 and pcolor > 6 )
  [ set pcolor pcolor + 1
    set energy energy + crumbs-energy ]
  if pcolor = 9 [ set pcolor white
    set energy energy + crumbs-energy ]
end

to reproduce
  if energy > birth-threshold and steps > birth-rate and ( ( count turtles ) < 150 )
    [
      set energy energy / 1.5
      set steps 0
      hatch 1 [
        let var1 matrix:from-column-list  n-values 6 [ n-values 9 [ random-float ( 2 * mutation ) - mutation ]]
        let var2 matrix:from-column-list  n-values 6 [ n-values 6  [ random-float ( 2 * mutation ) - mutation ]]
        let var3 matrix:from-column-list  n-values 4  [ n-values 6 [ random-float ( 2 * mutation ) - mutation ]]
        set w1 matrix:plus w1 var1
        set w2 matrix:plus w2 var2
        set w3 matrix:plus w3 var3
        set in  matrix:from-column-list  n-values 9 [ n-values 1 [ 0 ]]
        set a1  matrix:from-column-list  n-values 6 [ n-values 1  [ 0 ]]
        set out matrix:from-column-list  n-values 4[ n-values 1  [ 0 ]]
        matrix:set in 0 0 1
        matrix:set a1 0 0 1
        set color color + ( random 2 - 1 )
        set steps -3
        set energy 10
        set g g + 1
        set heading heading + 180
        fd 1
        ]
      ]
end

to death
  if  energy < 0 or steps > 30 [ die ]
end

;svakih 10 tickova se stvara neki broj (mutants-births) novih agenata:
to mutants-arrive
  if ( ticks mod 10 ) = 0 [
    create-ducks mutants-births [
   set w1 matrix:from-column-list  n-values 6 [ n-values 9 [ ifelse-value ( random 4 = 1) [0] [random-float 2 - 1 ] ]]
    set w2 matrix:from-column-list  n-values 6 [ n-values 6 [ ifelse-value ( random 2 = 1) [0] [random-float 2 - 1 ] ]]
    set w3 matrix:from-column-list  n-values 4 [ n-values 6 [ ifelse-value ( random 4 = 1) [0] [random-float 2 - 1 ] ]]
    set in  matrix:from-column-list  n-values 9 [ n-values 1 [ 0 ]]
    set a1  matrix:from-column-list  n-values 6 [ n-values 1  [ 0 ]]
    set out matrix:from-column-list  n-values 4 [ n-values 1  [ 0 ]]
    matrix:set in 0 0 1
    matrix:set a1 0 0 1
    set color ( random 12 + 1) * 10 + 5
    setxy ( random-float 59 - 40 ) random-ycor
    set energy 10
    set steps -3
    set g 1
    set size 2
   ]

   set newspecies newspecies + mutants-births
  ]
end

;----- plot, labele, prikaz mreže --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

;label pokazuje generaciju i stanje energije
to labela
set label-color 0
set label word g word ", " round energy
end

to setup-plot
  set-current-plot "Populations"
  set-plot-y-range 0 number
end


to do-plot
  set-current-plot "Populations"
  set-current-plot-pen "crumbs"
  plot count patches with [ pcolor < 9.9 and pcolor > 6 ] / 4
  set-current-plot-pen "ducks"
  plot count ducks
end

to-report sigmoid [input]
   report  1. / ( 1. + exp input )
end

to activate-network
    let i 0
    let j 9
    while [i < 9] [
      while [j < 15] [
       let k ( matrix:get w1 ( i ) ( j - 9 ) )
       ask link i j [ ifelse ( k > 0 ) [ set color ( 19.9 - 5 * k ) ] [ set color ( 99.9 + 5 * k ) ] ]
       set j j + 1
      ]
      let k abs matrix:get in 0 i
      ask neuron i  [ set color ( 19.9 - 5 * k )
                      set label-color 0
                      set label i   ]
      set j 9
      set i i + 1
    ]

    set i 9
    set j 9
    while [i < 15] [
      while [j < 15] [
       let k ( matrix:get w2 ( i - 9 ) ( j - 9 ) )
       if i != j [ ask link i j [ ifelse ( k > 0 ) [ set color ( 19.9 - 5 * k ) ] [ set color ( 99.9 + 5 * k ) ] ]
         ]
       set j j + 1
      ]
      let k abs matrix:get a1 0 ( i - 9 )
      ask neuron i  [ set color ( 19.9 - 5 * k ) ]
      set j 9
      set i i + 1
    ]

    set i 9
    set j 15
    while [i < 15] [
      while [j < 19] [
       let k ( matrix:get w3 ( i - 9 ) ( j - 15 ) )
       ask link i j [ ifelse ( k > 0 ) [ set color ( 19.9 - 5 * k ) ] [ set color ( 99.9 + 5 * k ) ] ]
       set k abs matrix:get out 0 ( j - 15 )
          ask neuron j [ set color ( 19.9 - 5 * k )
                         set label-color 0
                         set label j - 15 ]
       set j j + 1
      ]
      set j 15
      set i i + 1
    ]
    ;ako su linkovi bijeli onda ih ni ne pokazuje, tako da se ne preklapaju
    ask links [ ifelse ( ( ( color + 0.1 ) mod 10 < 9 ) and ( ( color + 0.1 ) mod 10 > 1 ) ) [ show-link ] [ hide-link ] ]
    ask link 19 20 [ show-link ]
end
@#$#@#$#@
GRAPHICS-WINDOW
278
10
1260
533
40
20
12.0
1
10
1
1
1
0
0
0
1
-40
40
-20
20
1
1
1
ticks
30.0

BUTTON
2
45
57
78
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
56
45
111
78
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
2
116
140
149
crumbs-grow-rate
crumbs-grow-rate
0.0
20.0
8
1.0
1
NIL
HORIZONTAL

SLIDER
144
117
275
150
crumbs-energy
crumbs-energy
0.0
10.0
2.2
0.1
1
NIL
HORIZONTAL

SLIDER
5
154
137
187
number
number
20
150.0
70
1.0
1
NIL
HORIZONTAL

SLIDER
3
228
139
261
birth-threshold
birth-threshold
0.0
20.0
12
1.0
1
NIL
HORIZONTAL

PLOT
5
265
276
461
Populations
Time
Pop
0.0
100.0
0.0
111.0
true
true
"" ""
PENS
"crumbs" 1.0 0 -10899396 true "" ""
"ducks" 1.0 0 -2674135 true "" ""

MONITOR
189
464
276
509
count rabbits
count ducks
1
1
11

MONITOR
6
464
84
509
generation
generation
17
1
11

SLIDER
6
192
134
225
mutants-births
mutants-births
0
20
5
1
1
NIL
HORIZONTAL

MONITOR
85
464
187
509
num of species
newspecies
17
1
11

SLIDER
140
228
277
261
visibility
visibility
2
10
5
1
1
NIL
HORIZONTAL

SLIDER
144
191
276
224
birth-rate
birth-rate
0
10
10
1
1
NIL
HORIZONTAL

SLIDER
140
156
277
189
mutation
mutation
0
0.2
0.1
0.01
1
NIL
HORIZONTAL

SWITCH
1
10
91
43
test
test
1
1
-1000

SLIDER
103
12
275
45
test-color
test-color
0
141
140
1
1
NIL
HORIZONTAL

SLIDER
145
47
275
80
gnumber
gnumber
0
10
5
1
1
NIL
HORIZONTAL

SLIDER
145
80
277
113
gfeed
gfeed
0
20
12
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

Program se bavi razvijanjem neuronske mreže ( višeslojni perceptron ) kroz principe evolucije - mutaciju i prirodnu selekciju. Želimo pokazati kako se korištenjem tih metoda te odabirom odgovarajućih osjetila, mogu dobiti agenti čije je ponašanje optimalno s obzirom na okoliš u kojem se nalaze.

## HOW IT WORKS

Svakom je agentu pridružena neuronska mreža - višeslojni perceptron - sa 9 input neurona, 6 hidden i 4 output. Hidden neuroni su također povezani sa hidden neuronima iz prošlog koraka, predstavljajući element pamćenja u mreži.

Inputi redom predstavljaju:

0  - bias node
1  - broj sivih patcheva (okolina)
2  - energija agenta
3  - broj "granny" agenata (okolina)
4  - heading okolnih agenata (mentalitet jata)
5  - broj sivih patcheva (lijevo oko)
6  - broj "granny" agenata (lijevo oko)
7  - broj sivih patcheva (desno oko)
8  - broj "granny" agenata (desno oko)

Outputi predstavljaju:

0 - wheel1 (određuje smjer i brzinu lijevo)
1 - wheel1 (određuje smjer i brzinu lijevo)
2 - wheel2 (određuje smjer i brzinu desno)
3 - wheel2 (određuje smjer i brzinu desno)

Za kretanje u oba smijera su dana 2 neurona kako bi se postigla veća preciznost.


Agenti mogu povećati stanje energije jedući mrvice. Granny agenti iza sebe u luku ostavljaju mrvice. Mrvice se također pojavljuju nasumično po mapi, ali znatno sporijim tempom.

Nakon određenog broja koraka, ako agent ima dovoljno energije, napravit će potomka. Potomak poprima matrice težina i boju od roditelja, no sa malom mutacijom. Botovi sa korisnim mutacijama će biti uspješniji ( stanje više energije) i imati više potomaka.


Također su definirani parametri okoliša:

gnumber- broj granny agenata
gfeed - količina mrvica koje bacaju granny agenti
number - početni broj agenata
mutation - promjena težina veza u novoj generaciji
mutants-births - broj novih agenata nakon 10 tickova
birth-rate - "starost" agenta (broj koraka) sa koliko najranije može imati potomka
birth-threshold - minimalna energija koju agent mora imati da bi imao potomka
visibility - udaljenost do koje vidi druge agente i patcheve

## HOW TO USE IT

Pokrenuti program i pustiti agente da se razvijaju do negdje 20. - 30. generacije. Zatim se može povećati birth-treshold, a smanjiti grass-grow-rate, grass-energy ili mutants-births. Postepenim postavljanjem zahtjevnijih uvijeta u okolišu, dobiva se inteligentnije ponašanje. Također poželjno je na višim generacijama smanjiti mutation na 0.05.

Može se vidjeti neuronska mreža nekog od agenata, tako da se klikne na njega - neki put je teško naciljati, treba probati par puta. Neuroni mreže poprimaju boju između bijele i crvene, sukladno njihovoj vrijednosti između 0 i 1. Veze su crvene ili plave, ovisno jesu li pozitivne ili negativne.

Dio za testiranje:
test - kada je "on", označeni agent (mora biti već prije označen) dolazi u sredinu ekrana i može ga se testirati da se vidi kako reagira na podražaje, tako da se testni agent ili patch približi
test-color - boja testnog agenta; kada se namjesti na 141 testni agent postaje patch


## CREDITS AND REFERENCES
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

rabbit
false
0
Circle -7500403 true true 76 150 148
Polygon -7500403 true true 176 164 222 113 238 56 230 0 193 38 176 91
Polygon -7500403 true true 124 164 78 113 62 56 70 0 107 38 124 91

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
