globals      [ pointer
               brush-radius
               current-file
               small-brush-size
               big-brush-size
               undo-point
               undo-length
             ]

breeds       [ pointers
               markers
             ]

patches-own  [ sample-color unpainted? history ]

pointers-own [ start-x start-y marker-count moved? old-x old-y clicks ]
markers-own  [ start-x start-y marker-count order ]

to startup
    setup
    clear
end

to setup
    locals [ current-tool ]
    
    set small-brush-size 5
    set big-brush-size 10
    if big-brush-size > screen-edge-x
    [ set big-brush-size screen-edge-x ]

    ;; make sure there are no left-over markers
    set current-tool tool
    set tool "brush"
    wait .1
    clear-turtles

    ;; create pointer turtle
    create-custom-pointers 1
    [ setxy 0 0
      set clicks 0
      set pointer self
      set moved? false
    ]
    ask patches
    [ set unpainted? true
      if not is-list? history
      [ set history []
      ]
    ]
    set tool current-tool
    draw
end

to draw
    if not is-turtle? pointer [ setup ]
      ifelse tool = "brush"               [ do-brush     ]  ; 1
    [ ifelse tool = "lines"               [ do-lines     ]  ; 2
    [ ifelse tool = "fills"               [ do-fills   0 ]  ; 3
    [ ifelse tool = "fill-shades"         [ do-fills   1 ]  ; 4
    [ ifelse tool = "boxes"               [ do-boxes   0 ]  ; 5
    [ ifelse tool = "frames"              [ do-boxes   1 ]  ; 6
    [ ifelse tool = "rings"               [ do-circles 0 ]  ; 7
    [ ifelse tool = "circles"             [ do-circles 1 ]  ; 8
    [ ifelse tool = "pick-color"          [ do-pick      ]  ; 9
    [ ifelse tool = "change-color"        [ do-change    ]  ;10
    [ stop ] ; note: need one close bracket for each option
    ]]]]] ]]]]
end

to select-color [ hue ]
    set brush hue
end

to clear
    record-history
    ask patches
    [ set pcolor canvas
      set unpainted? true
    ]
end

to set-brush-radius
   set brush-radius int ( ( brush-width * .5 ))
end

to do-brush
    locals [  brush-x brush-y ]   

    ask pointer
    [ if shape != "tip" [ set shape "tip" ]
      if size != small-brush-size [ set size small-brush-size ]
      if color != brush [ set color brush ]
      set brush-x (round mouse-xcor)
      set brush-y (round mouse-ycor)
      set moved? old-x != brush-x or old-y != brush-y
      if moved?
      [ set old-x xcor
        set old-y ycor
        setxy brush-x brush-y
        set unpainted? true
      ]
      if mouse-down? and unpainted?
      [ if clicks = 0
        [ ; this is the beginning of a brush-stroke
          record-history 
          set clicks 1
        ]
        brush-paint
      ]
      if not (mouse-down? or unpainted?)
      [ set unpainted? false
        set clicks 0
      ]
    ]
end

to do-lines
    locals [  brush-x brush-y index]

      ask pointer
      [ if shape != "ch" [ set shape "ch" ]
        if size != big-brush-size [ set size big-brush-size ]
        if color != brush [ set color brush ]
        set brush-x (round mouse-xcor)
        set brush-y (round mouse-ycor)
        set moved? old-x != brush-x or old-y != brush-y
        if moved?
        [ set old-x xcor
          set old-y ycor
          setxy brush-x brush-y
        ]
        ifelse clicks = 0 and mouse-down?
          [ set clicks .5 ]
          [ ifelse clicks = 0.5 and not mouse-down?
            [ set start-x brush-x
              set start-y brush-y
              set marker-count 5 + 2 * int ( log ( screen-size-x * screen-size-y ) 10)
              set index 0
              hatch marker-count
              [ set breed markers
                set color inverse? pcolor
                set shape "bx"
                set size 1 ; (brush-radius + 1) ; big size is slow and ugly!
                set order index / marker-count
                set index index + 1
              ]
              set clicks 1
            ]
            [ ifelse clicks = 1 or clicks = 1.5 
              [ if moved?
                [
                  ask markers
                  [ set xcor start-x + order * ( brush-x - start-x )
                    set ycor start-y + order * ( brush-y - start-y)
                    set color inverse? pcolor
                  ]
                ]
                ifelse clicks = 1 and mouse-down?
                [ set clicks 1.5 ]
                [ if clicks = 1.5 and not mouse-down?
                  [ set clicks 2 ]
                ]
              ]
              [ if clicks = 2
                [ ; 2nd click: draw the line indicated
                  ask markers
                  [ die ]
                  record-history
                  line-paint start-x start-y brush-x brush-y
                  set clicks 0
                ]
              ]
            ]
          ]
        ]
 
end ; do-lines

to do-circles [ mode ]
    locals [  brush-x brush-y index radius]
      ask pointer
      [ if shape != "chc" [ set shape "chc" ]
        if size != big-brush-size [ set size big-brush-size ]
        if color != brush [ set color brush ]
        set brush-x (round mouse-xcor)
        set brush-y (round mouse-ycor)
        set moved? old-x != brush-x or old-y != brush-y
        if moved?
        [ set old-x xcor
          set old-y ycor
          setxy brush-x brush-y
        ]
        ifelse clicks = 0 and mouse-down?
          [ set clicks .5
          ]
          [ ifelse clicks = 0.5 and not mouse-down?
            [ set start-x brush-x
              set start-y brush-y
              set marker-count 20 ; 4 + int ( log ( screen-size-x * screen-size-y ) 10)
              set index 0
              hatch marker-count
              [ set breed markers
                set color inverse? pcolor
                set shape "bx"
                set size 1
                set order index / marker-count * 360
                set index index + 1
              ]
              set clicks 1
            ]
            [ ifelse clicks = 1 or clicks = 1.5 
              [ if moved? [
                  set radius distancexy-nowrap start-x start-y
                  ask markers
                  [
                    set xcor start-x + radius * sin order
                    set ycor start-y + radius * cos order
                    set color inverse? pcolor
                  ]
                ]
                ifelse clicks = 1 and mouse-down?
                [ set clicks 1.5 ]
                [ if clicks = 1.5 and not mouse-down?
                  [ set clicks 2 ]
                ]
              ]
              [ if clicks = 2
                [ ; 2nd click: draw the line indicated
                  set clicks 0
                  ask markers
                  [ die ]
                  record-history
                  ifelse mode = 0
                  [ circle-paint-edge start-x start-y brush-x brush-y ]
                  [ circle-paint-solid start-x start-y brush-x brush-y ]
                ]
              ]
            ]
          ]
        ]
 
end ; do-circles

to do-fills [ mode ]
    locals [  brush-x brush-y ]
    ask pointer
    [ if shape != "ch" [ set shape "ch" ]
      if size != big-brush-size [ set size big-brush-size ]
      if color != brush [ set color brush ]
      set brush-x (round mouse-xcor)
      set brush-y (round mouse-ycor)
      set moved? old-x != brush-x or old-y != brush-y
      if moved?
      [ set old-x xcor
        set old-y ycor
        setxy brush-x brush-y
      ]
      if clicks = 0 and mouse-down?
      [ set clicks 1 ]
      if clicks = 1 and not mouse-down?
      [ set clicks 0
        ask patches with [ not unpainted? ]
        [ set unpainted? true ]
        record-history
        ifelse mode = 0
        [ fill-solids pcolor ]
        [ fill-shades pcolor ]
      ]
    ]
end ; do-fills

to do-change
    locals [  brush-x brush-y ]
    ask pointer
    [ if shape != "cp" [ set shape "cp" ]
      if size != 10 [ set size 10 ]
      ; if color != brush [ set color brush ]
      set brush-x (round mouse-xcor)
      set brush-y (round mouse-ycor)
      if old-x != brush-x or old-y != brush-y
      [ set old-x xcor
        set old-y ycor
        setxy brush-x brush-y
      ]
      set color pcolor
      if clicks = 0 and mouse-down?
      [ set clicks 1 ]
      if clicks = 1 and not mouse-down?
      [ set clicks 0
        record-history
        ask patches with [ pcolor = color-of myself ]
        [ set pcolor brush ]
      ]
    ]
end ; do-change

to-report plus-or-minus-one
    report ( ( ( random 2 ) * 2 ) - 1 )
end

to-report zero-or-one
    report random 2
end

to do-boxes [ mode ]
    locals [  brush-x brush-y index]
      ask pointer
      [ if shape != "chbx" [ set shape "chbx" ]
        if size != big-brush-size [ set size big-brush-size ]
        if color != brush [ set color brush ]
        set brush-x (round mouse-xcor)
        set brush-y (round mouse-ycor)
        set moved? old-x != brush-x or old-y != brush-y
        if moved?
        [ set old-x xcor
          set old-y ycor
          setxy brush-x brush-y
        ]
        ifelse clicks = 0 and mouse-down?
        [ set clicks .5
        ]
        [ ifelse clicks = 0.5 and not mouse-down?
          [ set start-x brush-x
            set start-y brush-y
            set marker-count 32
            set index 0
            set clicks 1
            hatch marker-count
            [ set breed markers
              set color inverse? pcolor
              set shape "bx"
              set size 1
              set order index
              set index index + 1
            ]
          ]
          [ ifelse clicks = 1 or clicks = 1.5 
            [ if moved?
              [
                ask markers
                [ ifelse order < 16
                  [ set xcor start-x + order mod 2 * ( brush-x - start-x )
                    set ycor start-y + int( order / 2 ) / 8.0 * ( brush-y - start-y )
                  ]
                  [ set xcor start-x + int( (order - 16) / 2) / 8.0 * ( brush-x - start-x )  
                    set ycor start-y + order mod 2 * ( brush-y - start-y )
                  ]
                  set color inverse? pcolor  
                ]
              ]
              ifelse clicks = 1 and mouse-down?
              [ set clicks 1.5
              ]
              [ if clicks = 1.5 and not mouse-down?
                [ set clicks 2
                ]
              ]
            ]
            [ if clicks = 2
              [ ; 2nd click: draw the box indicated
                ask markers
                [ die ]
                record-history
                ifelse mode = 0
                [ frame-paint start-x start-y brush-x brush-y ]
                [ box-paint   start-x start-y brush-x brush-y ]
                set clicks 0
              ]
            ]
          ]
        ]
      ]
end

to do-pick
    locals [  brush-x brush-y ]
    ask pointer
    [ if shape != "cp" [ set shape "cp" ]
      if size != 10 [ set size 10 ]
      ; if color != brush [ set color brush ]
      set brush-x (round mouse-xcor)
      set brush-y (round mouse-ycor)
      if old-x != brush-x or old-y != brush-y
      [ set old-x xcor
        set old-y ycor
        setxy brush-x brush-y
      ]
      set color pcolor
      if clicks = 0 and mouse-down?
      [ set clicks 1 ]
      if clicks = 1 and not mouse-down?
      [ set clicks 0
        select-color pcolor
      ]
    ]
end ; do-pick

;to brush-paint-solid
;    ifelse brush-width = 1
;    [ stamp brush ]
;    [ set-brush-radius
;      ask patches in-radius brush-radius with
;                  [     pcolor != brush
;                    and abs (pxcor - xcor-of myself) <= brush-radius
;                    and abs (pycor - ycor-of myself) <= brush-radius
;                  ]        
;      [ set pcolor brush ]
;    ]
;end ; brush-paint-solid

to brush-paint
    locals [ result mypatches mypxcor mypycor]
    ifelse brush-width = 1
    [ stamp-efx
      set unpainted? false
    ]   
    [ set-brush-radius
      set mypatches patches in-radius brush-radius
                            with [ distance-nowrap myself <= brush-radius ]
      paint-efx mypatches
      ask mypatches [ set unpainted? false ]
    ]
end

to line-paint [ x1 y1 x2 y2 ] ; input end-points of line
; effects: "1 solid" "2 dappled" "3 undapple" "4 darken" "5 lighten" "6 blend"
    locals [ b-left b-top       ;
             b-right b-bottom   ; corners of the bounding box
             ex-left ex-top     ;
             ex-right ex-bottom ; corners of the bounding box, EXpanded by brush-radius
             mybox           ; patches within the expanded bounding box
             myline          ; patches directly along the line
             myendpoints     ; patches in radius brush-radius of the end-points
             mystroke        ; patches within brush-radius of the line
             mypatches       ; patches in mybox within brushwith of myline
                             ; union of mystroke and myendpoints
              
             ; equation for a line, in terms of y : y = mx + b
             m         ; slope, rise / run, y-delta / x-delta, aka m 
             b        ; y intercept, aka b
             ; same line, in terms of x: x = ny + a
             n         ; slope, run / rise, x-delta / y-delta,  aka n  
             a         ; x intercept, aka a
           ]
  
    set-brush-radius   
    ifelse x1 <= x2
    [ set b-left x1      set b-right x2 ]
    [ set b-left x2      set b-right x1 ]
    ifelse y1 <= y2
    [ set b-top y1      set b-bottom y2 ]
    [ set b-top y2      set b-bottom y1 ]
    
    set ex-left   b-left   - brush-radius
    set ex-top    b-top    - brush-radius
    set ex-right  b-right  + brush-radius
    set ex-bottom b-bottom + brush-radius

    set mybox  patches with [     pxcor >= ex-left and pxcor <= ex-right
                              and pycor >= ex-top  and pycor <= ex-bottom ]

    ifelse b-top = b-bottom or b-left = b-right
    [
      set myline mybox with [     pxcor >= b-left
                              and pxcor <= b-right
                              and pycor >= b-top
                              and pycor <= b-bottom
                            ]
    ]
    [ set m ( y1 - y2 ) / ( x1 - x2 )
      set n ( x1 - x2 ) / ( y1 - y2 )
      set b  y1 - ( m * x1 )
      set a  x1 - ( n * y1 )
      
      ; find patches that lie along the line
      set myline mybox with
                 [     pxcor >= b-left and pxcor <= b-right
                   and pycor >= b-top  and pycor <= b-bottom 
                   and (   pycor = round ( m * pxcor + b )
                        or pxcor = round ( n * pycor + a )
                       )
                 ]
    ]
  set mypatches mybox with [ min values-from myline [ distance-nowrap myself] <= brush-radius ]
  ; slower...
  ; set mypatches mybox with [ any myline with [ distance-nowrap myself <= brush-radius ] ]
  paint-efx mypatches
  
end  ; line-paint

to circle-paint-edge [ cx cy ex ey ]
    locals [ inner-radius outer-radius]
    
    set-brush-radius
    ask patch cx cy
    [ set inner-radius ( round distancexy-nowrap ex ey ) - brush-radius 
      set outer-radius inner-radius + brush-width 
      paint-efx patches in-radius outer-radius with [ (distance-nowrap myself) >= inner-radius ]
     ]
end ; circle-paint-edge

to box-paint [ x1 y1 x2 y2 ]
    locals [ tempxy ]
    if x1 > x2 [ set tempxy x1 set x1 x2 set x2 tempxy ]
    if y1 > y2 [ set tempxy y1 set y1 y2 set y2 tempxy ]
    set-brush-radius
    paint-efx patches with [    pxcor >= x1 - brush-radius and pxcor <= x2 + brush-radius
                                 and pycor >= y1 - brush-radius and pycor <= y2 + brush-radius 
                                 and not (      pxcor > x1 + brush-radius 
                                            and pxcor < x2 - brush-radius 
                                            and pycor > y1 + brush-radius
                                            and pycor < y2 - brush-radius
                                         )
                                ]
end

to frame-paint [ x1 y1 x2 y2 ]
    locals [ tempxy ]
    if x1 > x2 [ set tempxy x1 set x1 x2 set x2 tempxy ]
    if y1 > y2 [ set tempxy y1 set y1 y2 set y2 tempxy ]
    paint-efx patches with [     pxcor >= x1 and pxcor <= x2 
                             and pycor >= y1 and pycor <= y2
                           ]
end

to circle-paint-solid [ cx cy ex ey ]
    locals [ mypatches myradius]
    
    set-brush-radius
    ask patch cx cy
    [ set myradius distancexy-no-wrap ex ey 
      set mypatches patches with
                    [ distance-nowrap myself <= myradius ]
    ]
    paint-efx mypatches
end ; circle-paint-solid

to-report efx-result
; effects: "1 solid" "2 dappled" "3 undapple" "4 darken" "5 lighten" "6 blend"
    locals [ efx ]
    set efx read-from-string item 0 effect
    ifelse efx = 1 [ report brush ]
  [ ifelse efx = 2 [ report dappled ]
  [ ifelse efx = 3 [ report center? pcolor ]
  [ ifelse efx = 4 [ report undapple? pcolor ]
  [ ifelse efx = 5 [ report darker? pcolor ]
  [ ifelse efx = 6 [ report lighter? pcolor ]
  [ ifelse efx = 7 [ report blend pcolor ]
                   [ stop ]
  ]]]]] ]
end ; efx-result
    
to paint-efx [ mypatches ]
; effects: "1 solid" "2 dappled" "3 undapple" "4 darken" "5 lighten" "6 blend"
    locals [ efx ]
    set efx read-from-string item 0 effect
    ifelse efx = 1 [ ask mypatches [ set pcolor brush ] ]
  [ ifelse efx = 2 [ ask mypatches [ set pcolor dappled ] ]
  [ ifelse efx = 3 [ ask mypatches [ set pcolor center? pcolor ] ]
  [ ifelse efx = 4 [ ask mypatches [ set pcolor undapple? pcolor ] ]
  [ ifelse efx = 5 [ ask mypatches [ set pcolor darker? pcolor ] ]
  [ ifelse efx = 6 [ ask mypatches [ set pcolor lighter? pcolor ] ]
  [ ifelse efx = 7 [ ask mypatches [ set pcolor blend pcolor ] ]
                   [ stop ]
  ]]]]] ]
end ; paint-efx

to stamp-efx      
; effects: "1 solid" "2 dappled" "3 undapple" "4 darken" "5 lighten" "6 blend"
  set pcolor efx-result
  set unpainted? false
end ; stamp-efx
      

to fill-solids [ old-color ]
    locals [ fillable my-pxcor my-pycor ]

    if pcolor = old-color and unpainted?
    [ stamp-efx
      set my-pxcor pxcor
      set my-pycor pycor
      set fillable neighbors4 with [     pcolor = old-color 
                                     and unpainted?
                                     and abs (pxcor - my-pxcor) < 2
                                     and abs (pycor - my-pycor) < 2
                                   ]
      if any fillable [ ask fillable [ fill-solids old-color ] ]
    ]    
end ; fill-solids

to fill-shades [ old-color ]
   locals [ new-color fillable my-pxcor my-pycor ]

   set new-color efx-result
   if shade-of? pcolor old-color
      and unpainted?
      and not shade-of? pcolor new-color
   [ set pcolor new-color
     set my-pxcor pxcor
     set my-pycor pycor
     set fillable neighbors4 with [     shade-of? old-color pcolor
                                    and unpainted?
                                    and distance-nowrap myself < 2
                                    ;and abs (pxcor - my-pxcor) < 2
                                    ;and abs (pycor - my-pycor) < 2 
                                  ]
     if any fillable [ ask fillable [ fill-shades old-color ] ]
   ]
end ; fill-shades

to display-sample
    every 2
    [ ask patches
      [ set sample-color pcolor
        if random 2 = 0
        [ set pcolor brush ]
      ]
      wait 1
      ask patches
      [ set pcolor sample-color ]
    ]
end
    
to display-blend
    locals [rr gg bb ]
    
    set rr get-r brush
    set gg get-g brush
    set bb get-b brush
    
    every 2
    [ ask patches
      [ set sample-color pcolor
        if random 2 = 0 
        [ set pcolor rgb ( .5 * ( get-r pcolor + rr ) ) 
                         ( .5 * ( get-g pcolor + gg ) ) 
                         ( .5 * ( get-b pcolor + bb ) ) 
        ]
      ]
      wait 1
      ask patches
      [ set pcolor sample-color ]
    ]
end

to-report blend [ hue2 ]
    locals [ rr1 gg1 bb1 rr2 gg2 bb2 ]

    set rr1 get-r brush  * strength
    set gg1 get-g brush  * strength
    set bb1 get-b brush  * strength
    
    set rr2 get-r hue2  * ( 1 - strength )
    set gg2 get-g hue2  * ( 1 - strength )
    set bb2 get-b hue2  * ( 1 - strength )

    report rgb ( ( rr1 + rr2 ) )
               ( ( gg1 + gg2 ) )
               ( ( bb1 + bb2 ) )
end

to-report blend? [ hue1 hue2 ]
    locals [ rr1 gg1 bb1 rr2 gg2 bb2 ]

    set rr1 ( get-r hue1 ) * strength
    set gg1 ( get-g hue1 ) * strength
    set bb1 ( get-b hue1 ) * strength
    
    set rr2 ( get-r hue2 ) * ( 1 - strength )
    set gg2 ( get-g hue2 ) * ( 1 - strength )
    set bb2 ( get-b hue2 ) * ( 1 - strength )

    report rgb ( ( rr1 + rr2 ) )
               ( ( gg1 + gg2 ) )
               ( ( bb1 + bb2 ) )
end

to-report get-r [ hue ]
   report item 0 (extract-rgb hue)
end

to-report  get-g [ hue ]
   report item 1 (extract-rgb hue)
end

to-report  get-b [ hue ]
   report item 2 (extract-rgb hue)
end

to-report inverse? [ hue ]
    report rgb (1 - get-r hue ) (1 - get-g hue) (1 - get-b hue)
end

to-report base-color
    ; reports base-color of brush
    ; e.g. if brush is red, base-color is red - 5.
    ; if brush is 86.875, base-color is 80.000
    report 10 * int ( brush * .1 )
end

to-report base-color? [ hue ] ; reports base-color of any hue
    report 10 * int ( hue * .1 )
end

to-report tint
    ; reports tint of brush
    ; e.g. if brush is red, tint is 5
    ; if brush is 86.8753, tint is 6.8753
    report precision ( brush - base-color ) 4
end

to-report tint? [ hue ] ; reports tint of any hue
    report precision (hue - base-color? hue) 4
end

to-report dappled ; dapples the brush; reports a random tint of the brush color
    report precision ( base-color +  5 - 5.0 * strength + (10.0 * random strength) ) 4
end

to-report dappled? [ hue ] ; dapples any color
    report precision ( base-color? hue +  5 - 5.0 * strength + (10.0 * random strength) ) 4
end


to-report darker
    locals [ new-tint ]
    set new-tint precision ( tint - .5 ) 1
    if new-tint < 0 
    [ set new-tint 0 ]
    report precision ( base-color + new-tint ) 4
end

to-report lighter
    locals [ new-tint ]
    set new-tint precision ( tint + .5 ) 1
    if new-tint > 9.9999 
    [ set new-tint 9.9999 ]
    report precision ( base-color + new-tint ) 4
end

to-report darker? [ hue ]
    locals [ new-tint ]
    set new-tint precision ( ( tint? hue ) - .5 ) 1 
    if new-tint < 0 
    [ set new-tint 0 ]
    report precision ( base-color? hue + new-tint ) 4
end

to-report lighter? [ hue ]
    locals [ new-tint ]
    set new-tint  precision ( ( tint? hue )  + .5 ) 1
    if new-tint > 9.9999 
    [ set new-tint 9.9999 ]
    report precision ( base-color? hue + new-tint ) 4
end

to-report undapple; removes shades from the brush color. i.e. color is set to multiple of 5
    report 5.0 + base-color
end

to-report undapple? [ hue ] ; removes shades from any color
    report 5.0 + base-color? hue 
end

to-report center ;; Centers the brush color
;; center is a smarter version of undapple
;; undapple always reports the true center, so black and white turn gray.
;; center will turn dark shades of gray black, and light shades white.
    locals [ my-tint my-base ]
    set my-base base-color
    ifelse my-base != 0
    [ report my-base + 5 ]
    [ set my-tint tint
        ifelse my-tint < 3.3333 [ report black ]
      [ ifelse my-tint < 6.6666 [ report gray  ]
                                [ report white ]
      ]
    ]
end


to-report center? [ hue ] ; centers any color
;; center is a smarter version of undapple
;; undapple always reports the true center, so black and white turn gray.
;; center will turn dark shades of gray black, and light shades white.
    locals [ my-tint my-base ]
    set my-base base-color? hue
    ifelse my-base != 0
    [ report my-base + 5 ]
    [ set my-tint tint? hue
        ifelse my-tint < 3.3333 [ report black ]
      [ ifelse my-tint < 6.6666 [ report gray  ]
                                [ report white ]
      ]
    ]
end

to-report un-center
    ifelse brush >= 10
    [ report dappled ]
    [ ifelse brush < 3.3333
      [ report random 3.3333 ]
      [ ifelse brush < 6.6666
        [ report 3.3333 + random 3.3333 ]
        [ report 6.6666 + random 3.3333 ]
      ]
    ]
end

to-report un-center? [ hue ]
    ifelse hue >= 10
    [ report dappled? hue ]
    [ ifelse hue < 3.3333
      [ report random 3.3333 ]
      [ ifelse hue < 6.6666
        [ report 3.3333 + random 3.3333 ]
        [ report 6.6666 + random 3.3333 ]
      ]
    ]
end


to-report black-out
    report base-color
end

to-report white-out
    report precision ( 9.9999 + base-color ) 4
end

to-report color-name [ hue ] ; returns a string naming the color
    locals [ name my-tint tint-name base ]
    set base 5 + base-color? hue
    set name ""
    set tint-name ""
    ifelse hue = black  [set name "black" ]
    [ ifelse hue = white    [ set name "white" ]
      [ if base = blue      [ set name "blue" ]
        if base = brown     [ set name "brown" ]
        if base = cyan      [ set name "cyan" ]
        if base = gray      [ set name "gray" ]
        if base = green     [ set name "green" ]
        if base = lime      [ set name "lime" ]
        if base = magenta   [ set name "magenta" ]
        if base = orange    [ set name "orange" ]
        if base = pink      [ set name "pink" ]
        if base = red       [ set name "red" ]
        if base = sky       [ set name "sky" ]
        if base = turquoise [ set name "turquoise" ]
        if base = violet    [ set name "violet" ]
        if base = yellow    [ set name "yellow" ]
        if name = ""        [ set name "unknown" ]
        set my-tint tint? hue
          ifelse my-tint = 0.0000   [ set tint-name "darkest "  ]
        [ ifelse my-tint = 9.9999  [ set tint-name "lightest " ]
        [ ifelse my-tint <= 2.5    [ set tint-name "darker "   ]
        [ ifelse my-tint >= 7.5    [ set tint-name "lighter "  ]
        [ ifelse my-tint < 5       [ set tint-name "dark "     ]
        [ ifelse my-tint > 5       [ set tint-name "light "    ]
                                   [ set tint-name "pure "     ]
        ]]]]]
      ]
    ]
    report (tint-name + name)
end

to-report monitor-color
    locals [ point-color result]
    ifelse tool = "pick-color" and is-turtle? pointer and pointer != nobody
    [ set point-color color-of pointer
      ifelse point-color = brush
      [ set result "brush is " ]
      [ set result "set brush to " ]
      set result result + point-color + ", " + color-name point-color 
    ] 
    [ ifelse tool = "change-color" and is-turtle? pointer and pointer != nobody
      [ set point-color color-of pointer
        ifelse point-color = brush
        [ set result "color is " ]
        [ set result "change " + point-color + ", " + color-name point-color + " to "  ]
        set result result + brush + ", " + color-name brush
      ]
      [ set result tool + ": " + brush + ", " + color-name brush + "(" + effect + ")" ]
    ]
    report result
end

to test-agentsets
    locals [ set1 set2 set3 ]
    ca
    
    set set1 patches with [ abs pxcor < 5 ]
    set set2 patches with [ abs pxcor > 10 ]
    set set3 union set1 set2
    
    ask set3 [ set pcolor white ]
end

to-report intersect [ set1 set2 ]
    if    (is-patch-agentset? set1 and is-patch-agentset? set2 ) 
       or (is-turtle-agentset? set1 and is-turtle-agentset? set2 ) 
    [ report (set1 with [ any set2 with [ self = myself ] ] ) ]
end
    
to-report union [ set1 set2 ]
    locals [ error! ]

    ifelse (is-patch-agentset? set1 and is-patch-agentset? set2 ) 
    [ report patches with [ any set1 with [ self = myself ] or any set2 with [ self = myself ] ]]
    [ ifelse (is-turtle-agentset? set1 and is-turtle-agentset? set2 )
      [ report turtles with [ any set1 with [ self = myself ] or any set2 with [ self = myself ] ] ]
      [ ifelse (is-agentset? set1 and is-agentset? set2)
        [ print "Error: Agentsets must be of the same agent type" ]
        [ ifelse is-agentset? set1
          [ print "Error: Set2 is not an agentset" ]
          [ ifelse is-agentset? set2
            [ print "Error: Set1 is not an agentset" ]
            [ print "Error: Neither Set1 nor Set2 is an agentset" ]
          ]
        ]
        set error! 0
        set error! error! with [ true ] ; will throw a runtime error
        report error!
      ]
    ]
end
    
    
to starburst
    locals [ start
             top-edge left-edge bottom-edge right-edge
             top-to-bottom left-to-right
             edge index inc
           ]
    if cycles = 0 [ stop ]
    record-history 
    set top-edge screen-edge-y
    set bottom-edge 0 - top-edge
    set right-edge screen-edge-x
    set left-edge 0 - right-edge
    set top-to-bottom screen-size-y
    set left-to-right screen-size-x

    set edge top-edge ; moving along the...
    set index left-edge ; starting from the...
    set inc int ( index / left-edge ) * cycles
    repeat left-to-right / cycles ; general direction (RL same LR)
    [ line-paint 0 0 index edge
      set index index + inc
    ]

    set edge right-edge
    set index top-edge
    set inc int ( index / bottom-edge ) * cycles
    repeat top-to-bottom / cycles
    [ line-paint 0 0 edge index
      set index index + inc
    ]

    set edge bottom-edge
    set index right-edge
    set inc int ( index / left-edge ) * cycles
    repeat left-to-right / cycles
    [ line-paint 0 0 index edge
      set index index + inc
    ]

    set edge left-edge
    set index bottom-edge
    set inc int ( index / bottom-edge ) * cycles
    repeat top-to-bottom / cycles
    [ line-paint 0 0 edge index
      set index index + inc
    ]
end

to shade-edges
    record-history
    ask patches
    [ shade-edge ]
end

to shade-edge
    locals [ color-mates my-color mates-count max-mates]
    set my-color base-color? pcolor
    set color-mates patches in-radius cycles
    set max-mates count color-mates
    set color-mates color-mates with [ base-color? pcolor = my-color ]
    set mates-count count color-mates
    ifelse mates-count < max-mates
    [ set pcolor my-color + 5 * (mates-count / max-mates )]
    [ set pcolor my-color + 5 ]
end

to shift-all [ sdx sdy amount ]
    record-history
    set sdx sdx * amount
    set sdy sdy * amount 
    ask patches
    [ set sample-color pcolor-of patch-at sdx sdy ]
    ask patches
    [ set pcolor sample-color ]
end

to flip-xx
    record-history
    ask patches
    [ set sample-color pcolor-of patch ( 0 - pxcor ) ( pycor ) ]
    ask patches
    [ set pcolor sample-color ]
end

to flip-yy
    record-history
    ask patches
    [ set sample-color pcolor-of patch ( pxcor ) ( 0 - pycor ) ]
    ask patches
    [ set pcolor sample-color ]
end

to rotate-90
      record-history
      ask patches
      [ set sample-color canvas ]
      ask patches with [ abs pxcor <= screen-edge-y and abs pycor <= screen-edge-x ]
      [ set sample-color pcolor-of patch (0 - pycor) (pxcor) ]
      ask patches
      [ set pcolor sample-color ]
    ; ]  
end

to trim-history
    ; removes undo information above the current undo point.
    repeat undo-point + 1
    [ set history but-first history ]
end    

to record-history
    if undo-on? 
    [ ; if any redos after this point, delete them
      if undo-point > 0
      [ ask patches with [ true ]
        [ trim-history ]
        set undo-length length history-of patch 0 0
        set undo-point 0
      ]
      ; record this point in the history
      ask patches with [ true ]
      [ set history fput pcolor history ]
      set undo-length undo-length + 1
      ; if history has exceeded depth, trim oldest item.
      while [ undo-length > undo-levels ]
      [ ask patches with [ true ]
        [ set history but-last history ]
        set undo-length undo-length - 1
      ]
    ]
end ; record-history

to undo
    if undo-on?
    [ ; undo is on, so.. is there any history?
      if undo-length > 0
      [ ; there is at least one history item
        if undo-point = 0
        ; if we are at head of undo, the record the current screen, to enable redo
        [ record-history ]
        ; move back in the history
        if undo-point < undo-length - 1
        [ ; apply colors from history
          set undo-point undo-point + 1
          ask patches
          [ set pcolor item undo-point history ]
        ]
      ] ; if undo-length?...
    ] ; if undo-on?...
end ; undo

to redo
    if undo-on?
    [ ; undo is on, so.. are we in the the history?
      if undo-point > 0
      [ ; we are in the history, so lets move up to the previous entry
        set undo-point undo-point - 1
        ; apply colors from history
        ask patches 
        [ set pcolor item undo-point history ]
        if undo-point = 0
        ; if we are back at the head of the list, 
        ; lets get rid of the copy we made earlier.
        [ ask patches 
          [ set history but-first history ]
          set undo-length undo-length - 1
        ]
      ]
    ] ; if undo-on?...
end ; redo

to reset-undo-history
    ask patches
    [ set history [] ]
    set undo-point 0
    set undo-length 0
end

to-report get-file-name [ mode ]
    locals [ file-name input-name prompt ]
    ; prompt for filename
    ; is the current-file variable not a string? Does it not have a value?
    if (not is-string? current-file ) or current-file = ""
    [ ; no. make it an empty string.
      set current-file ""
    ]
    ; initialize file-name to the current-file (which may be empty)
    set file-name current-file
    
    ; test the mode parameter. is it a string?
    ifelse not is-string? mode
    [ ; no. make it an empty string
      set mode ""
    ]
    [ ; yes. enhance mode variable for display in prompt
      set mode " to " + mode + "."
    ]
    set prompt "Type filename" + mode 
    ; if there is a default filename, add it to the prompt
    if file-name != ""
    [ set prompt prompt + " Default: [ " + file-name + " ]" ]
    
    ; prompt for the name
    set input-name user-input prompt 
    ; the below (in place of the above line) did not work:
    ; set input-name read-from-string user-input prompt
     ; it throws this error:
     ; error while observer executing READ-FROM-STRING
     ; in procedure GET-FILE-NAME
     ; called by procedure LOAD-PATCHES
     ; Expected a constant.
     ; (halted execution of load)
    if input-name != ""
    [ ; if anything entered, set the filename
      set file-name input-name
    ] ; if blank, the file-name is left as the current-file name (which may be blank)
      
    report file-name
end
    
to save-patches
    locals [ file-name ]
    set file-name get-file-name "save"
    if file-name = "" [ stop ]
    ; open file
    __openwrite file-name
    ; write file header
    print "PCF-001"
    ; write size information
    print screen-edge-x
    print screen-edge-y
    ; write patch color
    ask patches
    [ without-interruption
      [ print pxcor
        print pycor
        print pcolor
      ]
    ]
    ; store file-name
    set current-file file-name
    ; close file
    __close
end

to load-patches [ file-name ]
; depends on helper procedure "get-file-name"
; to use without "get-file-name"
; comment out the code between ";; PROMPT FOR FILE NAME"
; Also uses RECORD-HISTORY

    locals [ my-size-x my-size-y match? in-x in-y in-c version]

    ;; PROMPT FOR FILE NAME
        if file-name = ""
        [ set file-name get-file-name "load" ]
    ;; END-PROMPT FOR FILE NAME
    if file-name = "" [ user-message " stopping" stop ]
    
    ; open file
    __openread file-name
    ; read version information
    set version __readline
    if version != "PCF-001"
    [ user-message "File type '" + version + "' is not supported."
      stop
    ]
    
    ; read size-information
    set my-size-x  read-from-string __readline
    set my-size-y  read-from-string __readline
    set match? ( my-size-x <= screen-edge-x or my-size-y <= screen-edge-y)
    if not match?
    [ user-message "Warning!\n\nPatch data is for larger screen!\n\n" + 
                   "screen-edge-x: " + my-size-x + "\n" +
                   "screen-edge-y: " + my-size-y + "\n\n" + 
                   "Image will be truncated. Click OK to continue."
    ]
    record-history
    while [ not __endoffile ]
    [ set in-x read-from-string __readline
      set in-y read-from-string __readline
      set in-c read-from-string __readline
      if match? or ( (abs in-x ) <= screen-edge-x and (abs in-y ) <= screen-edge-y )
      [ set pcolor-of patch in-x in-y in-c ]
    ]
    ; set current-file-name
    set current-file file-name
    ; close file
    __close
end

@#$#@#$#@
GRAPHICS-WINDOW
466
10
884
449
25
25
8.0
1
10
0
1

CC-WINDOW
467
452
882
544
Command Center

BUTTON
182
287
237
320
NIL
clear
NIL
1
T
OBSERVER

BUTTON
10
10
122
43
drawing tool ON
draw
T
1
T
OBSERVER

SLIDER
10
178
236
211
brush
brush
0
139.9999
45.0
1.0E-4
1
NIL

BUTTON
238
131
293
164
red
select-color red
NIL
1
T
OBSERVER

BUTTON
238
166
293
199
orange
select-color orange
NIL
1
T
OBSERVER

BUTTON
238
201
293
234
yellow
select-color yellow
NIL
1
T
OBSERVER

SLIDER
11
287
123
320
canvas
canvas
0
139.9999
95.0
1.0E-4
1
NIL

BUTTON
295
131
350
164
green
select-color green
NIL
1
T
OBSERVER

BUTTON
352
201
407
234
turquoise
select-color turquoise
NIL
1
T
OBSERVER

BUTTON
295
201
350
234
cyan
select-color cyan
NIL
1
T
OBSERVER

BUTTON
352
131
407
164
blue
select-color blue
NIL
1
T
OBSERVER

BUTTON
352
166
407
199
sky
select-color sky
NIL
1
T
OBSERVER

BUTTON
409
131
464
164
violet
select-color violet
NIL
1
T
OBSERVER

BUTTON
409
166
464
199
mgnta
select-color magenta
NIL
1
T
OBSERVER

BUTTON
238
236
293
269
_0.0000
select-color black-out
NIL
1
T
OBSERVER

BUTTON
409
236
464
269
_9.9999
select-color white-out
NIL
1
T
OBSERVER

BUTTON
11
325
123
358
sample-solid
display-sample
T
1
T
OBSERVER

BUTTON
125
287
180
320
=brush
set canvas brush
NIL
1
T
OBSERVER

BUTTON
125
325
237
358
sample-blend
display-blend
T
1
T
OBSERVER

BUTTON
238
96
293
129
black
select-color black
NIL
1
T
OBSERVER

BUTTON
295
96
350
129
gray
select-color gray
NIL
1
T
OBSERVER

BUTTON
352
96
407
129
white
select-color white
NIL
1
T
OBSERVER

BUTTON
409
96
464
129
brown
select-color brown
NIL
1
T
OBSERVER

BUTTON
295
166
350
199
lime
select-color lime
NIL
1
T
OBSERVER

BUTTON
238
271
293
304
darker
select-color darker
NIL
1
T
OBSERVER

BUTTON
409
271
464
304
lighter
select-color lighter
NIL
1
T
OBSERVER

BUTTON
295
236
407
269
pure
select-color center
NIL
1
T
OBSERVER

BUTTON
409
201
464
234
pink
select-color pink
NIL
1
T
OBSERVER

SLIDER
10
143
236
176
brush-width
brush-width
1
25
3
2
1
NIL

CHOICE
10
96
122
141
tool
tool
"brush" "lines" "frames" "boxes" "rings" "circles" "fills" "fill-shades" "change-color" "pick-color"
0

BUTTON
125
360
237
393
posterize
record-history\nask patches\n[ set pcolor center? pcolor ]
NIL
1
T
OBSERVER

BUTTON
11
360
123
393
dapple-all
record-history\nask patches\n[ set pcolor dappled? pcolor ]
NIL
1
T
OBSERVER

BUTTON
11
395
123
428
diffuse
record-history\nrepeat cycles\n[ diffuse pcolor strength ]\nask patches\n[ set pcolor precision pcolor 4 ]
NIL
1
T
OBSERVER

SLIDER
10
213
236
246
strength
strength
0
1
0.5
0.01
1
NIL

SLIDER
10
248
236
281
cycles
cycles
0
100
5
1
1
NIL

MONITOR
10
45
464
94
color
monitor-color
0
1

CHOICE
124
96
236
141
effect
effect
"1 solid" "2 dappled" "3 center" "4 undapple" "5 darken" "6 lighten" "7 blend"
0

BUTTON
11
430
123
463
starburst
starburst
NIL
1
T
OBSERVER

BUTTON
124
10
179
43
reset
setup
NIL
1
T
OBSERVER

BUTTON
181
10
293
43
clear-cursors
no-display\nclear-turtles\ndisplay
NIL
1
T
OBSERVER

BUTTON
125
395
237
428
NIL
shade-edges
NIL
1
T
OBSERVER

BUTTON
295
10
350
43
save
save-patches
NIL
1
T
OBSERVER

BUTTON
352
10
407
43
load
load-patches ""
NIL
1
T
OBSERVER

BUTTON
409
10
464
43
load!
if is-string? current-file\n[ load-patches current-file ]
NIL
1
T
OBSERVER

BUTTON
382
312
437
345
//
shift-all -1 -1 shift
NIL
1
T
OBSERVER

BUTTON
400
347
455
380
>>
shift-all -1 0 shift
NIL
1
T
OBSERVER

BUTTON
325
382
380
415
\\//
shift-all 0 1 shift
NIL
1
T
OBSERVER

BUTTON
249
347
304
380
<<
shift-all 1 0 shift
NIL
1
T
OBSERVER

BUTTON
325
312
380
345
//\\
shift-all 0 -1 shift
NIL
1
T
OBSERVER

BUTTON
268
382
323
415
//
shift-all 1 1 shift
NIL
1
T
OBSERVER

BUTTON
382
382
437
415
\\
shift-all -1 1 shift
NIL
1
T
OBSERVER

BUTTON
268
312
323
345
\\
shift-all 1 -1 shift
NIL
1
T
OBSERVER

SLIDER
306
347
398
380
shift
shift
1
41
1
1
1
NIL

BUTTON
268
423
323
456
rotate
rotate-90
NIL
1
T
OBSERVER

BUTTON
325
423
380
456
flip <-->
flip-xx
NIL
1
T
OBSERVER

BUTTON
382
423
437
456
flip /\ \/
flip-yy
NIL
1
T
OBSERVER

SWITCH
269
496
381
529
undo-on?
undo-on?
0
1
-1000

SLIDER
269
461
381
494
undo-levels
undo-levels
1
100
100
1
1
NIL

BUTTON
212
461
267
494
NIL
undo
NIL
1
T
OBSERVER

BUTTON
212
496
267
529
NIL
redo
NIL
1
T
OBSERVER

BUTTON
383
496
453
529
clear undo
reset-undo-history
NIL
1
T
OBSERVER

@#$#@#$#@
WHAT IS IT?
-----------
A drawing tool for NetLogo, implemented in NetLogo.
It can be used to design initial patch color arrangements.
It includes the usual tools--brush, line, circle-- and a multi-level undo / redo feature.
Basic save and load features allow color setups to be saved for use in other models.

HOW IT WORKS
------------
Click drawing-tool ON to begin. If needed, the model automatically "resets".
Choose a tool and effect from the pick-lists.
Choose a brush width and brush-color.
Click in the patch area to draw.

BRUSH-WIDTH
---------------
Use to set the brush-width used by the tools.
Is always odd, as it uses integer patches

BRUSH
-----
Sets the color of the brush, in increments of .0001




STRENGTH - CYCLES
-----------------
strength:	controls the "strength" of various effects.
                blend: stronger means less transparent
                dapple: stronger means a wider range of shades
                diffuse: stonger diffuses more
                use for any control or effect that requires a value varying from 0.0 to 1.0
cycle:          diffuse: repeats the diffuse function that many times
                startburst: sets the gap between the lines

THE COLOR PALETTE
-----------------
Brush:   Sets the brush color anywhere from 0.000 to 139.999
Buttons: Sets the brush to the named color.
Lighter,
Darker:  Affect the brush color (by even 0.5 increments)
Pure:    Sets the brush color to the "pure" color, aka the center color.
         Example: If brush is 19.455 (light red),
                 changes it to 15.000 (red)
         Note: Pure uses the Center function, so darker grays become black,
         and brighter grays become white.

_0.0000: Sets the brush to the darkest shade of the current color.
         Example: If brush is 117.500 (lighter violet),
                  changes color to 110.000 (darkest violet).
_9.9999: Sets the brush to the lightest shade of the current color

THE TOOLS
---------
Tools alter the canvas in different ways, using the current brush color and / or effect. (Except for pick-color, which just changes the brush color)
To cancel a line, frame, box, circle or ring in progress, click RESET.

brush:        click and drag to paint
lines:        click to set the start point, click again to complete the line.
frames:       click to draw a rectangle outline, as thick as the brush-width
boxes:        click to draw a filled rectangle
fill:         click to fill the selected solid-color region
fill-shades:  like fill, but ignores shades of color.
              doesn't work for all effects.
circles:      draws a filled circle. click to specify center,
              again to specify radius
rings:        like circles, but draws a circular ring.
pick-color:   click on the canvas to change the brush color to the
              color of the selected patch
change-color: click on the canvas to change every patch with that color to the brush color


THE EFFECTS
------------
solid:    draws in the selected color
dappled:  draws in random shades of the selected color
center:   changes the current patch color to the pure shade of that color,
          except for grays, where darker gray becomes black and lighter gray becomes white
undapple: changes the current patch color to the pure shade of that color
darken:   changes the current patch color to be slightly darker
lighten:  changes the current patch color to be slightly lighter
blend:    draws in the slected color, blended with the current patch color.
          set the opacity with the strength slider.


SAVING AND LOADING
------------------
Save : Save the patch colors (prompt for name)
Load : Load the patch colors (prompt for name)
Load!: Load the same file loaded last time (no prompt)

Enter the file-name (or path and file-name) when prompted.
If you want to use a file-extension, be sure to include it.

If the loaded image is larger than the current screen, you will be warned, the image will load, and the edges will be cut off.

If the loaded image is smaller, it will load into the center. The outer edges will not be cleared or otherwise changed.


ADDITIONAL TOOLS / EFFECTS / CONTROLS
-------------------------------------
reset:         resets the drawing cursor and any marker turtles.
               use to cancel a line, frame, box, circle, or ring in progress.

clear-cursors: clears the drawing cursor from the canvas,
               so the canvas is clean for screen-shots and the like.
strength:     specifies the diffusion strength, or the blend opacity
              (stronger is more opaque)

SHIFTERS
~~~~~~~~
shifters:      shifts the patch colors in the indicated direction, by the amount of the shift slider
flip <-->:     Flips the world along the center vertical axis
flip /\\/:     Flips the world along the center horizontal axis
rotate:        rotates the patches 90 degrees.
               Caution: if the world is not square, color data in patches outside the center will be lost

UNDO
~~~~
undo-on?:     enables or disables the undo feature
undo:         removes the last change. For the brush tool, each stroke can be un-done individually
redo:         reapplies the changes removed by undo.
clear-undo:   deletes the undo-history
undo-levels:  sets the maximum number of changes that can be recorded. Additional changes will cause the older 

SPECIAL EFFECT BUTTONS
~~~~~~~~~~~~~~~~~~~~~~

sample-solid: flashes the brush color on the canvas
sample-blend: flashes the brush color blended with the canvas
canvas:       sets the canvas color
<=brush:      sets the canvas color from the brush color
dapple-all:   sets all patches to a random shade of their current color
              breadth of shades determined by strength
              0.0 = use pure color
              0.5 = use mostly middle shades
              1.0 = use all shades
posterize:    sets all patches to their pure color.
shade-edges:  sets color brightness based on number
              of neighbors with same base-color
diffuse:      performs diffusion at the specified strength
              for the specified number of cycles

starburst:    draws a sweep of lines around the center, in the current brush color and width,
              cycles sets the spacing of the lines. Used with blend, darken, or lighten, 
              produces some attractive effects.



SPECIAL PROGRAMMING NOTES
-------------------------
To interactively show the user the line, circle or box that will be drawn, "marker" turtles are created and destroyed. The number of marker turtles varies, depending on the screen-size.

To reduce the number of global variables, the model makes use of turtle variables and turtle inheritance.

The flood fill functions use recursion to fill the patches.

The model makes use of a turtle's ability to directly access the variables of the patch the turtle is on: The pointer turtle performs most of the tasks, so it can directly refer to the patch color, etc.

The model uses several custom-designed turtle-shapes as the various drawing cursors.

Where there are two reporters with nearly the same name, like "blend" and "blend?" the unadorned reporter refers to the brush color, whereas the "?" reporter always requires a color argument. For example: "dappled" reports a random shade of the brush color, but "dappled? red" reports a random shade of red.

Many of the effects depend on the base-color and tint reporters.
Base-color gives the black version of the color (i.e. the even multiple of 10 for the color)
E.g. the base-color of red (15) is 10.
Tint could also be called "shade": it gives the amount above the base-color. The tint of a pure color is alway 5. The tint of black is 0, the tint of white is 9.9999.

Black, white and gray are strange cases. They all share a base color (0) and therefore, the pure color (base + 5) of all three is 5. So, undapple will always turn black and white to gray. However, Center is a smarter undapple: It examines the shade of gray and turns darker gray to black and lighter gray to white.

Setting the size and shape every cycle caused the turtles to flicker. To avoid flicker of the cursors, the size and shape is tested first, and only set if it doesn't match. Likewise, the x and y coordinates are set only if the mouse moves to a different patch.
@#$#@#$#@
default
true
0
Polygon -7566196 true true 150 5 40 250 150 205 260 250

bx
true
0
Polygon -7566196 true true 45 45 45 255 255 255 255 45

bxo
false
10
Rectangle -16776961 false true 15 15 285 285

ch
true
10
Line -16776961 true 150 0 150 300
Line -16776961 true 0 150 300 150

chbx
false
10
Rectangle -16776961 false true 15 15 285 285
Line -16776961 true 15 15 285 285
Line -16776961 true 285 15 15 285

chc
false
10
Line -16776961 true 150 0 150 300
Line -16776961 true 0 150 300 150
Circle -16776961 false true 15 15 270

cp
false
10
Rectangle -16777216 false false 0 0 85 85
Rectangle -1 false false 215 0 300 85
Rectangle -1 false false 0 215 85 300
Rectangle -16777216 false false 215 215 300 300
Rectangle -16776961 true true 15 15 75 75
Rectangle -16776961 true true 15 225 75 285
Rectangle -16776961 true true 225 15 285 75
Rectangle -16776961 true true 225 225 285 285
Line -16776961 true 150 0 150 300
Line -16776961 true 0 150 300 150

oc
false
10
Circle -16776961 false true 15 15 270

ray
true
10
Line -16776961 true 150 150 150 0

tip
false
10
Line -16776961 true 15 150 285 150
Line -16776961 true 150 15 150 285
Rectangle -16776961 true true 115 115 175 175

tip0
false
0
Rectangle -7566196 true true 100 100 200 200
Rectangle -1 false false 15 15 285 285
Rectangle -16777216 false false 30 30 270 270

@#$#@#$#@
NetLogo 1.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
