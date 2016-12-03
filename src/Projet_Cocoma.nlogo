__includes["BDI/communication.nls" "BDI/bdi.nls" "astar.nls" "convoi.nls" "env.nls" "hostile.nls" "bullet.nls" "drone.nls" "visu.nls" "communication/basic_message.nls" "communication/drone_messages.nls" "communication/convoi_messages.nls" "BDI/basic_bdi.nls" "utils/utils.nls" "strategy/strat_drone.nls"]
breed [waypoints waypoint]
breed [envconstructors envconstructor]
breed [convois convoi]
breed [drones drone]
breed [HQs HQ]
breed [hostiles hostile]
breed [drawers drawer]
breed [bullet]

directed-link-breed [path-links path-link]
undirected-link-breed [dummy-links dummy-link]
directed-link-breed [convoi-links convoi-link]

globals [mapAlt solAlt basseAlt hauteAlt ; variables topologiques Z discretise: definit le niveau ou se trouvent toutes les informations de la carte (obstacles base etc.) car en 2D, niveau au sol ou se trouvent les agents, niveau basse altitude et niveau haute altitude
  base-patches base-entry base-central ; precache: definit ou se trouvent les patchs de la base d'atterrissage, le patch d'entree sur la piste d'atterrissage, et le patch ou doivent s'arreter les drones pour se recharger. Permet d'evaluer rapidement la distance et les besoins des drones (quand ils doivent rentrer a la base)
  as-cost as-path ; variables globales pour les chemins AStar: le cout d'un pas sur un patch, et as-path est la liste des plans, un pour chaque convoi leader
  ;max-fuel max-ammo ; fuel and ammo for drones.
  ;fuel-dec ; how much fuel will be decremented at each iteration
  mission-completed? mission-failed?
  send-interval ; communication period
  is-movie-recording?
  convoi-position ;; position connu du convoi par les agents hostiles
  nb-cars

]

patches-own [obstacle? base? hangar? objectif? bridge? sol?; variables topologiques au niveau mapAlt, permet de definir les patchs praticables et ceux qui sont des obstacles
  as-closed as-heuristic as-prev-pos z_zone ; variables temporaires pour calculer les chemins AStar (effaces a chaque calcul de plan)
]

turtles-own [
  hp
  dead?
  speed maxdir ; maximal speed of a car, and max angle
  beliefs intentions
  range
  range-visu
  range-color
  message-to-forward
  newdetect?
  last-color nb-tick-color
]


;***********************
;         SETUP
;***********************

to setup
  ; The setup generates environments until one of them is acceptable (the convoi can accomplish the mission)
  let path-is-possible? false
  while [not path-is-possible?] [
    clear-all
    if not debug and not debug-verbose [no-display] ; disable gui display to speedup processing, the time slider won't influence the setup procedure
    setup-globals
    setup-env
    clear-turtles ; reinit the id of the agents
    setup-convois ;
    setup-drones
    setup-hostiles

    ask patches
    [
      let x int (pxcor / zone-size)
      let y int (pycor / zone-size)
      set z_zone (list x y 1)
    ]
    ifelse nb-cars <= 0 [
      set path-is-possible? true
    ]
    ; generate a path and check is the convoi can reach its destination. If not, generate a new env
    [
      let t one-of convois with [leader?]
      let z []
      ask t [set z get-hostile-belief]
      let start-path (plan-astar ([[patch-at 0 0 (pzcor * -1)] of patch-here] of t) (one-of patches with [objectif?]) false z)
      set as-path replace-item 0 as-path start-path
      let i path-to-zone item 0 as-path
      if not empty? start-path [ set path-is-possible? true]

      let lC [who] of one-of convois with [leader?]
      let lD [who] of one-of drones with [leader?]
      ask convois [init-beliefs-convoi lC lD start-path]
      ask drones [init-beliefs-drone lC lD start-path]
    ]
  ]



  if not debug and not debug-verbose [no-display]
  ;setup-drones
  ;setup-enemies
  ;setup-citizens
;  setup-hq

  setup-precache
  display ; reenable gui display
  reset-ticks

  set convoi-position []

  if debug-path [
    ask patches with [pxcor mod zone-size = 0 or pycor mod zone-size = 0 and pzcor = mapAlt]
    [set pcolor yellow]

;    let i path-to-zone item 0 as-path
;    print i
;    print item 0 as-path
;
;    ask patches with [pzcor = mapAlt]
;    [
;      foreach i
;      [
;        if pin-zone? ?
;        [set pcolor pink ]
;      ]
;    ]

  ]

end

; Initial parameters
to setup-globals
  set nb-cars total-nb-cars
  set mapAlt 0
  set solAlt 1
  set basseAlt (floor max-pzcor / 3 * 2 - 1)
  set hauteAlt (floor max-pzcor - 1)

  set mission-completed? false
  set mission-failed? false

  set as-cost 1 ; cost to move
  set as-path n-values (total-nb-cars + total-nb-drones)[[]] ; max one path for each car

  set send-interval 10 ; in number of steps

 ; set dist-R-set []

  set is-movie-recording? false
end


; Precaches places en global variables for static components in order to speed-up the processes.
to setup-precache
  set base-patches (patches with [base? and pzcor = mapAlt]) ; precache to speedup things
  set base-entry max-one-of (base-patches with-min [pycor]) [pxcor]
  set base-central min-one-of (base-patches with-min [pxcor]) [pycor]
end


;------------------------------------------------------------
;------------- functions ------------------------------------
;------------------------------------------------------------

to go
  ask turtles [
    ;print color
    set nb-tick-color nb-tick-color + 1
    if nb-tick-color > 10 [set color  last-color ]
  ]
  convois-think
  hostiles-think
  drones-think
  ;;print convoi-position
  ;update-bullets
  let agent-set turtles with [who = -1]
  if hostile-range-visu? [set agent-set (turtle-set agent-set hostiles)]
  if convoi-range-visu? [set agent-set (turtle-set agent-set convois)]
  if drone-range-visu? [set agent-set (turtle-set agent-set drones)]

  draw-range-agent agent-set
  tick

end
@#$#@#$#@
GRAPHICS-WINDOW
0
0
1430
1451
-1
-1
20.0
1
10
1
1
1
0
1
1
1
0
70
0
70
0
20
1
1
1
ticks
30.0

SWITCH
20
310
123
343
debug
debug
1
1
-1000

SWITCH
21
349
167
382
debug-verbose
debug-verbose
1
1
-1000

TEXTBOX
18
122
168
140
Environnement \n
12
0.0
1

INPUTBOX
112
209
197
269
total-nb-cars
3
1
0
Number

BUTTON
13
11
86
44
NIL
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

INPUTBOX
17
144
95
204
nb-mountains
3
1
0
Number

INPUTBOX
98
144
150
204
nb-lakes
1
1
0
Number

INPUTBOX
162
143
226
203
nb-rivers
2
1
0
Number

INPUTBOX
21
506
94
566
astar-faster
1000
1
0
Number

INPUTBOX
99
506
197
566
astar-max-depth
10000
1
0
Number

SWITCH
21
423
185
456
astar-longpath
astar-longpath
1
1
-1000

SWITCH
21
467
184
500
astar-randpath
astar-randpath
1
1
-1000

SWITCH
193
466
355
499
astar-visu-more
astar-visu-more
1
1
-1000

SWITCH
193
423
356
456
astar-visu
astar-visu
0
1
-1000

SLIDER
164
10
278
43
simu-speed
simu-speed
0
10
6
1
1
NIL
HORIZONTAL

TEXTBOX
21
283
171
301
Debug
12
0.0
1

TEXTBOX
24
397
174
415
A*
12
0.0
1

BUTTON
92
12
155
45
NIL
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

BUTTON
25
612
170
645
show to forward
ask convois [\nprintcom (word \"(\" breed \" \" who \") MESSSAGE TO FORWARD\" )\nlet tmp message-to-forward\n  foreach tmp [\n   let msg ?\n     printcom (word \"(\" breed \" \" who \")\" msg )\n  ]\n]\n\nask drones [\nlet tmp message-to-forward\n  foreach tmp [\n   let msg ?\n     printcom (word \"(\" breed \" \" who \")\" msg )\n  ]\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
17
209
107
269
nb-cars-hostile
0
1
0
Number

TEXTBOX
300
282
450
300
Bullets\n
12
0.0
1

MONITOR
99
69
158
114
Convois
count convois
0
1
11

MONITOR
167
69
233
114
Hostiles
count hostiles
0
1
11

MONITOR
12
73
92
118
POKERARE
count convois with [who = total-nb-cars - 1]
0
1
11

SWITCH
279
674
453
707
show_messages
show_messages
1
1
-1000

SWITCH
283
614
454
647
show-intentions
show-intentions
1
1
-1000

TEXTBOX
282
584
432
602
BDI
12
0.0
1

SLIDER
247
119
419
152
convois-hp
convois-hp
2
100
5
1
1
NIL
HORIZONTAL

SLIDER
247
161
419
194
hostiles-hp
hostiles-hp
2
100
5
1
1
NIL
HORIZONTAL

SLIDER
322
310
427
343
cooldown
cooldown
2
100
20
1
1
NIL
HORIZONTAL

INPUTBOX
200
210
295
270
total-nb-drones
1
1
0
Number

SLIDER
245
80
417
113
drones-hp
drones-hp
2
100
5
1
1
NIL
HORIZONTAL

SLIDER
436
162
608
195
hostile-range
hostile-range
3
50
13
1
1
NIL
HORIZONTAL

SWITCH
371
465
563
498
hostile-range-visu?
hostile-range-visu?
1
1
-1000

SWITCH
138
310
279
343
debug-path
debug-path
1
1
-1000

SLIDER
303
210
415
243
zone-size
zone-size
1
20
5
1
1
NIL
HORIZONTAL

SLIDER
437
122
609
155
convoi-range
convoi-range
1
20
10
1
1
NIL
HORIZONTAL

SLIDER
437
80
609
113
drone-range
drone-range
1
20
12
1
1
NIL
HORIZONTAL

SLIDER
447
241
619
274
pas-cercle
pas-cercle
1
12
12
1
1
NIL
HORIZONTAL

SLIDER
445
31
625
64
drones-max-ammo
drones-max-ammo
0
50
5
1
1
NIL
HORIZONTAL

SWITCH
381
428
567
461
drone-range-visu?
drone-range-visu?
1
1
-1000

CHOOSER
630
80
783
125
drone-range-color
drone-range-color
"red" "yellow" "blue" "gray" "orange" "brown" "lime" "turquoise" "cyan" "sky" "violet" "magenta" "pink"
1

CHOOSER
630
180
789
225
hostile-range-color
hostile-range-color
"red" "yellow" "blue" "gray" "orange" "brown" "lime" "turquoise" "cyan" "sky" "violet" "magenta" "pink"
2

SWITCH
175
345
312
378
debug-com
debug-com
1
1
-1000

TEXTBOX
635
565
785
583
Debug :\n
12
0.0
1

SLIDER
625
600
797
633
elipseA
elipseA
0
100
7
1
1
NIL
HORIZONTAL

SLIDER
625
635
797
668
elipseB
elipseB
0
100
7
1
1
NIL
HORIZONTAL

SLIDER
245
45
425
78
drones-max-carburant
drones-max-carburant
100
500
500
1
1
NIL
HORIZONTAL

SWITCH
370
515
557
548
convoi-range-visu?
convoi-range-visu?
1
1
-1000

CHOOSER
630
130
787
175
convoi-range-color
convoi-range-color
"red" "yellow" "blue" "gray" "orange" "brown" "lime" "turquoise" "cyan" "sky" "violet" "magenta" "pink"
0

BUTTON
85
270
202
303
show beliefs
printbdi (word \"(BELIEFS)\" )\nprintbdi (word \"(convoi)\\n\" )\nask convois [\n  printbdi (word \"(\" breed \" \" who \") beliefs\" )\n  let b get-hostile-belief\n  printbdi (word \"(\" breed \" \" who \") Hostile : \" b )\n  set b get-leader-id-convoi\n  printbdi (word \"(\" breed \" \" who \") LeaderC : \" b )\n  set b get-leader-id-drone\n  printbdi (word \"(\" breed \" \" who \") LeaderD : \" b )\n  set b get-convoi-critic\n  printbdi (word \"(\" breed \" \" who \") Critic? : \" b )\n  \n  set b get-convoi-path-zone\n  printbdi (word \"(\" breed \" \" who \") Path-zone? : \" b )\n  \n  printbdi (word \"-----------------\" )\n]\nprintbdi (word \"(drones)\" )\nask drones [\n    let b get-hostile-belief\n  printbdi (word \"(\" breed \" \" who \") Hostile : \" b )\n  set b get-leader-id-convoi\n  printbdi (word \"(\" breed \" \" who \") LeaderC : \" b )\n  set b get-leader-id-drone\n  printbdi (word \"(\" breed \" \" who \") LeaderD : \" b )\n  set b get-drone-munition\n  printbdi (word \"(\" breed \" \" who \") Ammo : \" b )\n  set b get-drone-essence\n  printbdi (word \"(\" breed \" \" who \") Fuel : \" b )\n  set b get-convoi-path-zone\n  printbdi (word \"(\" breed \" \" who \") Path-zone? : \" b )\n  printbdi (word \"-----------------\" )\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
175
380
302
413
debug-bdi
debug-bdi
0
1
-1000

BUTTON
290
10
402
43
split convoi
ask convoi max [who] of convois with [leader?]\n[\n  let zzone [z_zone] of patch-here\n  add-hostile-belief zzone\n  split (who + 1)\n  \n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
785
355
987
388
proba-touche-drone
proba-touche-drone
0.1
1
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
785
300
992
333
proba-touche-hostile
proba-touche-hostile
0.1
1
0.5
0.1
1
NIL
HORIZONTAL

BUTTON
210
275
892
308
NIL
ask turtle 0 [send-message create-msg-leader-to-leader-leader \"inform\" 0 3 \"\" \"nLeaderC\"]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

airplane 2
true
0
Polygon -7500403 true true 150 26 135 30 120 60 120 90 18 105 15 135 120 150 120 165 135 210 135 225 150 285 165 225 165 210 180 165 180 150 285 135 282 105 180 90 180 60 165 30
Line -7500403 true 120 30 180 30
Polygon -7500403 true true 105 255 120 240 180 240 195 255 180 270 120 270

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

person soldier
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 105 90 60 195 90 210 135 105
Polygon -10899396 true false 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -6459832 true false 120 90 105 90 180 195 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 183 90 240 15 247 22 193 90
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208

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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 3D 5.3.1
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
1
@#$#@#$#@
