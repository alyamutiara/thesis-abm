breed [ persons person ]

globals [
  upper              ; the upper edge of the exit
  lower              ; the lower edge of the exit
  move-speed         ; how many patches did persons move in last tick on average
  dead               ; count persons dead
  evacuated
]

persons-own [
  moved?             ; if agent moved in this tick
  agent-type         ; age distribution: child, adult, senior, disabled
  travel-distance    ; how far the agent had moved
  vx                 ; x velocity
  vy                 ; y velocity
  desired-direction  ; person desired direction towards exit
  driving-forcex     ; agent's motivation force in x axis
  driving-forcey     ; agent's motivation force in y axis
  obstacle-forcex    ; force exerted by obstacles
  obstacle-forcey
  territorial-forcex ; force exerted by neighbors
  territorial-forcey
  max-speed
  counter
]

patches-own [
  path               ; how many times it has been chosen as a path
  patch-id           ; if exit, wall, and obstacle = 1, if floor 0
  name               ; patches id
]

to setup
  clear-all
  reset-ticks
  set-env
  set-agent
end

to go
  calc-desired-direction
  calc-driving-force
  calc-obstacle-force
  if any? other persons [
    calc-territorial-forces
  ]
  ask persons [ set counter 5 ]
  move-persons
  if count persons = 0 [ stop ]
  tick
end

; ============================ SETUP BUTTON ============================
to set-env
  ask patches [
    set pcolor white
    set path 0
  ]

  ;; set boundary patches as walls
  ask patches with [ pxcor = min-pxcor or pxcor = max-pxcor ] [
    set pcolor brown
    set name "wall"
    set patch-id -1
;    set plabel pycor
  ]
  ask patches with [ pycor = min-pycor or pycor = max-pycor ] [
    set pcolor brown
    set name "wall"
    set patch-id -1
;    set plabel pxcor
  ]

  ;; create the exit door
  set upper round (exit-width / 2)
  set lower 0 - (exit-width - upper)
  if exit-door-layout = "1-side A" [
    ask patches with [ pxcor = min-pxcor and pycor < upper and pycor >= lower ] [
      set pcolor green - 3
      set patch-id 1
      set name "door"
      set plabel "A"
    ]
  ]

  if exit-door-layout = "2-side A" [
    ask patches with [ pxcor = min-pxcor and pycor < upper + 8 and pycor >= lower + 8 ] [
      set pcolor green - 3
      set patch-id 1
      set name "door"
      set plabel "A1"
    ]
    ask patches with [ pxcor = min-pxcor and pycor < upper - 8 and pycor >= lower - 8 ] [
      set pcolor green - 3
      set patch-id 1
      set name "door"
      set plabel "A2"
    ]
  ]

  if exit-door-layout = "1-side AC" [
    ask patches with [ pxcor = min-pxcor and pycor < upper and pycor >= lower ] [
      set pcolor green - 3
      set patch-id 1
      set name "door"
      set plabel "A"
    ]
    ask patches with [ pxcor = max-pxcor and pycor < upper and pycor >= lower ] [
      set pcolor green - 3
      set patch-id 1
      set name "door"
      set plabel "C"
    ]
  ]

  if exit-door-layout = "1-side ABD" [
    ask patches with [ pxcor = min-pxcor and pycor < upper and pycor >= lower ] [
      set pcolor green - 3
      set patch-id 1
      set name "door"
      set plabel "A"
    ]
    ask patches with [ pycor = max-pycor and pxcor < upper and pxcor >= lower ] [
      set pcolor green - 3
      set patch-id 1
      set name "door"
      set plabel "B"
    ]
    ask patches with [ pycor = min-pycor and pxcor < upper and pxcor >= lower ] [
      set pcolor green - 3
      set patch-id 1
      set name "door"
      set plabel "D"
    ]
  ]

  if exit-door-layout = "1-side ABCD" [
    ask patches with [ pxcor = min-pxcor and pycor < upper and pycor >= lower ] [
      set pcolor green - 3
      set patch-id 1
      set name "door"
      set plabel "A"
    ]
    ask patches with [ pxcor = max-pxcor and pycor < upper and pycor >= lower ] [
      set pcolor green - 3
      set patch-id 1
      set name "door"
      set plabel "C"
    ]
    ask patches with [ pycor = max-pycor and pxcor < upper and pxcor >= lower ] [
      set pcolor green - 3
      set patch-id 1
      set name "door"
      set plabel "B"
    ]
    ask patches with [ pycor = min-pycor and pxcor < upper and pxcor >= lower ] [
      set pcolor green - 3
      set patch-id 1
      set name "door"
      set plabel "D"
    ]
  ]

end


to set-agent
  clear-turtles
  ;; create agents
  ; create children
  create-persons num-people * child-num / 100 [
    move-to one-of patches with [ pcolor = white and pxcor != 15 and (not any? other turtles-here) ]
    set color lime
    set shape "circle3"
    set agent-type "child"
    let init-direction 0 + random 360     ;; give the turtles an initial nudge towards the goal
    set vx sin init-direction
    set vy cos init-direction
    set max-speed 0.36 + random-float 0.24 - 0.12
  ]
  ; create adults
  create-persons num-people * adult-num / 100 [
    move-to one-of patches with [ pcolor = white and pxcor != 15 and (not any? other turtles-here) ]
    set color yellow
    set shape "circle3"
    set agent-type "adult"
    let init-direction 0 + random 360
    set vx sin init-direction
    set vy cos init-direction
    set max-speed 0.5 + random-float 0.24 - 0.12
  ]
  ; create seniors
  create-persons num-people * senior-num / 100 [
    move-to one-of patches with [ pcolor = white and pxcor != 15 and (not any? other turtles-here) ]
    set color orange
    set shape "circle3"
    set agent-type "senior"
    let init-direction 0 + random 360
    set vx sin init-direction
    set vy cos init-direction
    set max-speed 0.32 + random-float 0.24 - 0.12
  ]
  ; create disables
  create-persons num-people * disable-num / 100 [
    move-to one-of patches with [ pcolor = white and pxcor != 15 and (not any? other turtles-here) ]
    set color blue
    set shape "circle3"
    set agent-type "disabled"
    let init-direction 0 + random 360
    set vx sin init-direction
    set vy cos init-direction
    set max-speed 0.316 + random-float 0.256 - 0.128
  ]

  ask persons [ set counter 5 ]
end


; ============================ GO BUTTON ============================

to calc-desired-direction
  ask persons [
    if [patch-id] of patch-here != 1 [
      let goal min-one-of (patches with [ patch-id = 1 ]) [ distance myself ]
      set desired-direction towards goal
    ]
  ]
end

to calc-driving-force
  ask persons [
    set driving-forcex (1 / tau) * (max-speed * (sin desired-direction) - vx)
    set driving-forcey (1 / tau) * (max-speed * (cos desired-direction) - vy)
  ]
end

to calc-obstacle-force
  ask persons [
    set obstacle-forcex 0
    set obstacle-forcey 0
    if [patch-id] of patch-here != 1 [
      ask patches with [ patch-id = -1 ] [
        let to-obstacle (towards myself) - 180
        let obstacle-force (- u0) * exp (- (distance myself) / r)
        ask myself [
          set obstacle-forcex obstacle-forcex + obstacle-force * (sin to-obstacle)
          set obstacle-forcey obstacle-forcey + obstacle-force * (cos to-obstacle)
        ]
      ]
    ]
  ]
end

to calc-territorial-forces
  ask persons [
    set territorial-forcex 0
    set territorial-forcey 0
    ask other persons with [ distance myself > 0 ] [
      let to-agent (towards myself) - 180
      let rabx [xcor] of myself - xcor
      let raby [ycor] of myself - ycor
      let speed magnitude vx vy
      let to-root ((magnitude rabx raby) + (magnitude (rabx - (speed * sin desired-direction)) (raby - (speed * cos desired-direction)))) ^ 2 - speed ^ 2
      if to-root < 0 [
        set to-root 0
      ]
      let b 0.5 * sqrt to-root
      let agent-force (- v0) * exp (- b / sigma)
      ask myself [
        let agent-forcex agent-force * (sin to-agent)
        let agent-forcey agent-force * (cos to-agent)
        ;; modify the effect this force has based on whether or not it is in the field of view
        let vision field-of-view-modifier driving-forcex driving-forcey agent-forcex agent-forcey
        set territorial-forcex territorial-forcex + agent-forcex * vision
        set territorial-forcey territorial-forcey + agent-forcey * vision
      ]
    ]
  ]
end

to-report magnitude [ x y ]
  report sqrt ((x ^ 2) + (y ^ 2))
end

to-report field-of-view-modifier [desiredx desiredy forcex forcey]
  ifelse (desiredx * (- forcex) + desiredy * (- forcey)) >= (magnitude forcex forcey) * cos (field-of-view / 2)
  [ report 1 ]
  [ report c ]
end

to move-persons
  if count persons > 0 [
    set move-speed (count persons with [ moved? = true ] / count persons)
  ]

  ask persons [
    ifelse draw-path? [ pen-down ] [ pen-up ]

    let ax driving-forcex + obstacle-forcex + territorial-forcex
    let ay driving-forcey + obstacle-forcey + territorial-forcey

    set vx vx + ax
    set vy vy + ay

    let vmag magnitude vx vy
    let multiplier 1
    if vmag > max-speed [
      set multiplier max-speed / vmag
    ]

    set vx vx * multiplier
    set vy vy * multiplier

    ; kecepatan agen sumbu x dan y
    let v (sqrt (vx * vx + vy * vy))
    ifelse can-move? (v * 2) [
      carefully [
        set xcor xcor + vx
        set ycor ycor + vy
      ] [
        set xcor xcor - xcor
        set ycor ycor - ycor
        show "I'm stuck!"
        show error-message
        set counter counter - 1
        show counter
        if counter = 0 [
          set xcor xcor * (-2)
          set ycor ycor * (-2)
        ]
      ]
    ] [
      set xcor xcor - vx
      set ycor ycor - vy
    ]

;    ifelse can-move? (vx * 2) [
;      carefully [ set xcor xcor + vx ] [ set xcor xcor show "I'm stuck" ]
;    ] [ set xcor xcor - vx ]
;    ifelse can-move? (vy * 2) [
;      carefully [ set ycor ycor + vy ] [ set ycor ycor show "I'm stuck" ]
;    ] [ set ycor ycor - vy ]

    set travel-distance travel-distance + (sqrt (vx * vx + vy * vy))
  ]

  ask patches with [ patch-id = 1 ] [
    if any? persons-here [
      ask persons-here [ die ]
    ]
  ]

end

; ============================ PLOTTING ============================
; count number of agent in the room
to-report count-persons
  ifelse count persons > 0 [
    report count persons
  ] [report 0]
end

to-report count-child
  ifelse count persons with [ agent-type = "child" ] > 0 [
    report count persons with [ agent-type = "child" ]
  ] [ report 0 ]
end

to-report count-adult
  ifelse count persons with [ agent-type = "adult" ] > 0 [
    report count persons with [ agent-type = "adult" ]
  ] [ report 0 ]
end

to-report count-senior
  ifelse count persons with [ agent-type = "senior" ] > 0 [
    report count persons with [ agent-type = "senior" ]
  ] [ report 0 ]
end

to-report count-disable
  ifelse count persons with [ agent-type = "disable" ] > 0 [
    report count persons with [ agent-type = "disable" ]
  ] [ report 0 ]
end

to-report mean-child-velocity
  ifelse count persons with [ agent-type = "child" ] > 0 [
    report mean [ sqrt (vx * vx + vy * vy) ] of persons with [ agent-type = "child" ]
  ] [ report 0 ]
end

to-report mean-adult-velocity
  ifelse count persons with [ agent-type = "adult" ] > 0 [
    report mean [ sqrt (vx * vx + vy * vy) ] of persons with [ agent-type = "adult" ]
  ] [ report 0 ]
end

to-report mean-senior-velocity
  ifelse count persons with [ agent-type = "senior" ] > 0 [
    report mean [ sqrt (vx * vx + vy * vy) ] of persons with [ agent-type = "senior" ]
  ] [ report 0 ]
end

to-report mean-disable-velocity
  ifelse count persons with [ agent-type = "disable" ] > 0 [
    report mean [ sqrt (vx * vx + vy * vy) ] of persons with [ agent-type = "disable" ]
  ] [ report 0 ]
end

to-report mean-travel-distance
  ifelse count persons > 0 [
    report mean [ travel-distance ] of persons
  ] [ report 0 ]
end
@#$#@#$#@
GRAPHICS-WINDOW
351
10
830
490
-1
-1
11.5
1
10
1
1
1
0
0
0
1
-20
20
-20
20
0
0
1
ticks
30.0

BUTTON
9
21
75
54
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

BUTTON
86
21
149
54
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

INPUTBOX
9
59
158
119
num-people
500.0
1
0
Number

SLIDER
9
125
101
158
exit-width
exit-width
1
15
2.0
1
1
NIL
HORIZONTAL

TEXTBOX
12
170
162
188
Force Constants
11
0.0
1

SLIDER
11
353
103
386
tau
tau
1
30
2.5
0.5
1
NIL
HORIZONTAL

SLIDER
12
191
104
224
v0
v0
0
10
0.3
0.1
1
NIL
HORIZONTAL

SLIDER
11
231
103
264
sigma
sigma
0.1
2
0.6
0.01
1
NIL
HORIZONTAL

SLIDER
11
271
103
304
u0
u0
0
20
1.6
0.1
1
NIL
HORIZONTAL

SLIDER
11
313
104
346
r
r
0.15
1
0.4
0.01
1
NIL
HORIZONTAL

SLIDER
14
439
106
472
field-of-view
field-of-view
0
360
200.0
1
1
NIL
HORIZONTAL

SLIDER
13
479
105
512
c
c
0
1
0.5
0.1
1
NIL
HORIZONTAL

TEXTBOX
847
47
1190
89
Note:\nTurtles movement based on social force model
11
0.0
1

SLIDER
12
398
104
431
max-speed-y
max-speed-y
0
1
0.48
0.01
1
NIL
HORIZONTAL

MONITOR
351
495
409
540
second
ticks * 0.2
2
1
11

BUTTON
156
22
219
55
NIL
go
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
139
276
257
309
child-num
child-num
0
100 - (adult-num + senior-num + disable-num)
3.0
0.1
1
%
HORIZONTAL

SLIDER
139
195
258
228
adult-num
adult-num
0
100 - (child-num + senior-num + disable-num)
15.0
0.1
1
%
HORIZONTAL

SLIDER
139
236
258
269
senior-num
senior-num
0
100 - (child-num + adult-num + disable-num)
81.0
0.1
1
%
HORIZONTAL

SLIDER
139
315
258
348
disable-num
disable-num
0
100 - (child-num + adult-num + senior-num)
1.0
0.1
1
%
HORIZONTAL

TEXTBOX
141
170
291
188
Age Distribution
11
0.0
1

PLOT
847
90
1047
240
Agent Inside Building
Time
Number of Agent
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"child" 1.0 0 -14439633 true "" "plot count-child"
"adult" 1.0 0 -4079321 true "" "plot count-adult"
"senior" 1.0 0 -3844592 true "" "plot count-senior"
"disable" 1.0 0 -13345367 true "" "plot count-disable"
"agent" 1.0 0 -16777216 true "" "plot count-persons"

PLOT
848
256
1048
406
Average Velocity
Timestep
Velocity
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"children" 1.0 0 -14439633 true "" "plot mean-child-velocity"
"adult" 1.0 0 -4079321 true "" "plot mean-adult-velocity"
"senior" 1.0 0 -3844592 true "" "plot mean-senior-velocity"
"disable" 1.0 0 -13345367 true "" "plot mean-disable-velocity"

SWITCH
109
126
236
159
draw-path?
draw-path?
0
1
-1000

PLOT
1060
88
1260
238
Average Distance
Time
Distance
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"distance" 1.0 0 -16777216 true "" "plot mean-travel-distance"

CHOOSER
142
370
280
415
exit-door-layout
exit-door-layout
"1-side A" "2-side A" "1-side AC" "1-side ABD" "1-side ABCD"
0

TEXTBOX
851
429
1214
513
BehaviorSpace output:\nmean [travel-distance] of persons\nmean [sqrt (vx * vx + vy * vy)] of persons\nticks * 0.2\ncount persons
11
0.0
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

circle3
false
0
Circle -16777216 true false 15 15 270
Circle -7500403 true true 30 30 240

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
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="s-I.123.1" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="900"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>ticks * 0.2</metric>
    <metric>count persons</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-num">
      <value value="81.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="child-num">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="r">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-speed-y">
      <value value="0.48"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disable-num">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="50"/>
      <value value="250"/>
      <value value="500"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="s-I.123.2" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>ticks * 0.2</metric>
    <metric>count persons</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-num">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="child-num">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="r">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-speed-y">
      <value value="0.48"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disable-num">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="50"/>
      <value value="250"/>
      <value value="500"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="S-I.123.3" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>ticks * 0.2</metric>
    <metric>count persons</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-num">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="child-num">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="r">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-speed-y">
      <value value="0.48"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disable-num">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="50"/>
      <value value="250"/>
      <value value="500"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="S-I.123.4" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>ticks * 0.2</metric>
    <metric>count persons</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-num">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="child-num">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="r">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-speed-y">
      <value value="0.48"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disable-num">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="50"/>
      <value value="250"/>
      <value value="500"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="S-I.123.5" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>ticks * 0.2</metric>
    <metric>count persons</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="child-num">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="r">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-speed-y">
      <value value="0.48"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disable-num">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="50"/>
      <value value="250"/>
      <value value="500"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="s-II.1.123" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>ticks * 0.2</metric>
    <metric>count persons</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-num">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="child-num">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="r">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-speed-y">
      <value value="0.48"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disable-num">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="2"/>
      <value value="5"/>
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="300"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="s-II.2.12" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>ticks * 0.2</metric>
    <metric>count persons</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-num">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="child-num">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="r">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-speed-y">
      <value value="0.48"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disable-num">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="2"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;2-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="300"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="s-II.3.1" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>ticks * 0.2</metric>
    <metric>count persons</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-num">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="child-num">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="r">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-speed-y">
      <value value="0.48"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disable-num">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side AC&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="300"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="s-II.4.1" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-num">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="child-num">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="r">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-speed-y">
      <value value="0.48"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disable-num">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side AC&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="300"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="s-II.4.1" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>ticks * 0.2</metric>
    <metric>count persons</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-num">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="child-num">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="r">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-speed-y">
      <value value="0.48"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disable-num">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side ABD&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="300"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="s-II.5.1" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="400"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>ticks * 0.2</metric>
    <metric>count persons</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-num">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="child-num">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="r">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-speed-y">
      <value value="0.48"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disable-num">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side ABCD&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="300"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="S-I.3.5" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>ticks * 0.2</metric>
    <metric>count persons</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="child-num">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="c">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="r">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-speed-y">
      <value value="0.48"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disable-num">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="500"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
