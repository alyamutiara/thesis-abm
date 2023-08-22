breed [ persons person ]
breed [ fires fire ]
breed [ smokes smoke ]

globals [
  upper              ; the upper edge of the exit
  lower              ; the lower edge of the exit
  middle
  move-speed         ; how many patches did persons move in last tick on average
  dead               ; count persons dead
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
  energy
  state
  stuck
]

patches-own [
  path               ; how many times it has been chosen as a path
  patch-id           ; if exit = 2, door = 1, wall and obstacle = -1, floor = 0, fire = 1000
  name               ; patches id
  door-state
]

to setup
  clear-all
  reset-ticks
  set-env
  set-agent
  if danger? = true [ blow-up ]   ; add fire element into the simulation
end

to go
  ;calculate social force model
  calc-desired-direction
  calc-driving-force
  calc-obstacle-force
  if any? other persons [
    calc-territorial-forces
  ]

  move-persons     ; person movement
  if danger? = true [ fire-spread smoke-spread ]      ; spread fire and smoke
  door-status     ; check door status whether it is opened or closed

  if count persons with [ state = "alive" ] = 0 [ stop ]      ; end the simulation if there are no alive person inside the building
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
  set middle ((max-pycor - min-pycor) / 4)
  if exit-door-layout = "1-side A" [
    ask patches with [ pxcor = min-pxcor and pycor < upper and pycor >= lower ] [
;      set pcolor green - 3
;      set patch-id 1
      set name "door"
      door-status
;      set plabel "A"
    ]
  ]

  if exit-door-layout = "2-side A" [
    ask patches with [ pxcor = min-pxcor and pycor < upper + middle and pycor >= lower + middle ] [
      set pcolor green - 3
      set patch-id 1
      set name "door"
      set plabel "A1"
    ]
    ask patches with [ pxcor = min-pxcor and pycor < upper - middle and pycor >= lower - middle ] [
      set pcolor green - 3
      set patch-id 1
      set name "door"
      set plabel "A2"
    ]
  ]

  if exit-door-layout = "3-side A" [
    ask patches with [ pxcor = min-pxcor and pycor < upper + ((max-pycor - min-pycor) / 3) and pycor >= lower + ((max-pycor - min-pycor) / 3) ] [
      set pcolor green - 3
      set patch-id 1
      set name "door"
      set plabel "A"
    ]
    ask patches with [ pxcor = min-pxcor and pycor < upper and pycor >= lower ] [
      set pcolor green - 3
      set patch-id 1
      set name "door"
      set plabel "A"
    ]
    ask patches with [ pxcor = min-pxcor and pycor < upper + ((min-pycor - max-pycor) / 3) and pycor >= lower + ((min-pycor - max-pycor) / 3) ] [
      set pcolor green - 3
      set patch-id 1
      set name "door"
      set plabel "A"
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
    set agent-type "child"
    set max-speed 0.36 + random-float 0.24 - 0.12
    set energy random 20 + 80
    initialized-agent
  ]
  ; create adults
  create-persons num-people * adult-num / 100 [
    move-to one-of patches with [ pcolor = white and pxcor != 15 and (not any? other turtles-here) ]
    set color yellow
    set agent-type "adult"
    set max-speed 0.5 + random-float 0.24 - 0.12
    set energy random 10 + 90
    initialized-agent
  ]
  ; create seniors
  create-persons num-people * senior-num / 100 [
    move-to one-of patches with [ pcolor = white and pxcor != 15 and (not any? other turtles-here) ]
    set color orange
    set agent-type "senior"
    set max-speed 0.32 + random-float 0.24 - 0.12
    set energy random 30 + 70
    initialized-agent
  ]
  ; create disables
  create-persons num-people * disable-num / 100 [
    move-to one-of patches with [ pcolor = white and pxcor != 15 and (not any? other turtles-here) ]
    set color blue
    set agent-type "disabled"
    set max-speed 0.316 + random-float 0.256 - 0.128
    set energy random 40 + 60
    initialized-agent
  ]

;  ask patches [
;    set plabel patch-id
;    set plabel-color black
;  ]
end

to initialized-agent
  set size 1
  set shape "circle3"
  set state "alive"
  let init-direction 0 + random 360
  set vx sin init-direction
  set vy cos init-direction
  set counter 15
end

to blow-up
  ask n-of fire-count patches with [ patch-id = 0 and (not any? other turtles-here)] [
    sprout-fires 1 [
      set shape "fire"
      set color red
      set patch-id 1000
      set size 1
    ]
  ]
end


; ============================ GO BUTTON ============================

to calc-desired-direction
  ask persons [
    if [patch-id] of patch-here != 1 [
      let goal min-one-of (patches with [ name = "door" ]) [ distance myself ]
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
    let v (sqrt (vx * vx + vy * vy))

    ; kalau kena api
    agent-burnt

    ; kalau terhimpit
    agent-pressed

    ; kalau energy nya habis, mati
    agent-died

    ; kalau lihat api, reroute
    ifelse any? patches with [ patch-id = 1000 ] in-cone (v * visibility * c) field-of-view [
      set vx ((random 3 - 1) * vx * 3)
      set vy ((random 3 - 1) * vy * 3)
      set xcor xcor + vx
      set ycor ycor + vy
    ] []

    ; kecepatan agen sumbu x dan y
    ifelse can-move? (v * 2) [
      carefully [
        set xcor xcor + vx
        set ycor ycor + vy
      ] [
        set xcor xcor - vx
        set ycor ycor - vy
        show "I'm stuck!"
        set label "I'm stuck!"
        set label-color black
        set counter counter - 1
        if counter <= 0 [ show "Goodbye world, I'm gonna die" die set stuck stuck + 1]
      ]
    ] [
      carefully [
        let pengali -1
        while [can-move? (v * 2) = false] [
          set vx vx * (pengali * random-float 1)
          set vy vy * (pengali * random-float 1)
          set xcor xcor + vx
          set ycor ycor + vy
          set pengali pengali - 1
          ;set energy energy - 5

        ]
      ] []
    ]

    set travel-distance travel-distance + (sqrt (vx * vx + vy * vy))
  ]

  ; kalau sudah berhasil evakuasi
  ask patches with [ patch-id = 1 ] [
    if any? persons-here [
      ask persons-here [ die ]
    ]
  ]
end

to agent-burnt
  if patch-id = 1000 [
    set energy energy - 5
  ]
  if pcolor = grey + 2 [
    set energy energy - 2
  ]
end

to agent-pressed
  if count persons-on neighbors >= 6 [
    set energy energy - 1
  ]
end

to fire-spread
  ask patches with [ patch-id = 1000 ] [
    ask n-of 1 patches in-radius 1 [
      if random 100 < fire-spread-velocity [
        sprout-fires 1 [
          set shape "fire"
          set color red
          set patch-id 1000
          set size 2
        ]
      ]
    ]
  ]
end

to agent-died
  if energy <= 0 [
    set color black
    set vx 0
    set vy 0
    set xcor xcor + vx
    set ycor ycor + vy
    set state "die"
  ]
end

to smoke-spread
  ask patches [
    if patch-id = 1000 [
      if random 100 < smoke-spread-velocity [
        set pcolor grey + 2
      ]
    ]
    if patch-id = 0 and any? neighbors with [ pcolor = grey + 2 ] [
      if random 100 < smoke-spread-velocity [
        set pcolor grey + 2
      ]
    ]
  ]
end

to door-status
  ask patches with [ name = "door" ] [
    ifelse open-door? = true [
      set door-state "available"
      set patch-id 1
      set pcolor green - 2
    ] [
      set door-state "closed"
      set patch-id -2
      set pcolor pink
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

to-report person-velocity

end
@#$#@#$#@
GRAPHICS-WINDOW
352
34
825
508
-1
-1
15.0
1
8
1
1
1
0
0
0
1
-15
15
-15
15
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
80
21
143
54
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

INPUTBOX
9
59
158
119
num-people
400.0
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
max-pycor - min-pycor - 1
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
1442
47
1785
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
1659
255
1717
300
second
ticks * 0.2
2
1
11

SLIDER
124
276
242
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
124
195
243
228
adult-num
adult-num
0
100 - (child-num + senior-num + disable-num)
81.0
0.1
1
%
HORIZONTAL

SLIDER
124
236
243
269
senior-num
senior-num
0
100 - (child-num + adult-num + disable-num)
15.0
0.1
1
%
HORIZONTAL

SLIDER
124
315
243
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
126
170
276
188
Age Distribution
11
0.0
1

PLOT
1442
90
1642
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
1443
256
1643
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
164
59
270
92
draw-path?
draw-path?
1
1
-1000

PLOT
1655
88
1855
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
115
465
253
510
exit-door-layout
exit-door-layout
"1-side A" "2-side A" "3-side A" "1-side AC" "1-side ABD" "1-side ABCD"
0

TEXTBOX
1446
429
1809
541
mean [travel-distance] of persons\nmean [sqrt (vx * vx + vy * vy)] of persons\ncount persons with [ state = \"alive\" ]\ncount persons with [ state = \"die\" ]\n((max-pxcor - min-pxcor) * 0.5) * ((max-pxcor - min-pxcor) * 0.5)\nnum-people / (((max-pxcor - min-pxcor) * 0.5) * ((max-pxcor - min-pxcor) * 0.5))
11
0.0
1

SWITCH
165
97
271
130
danger?
danger?
1
1
-1000

SLIDER
1253
59
1345
92
fire-count
fire-count
1
5
5.0
1
1
NIL
HORIZONTAL

SLIDER
1251
174
1343
207
visibility
visibility
0
20
12.0
1
1
NIL
HORIZONTAL

MONITOR
1723
256
1780
301
death
count persons with [ state = \"die\" ]
17
1
11

SLIDER
1252
97
1389
130
smoke-spread-velocity
smoke-spread-velocity
0
5
2.5
0.1
1
NIL
HORIZONTAL

SLIDER
1251
135
1388
168
fire-spread-velocity
fire-spread-velocity
0
10
9.0
1
1
NIL
HORIZONTAL

CHOOSER
1254
261
1412
306
scenario
scenario
"door opened/closed"
0

SWITCH
1253
218
1372
251
open-door?
open-door?
0
1
-1000

MONITOR
254
194
316
239
luas m2
((max-pxcor - min-pxcor) * 0.5) * ((max-pycor - min-pycor) * 0.5)
1
1
11

MONITOR
256
247
313
292
orang
num-people
17
1
11

MONITOR
256
352
330
397
max-person
count patches with [ patch-id = 0 ]
0
1
11

MONITOR
256
300
315
345
density
num-people / (((max-pxcor - min-pxcor) * 0.5) * ((max-pxcor - min-pxcor) * 0.5))
5
1
11

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

fire
false
0
Polygon -7500403 true true 151 286 134 282 103 282 59 248 40 210 32 157 37 108 68 146 71 109 83 72 111 27 127 55 148 11 167 41 180 112 195 57 217 91 226 126 227 203 256 156 256 201 238 263 213 278 183 281
Polygon -955883 true false 126 284 91 251 85 212 91 168 103 132 118 153 125 181 135 141 151 96 185 161 195 203 193 253 164 286
Polygon -2674135 true false 155 284 172 268 172 243 162 224 148 201 130 233 131 260 135 282

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
  <experiment name="S-II.1.123" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-num">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="2"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="2"/>
      <value value="5"/>
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="300"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="S-II.2.12" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-num">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="2"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="2"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;2-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="300"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="S-II.3.1" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-num">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="2"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side AC&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="300"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="S-II.4.1" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-num">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="2"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side ABD&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="300"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="S-II.5.1" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-num">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="2"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side ABCD&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="300"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="S-I.123.1" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="600"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-num">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="2"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="true"/>
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
  <experiment name="S-I.123.2" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="600"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-num">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="2"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="true"/>
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
    <timeLimit steps="600"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-num">
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="2"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="true"/>
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
    <timeLimit steps="600"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-num">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="2"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="true"/>
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
    <timeLimit steps="600"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="2"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="true"/>
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
  <experiment name="36m2-density" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>(max-pxcor * 0.25) * (max-pycor * 0.25)</metric>
    <metric>num-people / ((max-pxcor * 0.25) * (max-pycor * 0.25))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="90"/>
      <value value="108"/>
      <value value="180"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="25m2-density" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>(max-pxcor * 0.25) * (max-pycor * 0.25)</metric>
    <metric>num-people / ((max-pxcor * 0.25) * (max-pycor * 0.25))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="63"/>
      <value value="75"/>
      <value value="125"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="49m2-density" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>(max-pxcor * 0.25) * (max-pycor * 0.25)</metric>
    <metric>num-people / (max-pxcor * 0.25) * (max-pycor * 0.25)</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="50"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
      <value value="350"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="36m2-density-personvary" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>(max-pxcor * 0.25) * (max-pycor * 0.25)</metric>
    <metric>num-people / (max-pxcor * 0.25) * (max-pycor * 0.25)</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="72"/>
      <value value="144"/>
      <value value="216"/>
      <value value="288"/>
      <value value="360"/>
      <value value="432"/>
      <value value="504"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="36m2-144-exitwidthvary" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>(max-pxcor * 0.25) * (max-pycor * 0.25)</metric>
    <metric>num-people / (max-pxcor * 0.25) * (max-pycor * 0.25)</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="1"/>
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
      <value value="12"/>
      <value value="14"/>
      <value value="16"/>
      <value value="18"/>
      <value value="20"/>
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="144"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="49m2-density-personvary" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>(max-pxcor * 0.25) * (max-pycor * 0.25)</metric>
    <metric>num-people / ((max-pxcor * 0.25) * (max-pycor * 0.25))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="245"/>
      <value value="147"/>
      <value value="123"/>
      <value value="74"/>
      <value value="49"/>
      <value value="25"/>
      <value value="20"/>
      <value value="15"/>
      <value value="10"/>
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="100m2-density" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="600"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>(max-pxcor * 0.25) * (max-pycor * 0.25)</metric>
    <metric>num-people / (max-pxcor * 0.25) * (max-pycor * 0.25)</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="100"/>
      <value value="110"/>
      <value value="120"/>
      <value value="130"/>
      <value value="140"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
      <value value="350"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="25m2-density2" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>(max-pxcor * 0.25) * (max-pycor * 0.25)</metric>
    <metric>num-people / ((max-pxcor * 0.25) * (max-pycor * 0.25))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="3"/>
      <value value="5"/>
      <value value="8"/>
      <value value="10"/>
      <value value="13"/>
      <value value="25"/>
      <value value="38"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="36m2-density2" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>(max-pxcor * 0.25) * (max-pycor * 0.25)</metric>
    <metric>num-people / ((max-pxcor * 0.25) * (max-pycor * 0.25))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="4"/>
      <value value="7"/>
      <value value="11"/>
      <value value="14"/>
      <value value="18"/>
      <value value="36"/>
      <value value="54"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="81m2-density" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>(max-pxcor * 0.25) * (max-pycor * 0.25)</metric>
    <metric>num-people / ((max-pxcor * 0.25) * (max-pycor * 0.25))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="8"/>
      <value value="16"/>
      <value value="24"/>
      <value value="32"/>
      <value value="41"/>
      <value value="81"/>
      <value value="122"/>
      <value value="162"/>
      <value value="203"/>
      <value value="243"/>
      <value value="324"/>
      <value value="405"/>
      <value value="486"/>
      <value value="567"/>
      <value value="648"/>
      <value value="729"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="36m2-144-exitwidth-2doors" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>(max-pxcor * 0.25) * (max-pycor * 0.25)</metric>
    <metric>num-people / ((max-pxcor * 0.25) * (max-pycor * 0.25))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="1"/>
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
      <value value="12"/>
      <value value="14"/>
      <value value="16"/>
      <value value="18"/>
      <value value="20"/>
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;2-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="144"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="100m2-400-ew-2sideAC" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>((max-pxcor - min-pxcor) * 0.5) * ((max-pxcor - min-pxcor) * 0.5)</metric>
    <metric>num-people / (((max-pxcor - min-pxcor) * 0.5) * ((max-pxcor - min-pxcor) * 0.5))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
      <value value="12"/>
      <value value="14"/>
      <value value="16"/>
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side AC&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="200"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="100m2-400-ew-1sideA" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>((max-pxcor - min-pxcor) * 0.5) * ((max-pxcor - min-pxcor) * 0.5)</metric>
    <metric>num-people / (((max-pxcor - min-pxcor) * 0.5) * ((max-pxcor - min-pxcor) * 0.5))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
      <value value="12"/>
      <value value="14"/>
      <value value="16"/>
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="250"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="100m2-400-ew-1sideABCD" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>((max-pxcor - min-pxcor) * 0.5) * ((max-pxcor - min-pxcor) * 0.5)</metric>
    <metric>num-people / (((max-pxcor - min-pxcor) * 0.5) * ((max-pxcor - min-pxcor) * 0.5))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
      <value value="12"/>
      <value value="14"/>
      <value value="16"/>
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side ABCD&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="200"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="100m2-400-exitwidth-2sideA" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>((max-pxcor - min-pxcor) * 0.5) * ((max-pxcor - min-pxcor) * 0.5)</metric>
    <metric>num-people / (((max-pxcor - min-pxcor) * 0.5) * ((max-pxcor - min-pxcor) * 0.5))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;2-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="250"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="100m2-400-ew-1sideABD" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>((max-pxcor - min-pxcor) * 0.5) * ((max-pxcor - min-pxcor) * 0.5)</metric>
    <metric>num-people / (((max-pxcor - min-pxcor) * 0.5) * ((max-pxcor - min-pxcor) * 0.5))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
      <value value="12"/>
      <value value="14"/>
      <value value="16"/>
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side ABD&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="200"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="100m2-400-ew-3sideA" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>((max-pxcor - min-pxcor) * 0.5) * ((max-pxcor - min-pxcor) * 0.5)</metric>
    <metric>num-people / (((max-pxcor - min-pxcor) * 0.5) * ((max-pxcor - min-pxcor) * 0.5))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
      <value value="12"/>
      <value value="14"/>
      <value value="16"/>
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;3-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="250"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="density-100m2" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="600"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>((max-pxcor - min-pxcor) * 0.5) * ((max-pycor - min-pycor) * 0.5)</metric>
    <metric>num-people / (((max-pxcor - min-pxcor) * 0.5) * ((max-pycor - min-pycor) * 0.5))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="100"/>
      <value value="110"/>
      <value value="120"/>
      <value value="130"/>
      <value value="140"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
      <value value="350"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="density-81m2" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="600"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>((max-pxcor - min-pxcor) * 0.5) * ((max-pycor - min-pycor) * 0.5)</metric>
    <metric>num-people / (((max-pxcor - min-pxcor) * 0.5) * ((max-pycor - min-pycor) * 0.5))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="8"/>
      <value value="16"/>
      <value value="24"/>
      <value value="32"/>
      <value value="41"/>
      <value value="59"/>
      <value value="57"/>
      <value value="65"/>
      <value value="73"/>
      <value value="81"/>
      <value value="89"/>
      <value value="97"/>
      <value value="105"/>
      <value value="113"/>
      <value value="122"/>
      <value value="162"/>
      <value value="203"/>
      <value value="243"/>
      <value value="284"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="density-64m2" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="600"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>(max-pxcor * 0.25) * (max-pycor * 0.25)</metric>
    <metric>num-people / ((max-pxcor * 0.25) * (max-pycor * 0.25))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="6"/>
      <value value="13"/>
      <value value="19"/>
      <value value="26"/>
      <value value="32"/>
      <value value="38"/>
      <value value="45"/>
      <value value="51"/>
      <value value="58"/>
      <value value="64"/>
      <value value="70"/>
      <value value="77"/>
      <value value="83"/>
      <value value="90"/>
      <value value="96"/>
      <value value="128"/>
      <value value="160"/>
      <value value="192"/>
      <value value="224"/>
      <value value="256"/>
      <value value="288"/>
      <value value="320"/>
      <value value="384"/>
      <value value="448"/>
      <value value="512"/>
      <value value="576"/>
      <value value="640"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="density-49m2" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="600"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>(max-pxcor * 0.25) * (max-pycor * 0.25)</metric>
    <metric>num-people / ((max-pxcor * 0.25) * (max-pycor * 0.25))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="29"/>
      <value value="34"/>
      <value value="39"/>
      <value value="44"/>
      <value value="49"/>
      <value value="54"/>
      <value value="59"/>
      <value value="64"/>
      <value value="69"/>
      <value value="74"/>
      <value value="98"/>
      <value value="123"/>
      <value value="147"/>
      <value value="172"/>
      <value value="196"/>
      <value value="221"/>
      <value value="245"/>
      <value value="294"/>
      <value value="343"/>
      <value value="392"/>
      <value value="441"/>
      <value value="490"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="100m2-population static-density vary" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="600"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>((max-pxcor - min-pxcor) * 0.5) * ((max-pxcor - min-pxcor) * 0.5)</metric>
    <metric>num-people / (((max-pxcor - min-pxcor) * 0.5) * ((max-pxcor - min-pxcor) * 0.5))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="50"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
      <value value="350"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="density-36m2" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="600"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>(max-pxcor * 0.25) * (max-pycor * 0.25)</metric>
    <metric>num-people / ((max-pxcor * 0.25) * (max-pycor * 0.25))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="4"/>
      <value value="7"/>
      <value value="11"/>
      <value value="14"/>
      <value value="18"/>
      <value value="22"/>
      <value value="25"/>
      <value value="29"/>
      <value value="32"/>
      <value value="36"/>
      <value value="40"/>
      <value value="43"/>
      <value value="47"/>
      <value value="50"/>
      <value value="54"/>
      <value value="72"/>
      <value value="90"/>
      <value value="108"/>
      <value value="126"/>
      <value value="144"/>
      <value value="162"/>
      <value value="180"/>
      <value value="216"/>
      <value value="252"/>
      <value value="288"/>
      <value value="324"/>
      <value value="360"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="density-25m2" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="600"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>(max-pxcor * 0.25) * (max-pycor * 0.25)</metric>
    <metric>num-people / ((max-pxcor * 0.25) * (max-pycor * 0.25))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="3"/>
      <value value="5"/>
      <value value="8"/>
      <value value="10"/>
      <value value="13"/>
      <value value="15"/>
      <value value="18"/>
      <value value="20"/>
      <value value="23"/>
      <value value="25"/>
      <value value="28"/>
      <value value="30"/>
      <value value="33"/>
      <value value="35"/>
      <value value="38"/>
      <value value="59"/>
      <value value="63"/>
      <value value="75"/>
      <value value="88"/>
      <value value="100"/>
      <value value="113"/>
      <value value="125"/>
      <value value="150"/>
      <value value="175"/>
      <value value="200"/>
      <value value="225"/>
      <value value="250"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="density-16m2" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="600"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>(max-pxcor * 0.25) * (max-pycor * 0.25)</metric>
    <metric>num-people / ((max-pxcor * 0.25) * (max-pycor * 0.25))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="2"/>
      <value value="3"/>
      <value value="5"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
      <value value="11"/>
      <value value="13"/>
      <value value="14"/>
      <value value="16"/>
      <value value="18"/>
      <value value="19"/>
      <value value="21"/>
      <value value="22"/>
      <value value="24"/>
      <value value="32"/>
      <value value="40"/>
      <value value="48"/>
      <value value="56"/>
      <value value="64"/>
      <value value="72"/>
      <value value="80"/>
      <value value="96"/>
      <value value="112"/>
      <value value="128"/>
      <value value="144"/>
      <value value="160"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="225m2-population static-density vary" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="600"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>((max-pxcor - min-pxcor) * 0.5) * ((max-pxcor - min-pxcor) * 0.5)</metric>
    <metric>num-people / (((max-pxcor - min-pxcor) * 0.5) * ((max-pxcor - min-pxcor) * 0.5))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="50"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
      <value value="350"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="10x15m2-population static-density vary" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="600"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>((max-pxcor - min-pxcor) * 0.5) * ((max-pycor - min-pycor) * 0.5)</metric>
    <metric>num-people / (((max-pxcor - min-pxcor) * 0.5) * ((max-pycor - min-pycor) * 0.5))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="50"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
      <value value="350"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="15x10m2-population static-density vary" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="600"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>((max-pxcor - min-pxcor) * 0.5) * ((max-pycor - min-pycor) * 0.5)</metric>
    <metric>num-people / (((max-pxcor - min-pxcor) * 0.5) * ((max-pycor - min-pycor) * 0.5))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="50"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
      <value value="350"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="81m2-population static-density vary" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="600"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>((max-pxcor - min-pxcor) * 0.5) * ((max-pycor - min-pycor) * 0.5)</metric>
    <metric>num-people / (((max-pxcor - min-pxcor) * 0.5) * ((max-pycor - min-pycor) * 0.5))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="50"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
      <value value="350"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="400m2-population static-density vary" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="600"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>((max-pxcor - min-pxcor) * 0.5) * ((max-pycor - min-pycor) * 0.5)</metric>
    <metric>num-people / (((max-pxcor - min-pxcor) * 0.5) * ((max-pycor - min-pycor) * 0.5))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="50"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
      <value value="350"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="625m2-population static-density vary" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="600"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>((max-pxcor - min-pxcor) * 0.5) * ((max-pycor - min-pycor) * 0.5)</metric>
    <metric>num-people / (((max-pxcor - min-pxcor) * 0.5) * ((max-pycor - min-pycor) * 0.5))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="50"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
      <value value="350"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="density-400m2" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="600"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>((max-pxcor - min-pxcor) * 0.5) * ((max-pycor - min-pycor) * 0.5)</metric>
    <metric>num-people / (((max-pxcor - min-pxcor) * 0.5) * ((max-pycor - min-pycor) * 0.5))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="800"/>
      <value value="1000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="density-225m2" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="600"/>
    <metric>mean [travel-distance] of persons</metric>
    <metric>mean [sqrt (vx * vx + vy * vy)] of persons</metric>
    <metric>count persons with [ state = "alive" ]</metric>
    <metric>count persons with [ state = "die" ]</metric>
    <metric>((max-pxcor - min-pxcor) * 0.5) * ((max-pycor - min-pycor) * 0.5)</metric>
    <metric>num-people / (((max-pxcor - min-pxcor) * 0.5) * ((max-pycor - min-pycor) * 0.5))</metric>
    <enumeratedValueSet variable="sigma">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-door?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="senior-num">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-spread-velocity">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visibility">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smoke-spread-velocity">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fire-count">
      <value value="5"/>
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
    <enumeratedValueSet variable="field-of-view">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-width">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="danger?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exit-door-layout">
      <value value="&quot;1-side A&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;door opened/closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-people">
      <value value="23"/>
      <value value="45"/>
      <value value="68"/>
      <value value="90"/>
      <value value="113"/>
      <value value="135"/>
      <value value="158"/>
      <value value="180"/>
      <value value="203"/>
      <value value="225"/>
      <value value="248"/>
      <value value="270"/>
      <value value="293"/>
      <value value="315"/>
      <value value="338"/>
      <value value="450"/>
      <value value="563"/>
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
