breed [citizens citizen]
breed [soldiers soldier]

citizens-own [anger
              fear
              violence
              hurt
              attack-mod]

patches-own [city-density]
soldiers-own [redcounter]
globals [num-attacks casualties death-toll civs-hurt attack-effectiveness init-civs num-soldiers]

to setup
  clear-all
  set num-attacks 0
  set death-toll 0
  set casualties 0
  set civs-hurt 0


  ask n-of  (count patches * (density / 100)) patches
             [sprout-citizens 1 [set color green set shape "circle"]]
  set init-civs count citizens


  set num-soldiers (count citizens) / Citizen-Soldier-Ratio
  let empty-patches count patches with [not any? turtles-here]
  if num-soldiers < 1 [set num-soldiers 1]
  if num-soldiers > empty-patches [set num-soldiers empty-patches]
  ask n-of num-soldiers patches with [not any? turtles-here]
               [sprout-soldiers 1 [set color blue set shape "square"]]

  ask citizens [set hurt 0
                set attack-mod 1
                set anger random-normal .25 .125
                if anger > 1 [set anger 1]
                if anger < 0 [set anger 0]
                set fear random-normal .5 .25
                if fear > 1 [set fear 1]
                if fear < 0 [set fear 0]
                set violence random-normal .5 .25
                if violence > 1 [set violence 1]
                if violence < 0 [set violence 0]
                ]
  ask citizens with [anger > violence and anger > fear] [set shape "star" set-civ-color]
  ask turtles [
    set heading 0
    let mover (random (count patches * (density)))
    while [turtle (random (count patches * (density))) = nobody] [
      set mover (random (count patches * (density)))
    ]
    move-to one-of turtles
    while [any? other turtles-here] [
        rt ((random 4) * 90)
        fd 1
        set heading 0

    ]
  ]
  reset-ticks

end

to set-civ-color
  set color green
  if anger > fear and violence > anger [set color yellow]
  if anger > violence and fear > anger [set color yellow]
  if anger > violence and anger > fear [set color orange set shape "star"]

end

to go
  let temp-attacks num-attacks
  let attacker no-turtles
  ask citizens [
     ifelse anger > violence and anger > fear [set shape "star" set-civ-color] [set shape "circle" set-civ-color]]
  set attacker one-of citizens with [shape = "star" and any? soldiers in-radius 3]
  if attacker != nobody
       [ask attacker [set color red
                     wait .1
                     launch-attack
                     ]
        counter-strike attacker
       ]
   tick
   if temp-attacks = num-attacks [stop]
end

to counter-strike [target]
  let target-location [patch-here] of target
  set attack-effectiveness effectiveness
  ifelse random 100 < attack-effectiveness
         [ ask target [die]
           set death-toll death-toll + 1
           if replacement? [ask one-of patches with [not any? turtles-here]
                              [sprout-citizens 1
                                [set-civ-color
                                 set shape "circle"
                                 set fear mean [fear] of citizens in-radius 3 ; NOT exactly as Bennett see article 6.1
                                 set anger mean [anger] of citizens in-radius 3
                                 set violence random-normal .5 .25
                                 if violence > 1 [set violence 1]
                                 if violence < 0 [set violence 0]
                                 set-civ-color]]]
          ]
         [ask target [set attack-mod attack-mod + (attack-mod * .1)]] ; if the target isn't killed it becomes more effective

  let num-hurt 0
  ask target-location [
                ask citizens in-radius 3
                     [if random 101 > Accuracy
                        [set num-hurt num-hurt + 1
                         set civs-hurt civs-hurt + 1
                         set hurt 1]]
                ask citizens in-radius 3 with [hurt = 1]
                    [set fear fear + (.1 * (1 - fear))
                     set anger anger + (.05 * num-hurt * (1 - anger))
                     set hurt 0]]
   end

to launch-attack
   ask soldiers [set redcounter redcounter - 1
                 ifelse redcounter < 0 [set redcounter 0] [set color red]
                 if redcounter = 0  [set color blue]]
   set num-attacks num-attacks  + 1
   ask one-of soldiers in-radius 3 [set color red set redcounter 3]
   if random 100 < (insurgent-deadliness * attack-mod)
     [
       set casualties casualties + 1
       if soldiers-move? [ask one-of soldiers in-radius 3 [die]
       ask one-of patches with [not any? turtles-here]
           [sprout-soldiers 1 [set color blue set shape "square"]]]
      ]

end
@#$#@#$#@
GRAPHICS-WINDOW
417
10
1037
651
30
30
10.0
1
10
1
1
1
0
0
0
1
-30
30
-30
30
1
1
1
ticks
30.0

SLIDER
13
48
185
81
Density
Density
0
90
42
1
1
%
HORIZONTAL

BUTTON
28
10
91
43
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
97
10
160
43
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

SLIDER
12
84
184
117
Citizen-Soldier-Ratio
Citizen-Soldier-Ratio
5
100
5
1
1
NIL
HORIZONTAL

SLIDER
10
166
182
199
Accuracy
Accuracy
0
100
50
1
1
%
HORIZONTAL

SLIDER
10
204
182
237
Effectiveness
Effectiveness
0
100
50
1
1
%
HORIZONTAL

PLOT
12
252
262
388
Casualty Ratio (deaths/initial#)
Time
Ratio
0.0
1.0
0.0
1.0
true
true
"" ""
PENS
"Civilian " 1.0 0 -16777216 true "" "plot (death-toll / init-civs)"
"Military " 1.0 0 -2674135 true "" "plot (casualties / num-soldiers)"

SWITCH
222
30
357
63
Replacement?
Replacement?
1
1
-1000

SWITCH
207
691
346
724
Soldiers-Move?
Soldiers-Move?
1
1
-1000

SLIDER
9
129
181
162
Insurgent-Deadliness
Insurgent-Deadliness
0
20
11
1
1
%
HORIZONTAL

TEXTBOX
205
741
370
797
With movement on, soldiers may\nappear in a new location after\n'death'
11
0.0
1

TEXTBOX
210
73
395
157
With replacement killed insurgents\nare replaced with new civilians with\nfear and anger = local means and a new violence threshold
11
0.0
1

MONITOR
277
239
344
284
NIL
death-toll
17
1
11

PLOT
15
400
263
550
Citizen Violence Propensity
ticks
v
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [violence] of citizens"

@#$#@#$#@
## WHAT IS IT?

This section could give a general understanding of what the model is trying to show or explain.

## HOW IT WORKS

This section could explain what rules the agents use to create the overall behavior of the model.

## HOW TO USE IT

This section could explain how to use the model, including a description of each of the items in the interface tab.

## THINGS TO NOTICE

This section could give some ideas of things for the user to notice while running the model.

## THINGS TO TRY

This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.

## EXTENDING THE MODEL

This section could give some ideas of things to add or change in the procedures tab to make the model more complicated, detailed, accurate, etc.

## NETLOGO FEATURES

This section could point out any especially interesting or unusual features of NetLogo that the model makes use of, particularly in the Procedures tab.  It might also point out places where workarounds were needed because of missing features.

## RELATED MODELS

This section could give the names of models in the NetLogo Models Library or elsewhere which are of related interest.

## CREDITS AND REFERENCES

This section could contain a reference to the model's URL on the web if it has one, as well as any other necessary credits or references.
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
