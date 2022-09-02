globals [
  done-selecting?
  selected-unit
  decision-number
  alien-moving?
  player1
  alien1
  alien2
  alien3
  alien4
  alien5

  alien1-status
  alien2-status
  alien3-status
  alien4-status
  alien5-status
]

breed [planets planet]
breed [outposts outpost]
breed [miners miner]
breed [fighters fighter]
breed [aliens alien]
breed [players player]
breed [traders trader]
breed [workers worker]
breed [scouts scout]
breed [strikers striker]
breed [seekers seeker]
breed [blackholes blackhole]
breed [moabs moab]

directed-link-breed [courses course]
directed-link-breed [attack-vectors attack-vector]
undirected-link-breed [relationships relationship]

patches-own [
  patch-owner
  explored?
]

relationships-own [
  sentiment ; 0 = hatred, 50 = neutral, 100 = strong alliance
  on-notice?
  at-war?
  alliance?
]

planets-own [
  owner ;who owns the planet
  spice-per-turn ;spice product per tick, based on the size of the planet
  ready-timer ; countdown timer for building stuff
  frontier ; a value determined by the distance from this planet to it's closest neighbor.  The more "frontier-like" a planet is, the more craziness can happen to it
  home? ; home planet?  Each player/alien has 1 home planet
  selected?
  defenses ; number indicating how many defenses a planet has before it's converted to an attacking player
  target ; a planet that is being targeted for attack (0 for no target)
  under-attack? ; is this planet being attacked?
  attack-timer ; a timer that gets reset each time the planet is attacked.  Once the timer reaches 0, the planet stops building fighters and goes back to normal production
  has-outpost?
  auto-defense? ; if on, this planet continuously builds fighters.  This is for player planets since alien planets do this already
  auto-explore? ; if on, this planet continuously builds explorers.
]

outposts-own [
  outpost-home-planet
  selected?
  upgrade-level ; the level that the outpost is currently upgraded to
  ready-timer ; a countdown timer to build the unit
  owner ; the player/alien who owns it
  target ; another outpost to launch seeker missiles at
  health ; when this reaches 0, the outpost has been destroyed
  ammo ; current ammo available
  max-ammo ;
  accuracy ; the percent chance to hit an enemy unit
]

blackholes-own [
  owner
  horizon
]

aliens-own [
  spice
  will
  max-will
  explore-goal
  improve-goal
  trade-goal
  attack-goal ; these goals are used to calculate alien turns
  defend-goal
  owner
  selected?
  score
]

players-own [
  spice
  will
  max-will
  owner
  selected?
  score
]

miners-own [
  miner-home-planet
  ready-timer ; a countdown timer to build the mining expedition
  owner ; the player/alien who owns the miner
  destination
  selected?
]

fighters-own [
  fighter-home-planet
  ready-timer ; a countdown timer to build the figher squadron
  owner ; the player/alien who owns the fighter
  destination
  selected?
  protected-planet ; the planet the fighter is currently protecting
  health ; when this reaches 0, the fighter squadron has been destroyed
]

traders-own [
  trader-home-planet
  ready-timer
  owner
  destination
  distance-traveled
  selected?
]

workers-own [
  worker-home-planet
  ready-timer
  owner
  selected?
]

scouts-own [
  scout-home-planet
  fuel ; lifespan
  ready-timer
  owner
  selected?
]

strikers-own [
  striker-home-planet
  ready-timer
  owner
  target-planet
  selected?
]

seekers-own [
  seeker-home-outpost
  ready-timer
  owner
  target-outpost
  selected?
]

moabs-own [
  moab-home-outpost
  ready-timer
  owner
  target-outpost
  selected?
]


to setup
  clear-all
  reset-ticks
  set selected-unit ""
  set-default-shape attack-vectors "vector"


  ;create the galaxy
  ask patches [
    set explored? false
  ]

  create-planets random 10 + (8 * alien-count) [
    set shape "dot"
    set color grey
    set owner "none"
    set selected? false
    set hidden? true
    set has-outpost? false
    set spice-per-turn random 3 + 1
    set size spice-per-turn
    set defenses (spice-per-turn * 20)
    set target 0
    set under-attack? false
    set auto-defense? false
    set auto-explore? false
    set attack-timer 0
    set ready-timer 0
    setxy round random-xcor round random-ycor
  ]

  ask planets [
    if any? other planets-here [die]
  ]

  ;create player
  create-players 1 [
    set shape "person"
    set spice 50
    set will 1
    set max-will 1
    set score 0
    set selected? false
    set hidden? true
    set color blue
    set hidden? true
  ]

  ;assign first planet
  ask players [
    ask one-of planets with [owner = "none"] [
      set owner myself
      set color [color] of myself
      set spice-per-turn 4
      set size spice-per-turn
      set label (word "You [" size "]")
      set label-color black
      set home? true
      set hidden? false
      set frontier 0
    ]
  ]

  ask planets with [is-player? owner] [
    ask patches in-radius 3 [
      set patch-owner [owner] of myself
      set pcolor lime
    ]
  ]


  ;create aliens
  create-aliens alien-count [
    set shape "person"
    set spice 50
    set will 1
    set max-will 1
    set score 0
    set hidden? true
    set selected? false
    set explore-goal 10
    set trade-goal 1
    set attack-goal 1
    set defend-goal 1
  ]




  ;assign a home planet to each alien
  ask aliens [
    ask one-of planets with [owner = "none" and not any? other planets with [is-turtle? owner] in-radius 10] [
      set owner myself
      set color [color] of myself
      set spice-per-turn 4
      set size spice-per-turn
      set label-color black
      set home? true
      set frontier 0

      ask patches in-radius 3 [
        set patch-owner [owner] of myself
        set pcolor [color + 4] of patch-owner
      ]
    ]
  ]

  ask patches [
    if is-player? patch-owner [set explored? true]
    if any? planets-here with [is-player? owner] [set explored? true]
  ]

  setup-relationships
  assign-players
  update-map

end

to assign-players
  set player1 one-of players
  set alien1 min-one-of aliens [who]
  set alien2 one-of aliens with [who = [who + 1] of alien1]
  set alien3 one-of aliens with [who = [who + 2] of alien1]
  set alien4 one-of aliens with [who = [who + 3] of alien1]
  set alien5 one-of aliens with [who = [who + 4] of alien1]

  if alien1 != nobody [ask alien1 [set color 15]]
  if alien2 != nobody [ask alien2 [set color 25]]
  if alien3 != nobody [ask alien3 [set color 45]]
  if alien4 != nobody [ask alien4 [set color 85]]
  if alien5 != nobody [ask alien5 [set color 125]]

end



to setup-relationships

  ask aliens [
    create-relationship-with one-of players [set sentiment 50]
    create-relationships-with other aliens [set sentiment 50]
    ask relationships [
      set on-notice? false
      set at-war? false
      set alliance? false
    ]
  ]

end



to go
  tick

  update-political-wills
  mine-spice

  ;chance of a blackhole showing up
  if random 1000 = 1 [build-blackhole]
  move-blackholes

  ;player turn
  ask players [
    take-turn self
    setup-mining self
  ]


  ;aliens turns
  if aliens-on? [
    ask aliens [
      alien-decision self
      take-turn self
      setup-mining self
    ]
  ]

  if ticks > 1000 [build-new-planets]

  update-map
  calculate-scores
  check-for-game-over
  check-relationships
end

to select-planet
  set done-selecting? false

  ;select planet
  if mouse-down? and selected-unit = "" [
    ask patch mouse-xcor mouse-ycor [
      if any? planets-here with [is-player? owner] [
        set selected-unit one-of planets-here
        set done-selecting? true

        ask selected-unit [
          set color yellow
          set selected? true
          set size spice-per-turn
          if is-planet? target [ask target [set color red]]
        ]
      ]
    ]
  ]

  ;select outpost
  if mouse-down? and selected-unit = "" [
    ask patch mouse-xcor mouse-ycor [
      if any? outposts-here with [is-player? owner] [
        set selected-unit one-of outposts-here
        set done-selecting? true

        ask selected-unit [
          set color yellow
          set selected? true
          set size 3
        ]
      ]
    ]
  ]


  ;unselect units
  if mouse-down? [
    ask patch mouse-xcor mouse-ycor [
      if not any? planets-here and not any? outposts-here [
        ask planets with [is-player? owner] [
          set color blue
          set size spice-per-turn
          set selected? false
          if is-planet? target [ask target [set color [color] of owner]]
        ]
        ask outposts with [is-player? owner] [
          set color blue
          set size 1
          set selected? false
        ]
        set done-selecting? true
        set selected-unit ""
      ]
    ]
  ]

  ;target alien planet
  if mouse-down? [
  ask patch mouse-xcor mouse-ycor [
      if any? planets-here with [is-alien? owner] [
        if is-planet? selected-unit [
          ask selected-unit [
            if is-planet? target [ask target [set color [color] of owner]]
            set target one-of planets-on patch mouse-xcor mouse-ycor
            ask my-links [die]
            create-attack-vector-to target
            if Show-AI? [print (word "Target set to " target)]
            ask target [
              set color red
            ]
          ]
          set done-selecting? true
        ]
      ]
    ]
  ]

  ;target enemy outpost with seekers
  if mouse-down? [
  ask patch mouse-xcor mouse-ycor [
      if any? outposts-here with [is-alien? owner] [
        if is-outpost? selected-unit [
          ask selected-unit [
            if is-outpost? target [ask target [set color [color] of owner]]
            set target one-of outposts-on patch mouse-xcor mouse-ycor
            ask my-links [die]
            create-attack-vector-to target
            if Show-AI? [print (word "Target set to " target)]
            ask target [
              set color red
            ]
          ]
          set done-selecting? true
        ]
      ]
    ]
  ]




end


to clear-target
  if is-planet? selected-unit [
    ask selected-unit [
      ask my-links [die]
      if is-planet? target [
        ask target [
          set color [color] of owner
        ]
      ]
      set target 0
    ]
  ]

  if is-outpost? selected-unit [
    ask selected-unit [
      ask my-links [die]
      if is-outpost? target [
        ask target [
          set color [color] of owner
        ]
      ]
      set target 0
    ]
  ]
end

to update-political-wills
  ask players [
    set will will + 1
    if will > max-will [set will max-will]
  ]

  ask aliens [
    set will will + 1
    if will > max-will [set will max-will]
  ]
end


to mine-spice
  ask players [
    set spice spice + (sum [spice-per-turn] of planets with [owner = myself])
    set spice spice + round (count patches with [patch-owner = myself] / 10)
  ]

  ask aliens [
    set spice spice + (sum [spice-per-turn] of planets with [owner = myself])
    set spice spice + round (count patches with [patch-owner = myself] / 10)
  ]

end

to build-blackhole

  create-blackholes 1 [
    setxy round random-xcor round random-ycor
    set owner "universe"
    set size 1
    set horizon random 8 + 1
    set shape "circle 2"
    set color 44
    ask patches in-radius horizon [
      set patch-owner 0
      set pcolor 49]
  ]


end



to build-fighter [builder home-planet]

  ;check to make sure player can build a new miner
  ask builder [
    if spice < 250 [user-message (word builder ": you need 250 spice to build a fighter.")]
    if will < 1 [user-message (word builder ": you do not have the political will to build a fighter.")]
  ]

  ask builder [
    if spice >= 250 and will >= 1 and ([selected?] of home-planet = [true] or [auto-defense?] of home-planet = true or is-alien? builder)  [
      set selected-unit ""
      ask home-planet [
        ifelse ready-timer = 0 and (selected? = true or auto-defense? = true or is-alien? builder) [
          hatch-fighters 1 [
            If show-AI? [print "Hatched 1 fighter"]
            set shape "fighter"
            set selected? false
            set ready-timer round (10 / [spice-per-turn] of myself)
            set fighter-home-planet myself
            set label ready-timer
            set label-color yellow
            set heading random 360
            set size 1
            set color [color] of builder
            set owner builder
            set protected-planet myself
            set health 50
            fd 1
          ]
          ;reset planet visual values
          set color [color] of builder
          set size spice-per-turn
          set selected? false
          set ready-timer round (10 / [spice-per-turn] of self)
        ][
          user-message "This planet is already building something."
        ]
      ]
      ;subtract costs
      set will will - 1
      set spice spice - 250

    ]
  ]
end


to build-miner [builder home-planet]

  ;check to make sure player can build a new miner
  ask builder [
    if spice < 25 [user-message "You need 25 spice to build a miner."]
    if will < 1 [user-message "You do not have the political will to build a miner."]
  ]

  ;build the miner
  ask builder [
    if spice >= 25 and will >= 1 and ([selected?] of home-planet = [true] or is-alien? builder) [
      set selected-unit ""
      ask home-planet [
        ifelse ready-timer = 0 [
          hatch-miners 1 [
            set shape "miner"
            set selected? false
            if is-alien? builder [set hidden? true]
            set ready-timer round (5 / [spice-per-turn] of myself)
            set miner-home-planet myself
            set owner builder
            set label ready-timer
            set label-color yellow
            set size 1
            set color [color] of builder
            fd 1
          ]

          ;reset planet visual values
          set color [color] of builder
          set size spice-per-turn
          set selected? false
          set ready-timer round (5 / [spice-per-turn] of self)
        ][
          user-message "This planet is already building something."
        ]
      ]
      set will will - 1
      set spice spice - 25
    ]
  ]
end

to build-trader [builder home-planet]

  ;check to make sure player can build a new trading fleet
  ask builder [
    if spice < 1000 [user-message "You need 1000 spice to build a trading fleet."]
    if will < 5 [user-message "You need a political will of 5 to build a trading fleet."]
  ]

  ;build the trading fleet
  ask builder [
    if spice >= 1000 and will >= 5 and ([selected?] of home-planet = [true] or is-alien? builder) [
      set selected-unit ""
      ask home-planet [
        ifelse ready-timer = 0 [
          hatch-traders 1 [
            set shape "truck"
            set selected? false
            set ready-timer round (25 / [spice-per-turn] of myself)
            set trader-home-planet myself
            set distance-traveled 0
            set owner builder
            set label ready-timer
            set label-color yellow
            set size 1
            set color [color] of builder
            set destination one-of planets
            carefully [set heading towards destination][]
            fd 1
          ]

          ;reset planet visual values
          set color [color] of builder
          set size spice-per-turn
          set selected? false
          set ready-timer round (25 / [spice-per-turn] of self)
        ][
          user-message "This planet is already building something."
        ]
      ]
      set will will - 5
      set spice spice - 1000
    ]
  ]
end

to build-worker [builder home-planet]

  ;check to make sure player can build a new worker fleet
  ask builder [
    if spice < 500 [user-message "You need 500 spice to build a worker fleet."]
    if will < 3 [user-message "You need a political will of 3 to build a worker fleet."]
  ]

  ;build the worker fleet
  ask builder [
    if spice >= 500 and will >= 3 and ([selected?] of home-planet = [true] or is-alien? builder) [
      set selected-unit ""
      ask home-planet [
        ifelse ready-timer = 0 [
          hatch-workers 1 [
            set selected? false
            set ready-timer round (15 / [spice-per-turn] of myself)
            set worker-home-planet myself
            set owner builder
            set label ready-timer
            set label-color yellow
            set size 1
            set shape "plant"
            set color [color] of builder
            set heading random 360
            fd 1
          ]

          ;reset planet visual values
          set color [color] of builder
          set size spice-per-turn
          set selected? false
          set ready-timer round (15 / [spice-per-turn] of self)
        ][
          user-message "This planet is already building something."
        ]
      ]
      set will will - 3
      set spice spice - 500
    ]
  ]
end

to build-scout [builder home-planet]

  ;check to make sure player can build a new worker fleet
  ask builder [
    if spice < 10 [user-message "You need 10 spice to build a scout."]
  ]

  ;build the scout fleet
  ask builder [
    if spice >= 10 and ([selected?] of home-planet = [true] or [auto-explore?] of home-planet = true or is-alien? builder) [
      set selected-unit ""
      ask home-planet [
        ifelse ready-timer = 0 [
          hatch-scouts 1 [
            set selected? false
            set fuel 100
            set ready-timer round (5 / [spice-per-turn] of myself)
            set scout-home-planet myself
            set owner builder
            set label ready-timer
            set label-color yellow
            set shape "scout"
            set size 1
            set color [color] of builder
            set heading random 360
            fd 1
          ]

          ;reset planet visual values
          set color [color] of builder
          set size spice-per-turn
          set selected? false
          set ready-timer round (5 / [spice-per-turn] of self)
        ][
          user-message "This planet is already building something."
        ]
      ]
      set spice spice - 10
    ]
  ]
end

to build-strikers [builder]

  ;build a strike force
  ask builder [
    if spice >= 100 and will >= 1 [
      ask planets with [owner = builder and is-planet? target] [
        if ready-timer = 0 and [spice] of builder >= 50 and [will] of builder > 0 [
          ask builder [
            set spice spice - 100
            set will will - 1
          ]
          hatch-strikers 1 [
            set selected? false
            set ready-timer round (10 / [spice-per-turn] of myself)
            set owner builder
            set target-planet [target] of myself
            set striker-home-planet myself
            set label ready-timer
            set label-color yellow
            ;shape will be default turtle shape
            set size 1
            set color [color] of builder
            set heading towards target-planet
            fd 1
          ]
          ;reset planet visual values
          set color [color] of builder
          set size spice-per-turn
          set selected? false
          set ready-timer round (10 / [spice-per-turn] of self)
        ]
      ]
    ]
  ]

end

to build-seeker [builder home-outpost]

  ;build a seeker missile
  if [spice] of builder >= 5000 and [will] of builder >= 10 and [ready-timer] of home-outpost = 0 and [target] of home-outpost != 0 [
    ask builder [
      set spice spice - 5000
      set will will - 10
    ]
    ask home-outpost [
      hatch-seekers 1 [
        set selected? false
        set ready-timer round (50 / [upgrade-level] of myself)
        set owner builder
        set target-outpost [target] of myself
        set seeker-home-outpost myself
        set label ready-timer
        set label-color yellow
        ;shape will be default turtle shape
        set size 2
        if is-alien? owner [set color red]
        if is-player? owner [set color blue]
        set shape "seeker"
        set heading towards target-outpost
        fd 1
      ]
      ;reset planet visual values
      set color [color] of builder
      set size 1
      set selected? false
    ]
  ]


end

to build-moab [builder home-outpost]

  ;build a moab
  if [spice] of builder >= 5000 and [will] of builder >= 10 and [ready-timer] of home-outpost = 0 and [target] of home-outpost != 0 [
    ask builder [
      set spice spice - 5000
      set will will - 10
    ]
    ask home-outpost [
      hatch-moabs 1 [
        set selected? false
        set ready-timer round (50 / [upgrade-level] of myself)
        set owner builder
        set target-outpost [target] of myself
        set moab-home-outpost myself
        set label ready-timer
        set label-color yellow
        ;shape will be default turtle shape
        set size 2
        if is-alien? owner [set color red]
        if is-player? owner [set color blue]
        set shape "moab"
        set heading towards target-outpost
        fd 1
      ]
      ;reset planet visual values
      set color [color] of builder
      set size 1
      set selected? false
    ]
  ]


end

to build-outpost [outpost-builder home-planet]
  ;build an outpost

  ;check to make sure player can build a new worker fleet
  ask outpost-builder [
    if spice < 5000 [
      user-message "You need 5000 spice to build an outpost."
      stop
    ]

    if will < 10 [
      user-message "You need a political will of 10 to build an outpost."
      stop
    ]
  ]

  ;build the outpost
  ask outpost-builder [
    carefully [
      if spice >= 5000 and will >= 10 and ([selected?] of home-planet = [true] or is-alien? outpost-builder) [
        set selected-unit ""
        ask home-planet [
          ifelse ready-timer = 0 and has-outpost? = false [
            ask outpost-builder [
              set spice spice - 5000
              set will will - 10
            ]
            hatch-outposts 1 [
              set selected? false
              set ready-timer round (50 / [spice-per-turn] of myself)
              set outpost-home-planet myself
              set owner outpost-builder
              set upgrade-level 1
              set ammo 1
              set max-ammo 1
              set accuracy 50
              set label ready-timer
              set label-color yellow
              set shape "target"
              set size 1
              set color [color] of outpost-builder
              set heading random 360
              fd 2
            ]

            set has-outpost? true
            ;reset planet visual values
            set color [color] of outpost-builder
            set size spice-per-turn
            set selected? false
            set ready-timer round (50 / [spice-per-turn] of self)
            ask outpost-builder [ask my-links [set sentiment sentiment - 1]] ;military buildups stress relationships
          ][
            user-message "This planet is already building something, or already has an outpost."
          ]
        ]

      ]
    ][]
  ]

end

to build-new-planets

  ; chance that a blank patch will sprout a new planet
  if random 1000 = 1 [
    ask one-of patches with [patch-owner = 0] [
      sprout-planets 1 [
        set shape "dot"
        set color grey
        set owner "none"
        set selected? false
        set hidden? true
        set has-outpost? false
        set spice-per-turn random 3 + 1
        set size spice-per-turn
        set defenses (spice-per-turn * 20)
        set target 0
        set under-attack? false
        set auto-defense? false
        set auto-explore? false
        set attack-timer 0
        set ready-timer 0
      ]
    ]
  ]

end



to take-turn [player-taking-turn]

  recharge-outposts player-taking-turn
  move-scouts player-taking-turn
  move-miners player-taking-turn
  move-traders player-taking-turn
  trade-with-planets player-taking-turn
  move-workers player-taking-turn
  ;move-fighters player-taking-turn

  ;if player-taking-turn is an alien, check to see if they're at war first.  If not, build-strikers for player
  ifelse is-alien? player-taking-turn [
    ask player-taking-turn [
      ask my-links [
        if at-war? = true [
          build-strikers player-taking-turn
        ]
      ]
    ]
  ] [build-strikers player-taking-turn]

  move-outposts player-taking-turn

  move-strikers player-taking-turn
  move-seekers player-taking-turn
  move-moabs player-taking-turn
  attack-planets player-taking-turn
  attack-outposts player-taking-turn
  check-moabs player-taking-turn

  continue-construction player-taking-turn

  update-planet-attack-timers player-taking-turn
  auto-defend-planets player-taking-turn
  auto-explore-planets player-taking-turn

  update-explored player-taking-turn

end

to toggle-auto-defense
  ask planets with [selected? = true] [
    ifelse auto-defense? = true [
      set auto-defense? false
    ][
      set auto-defense? true
      set auto-explore? false
    ]

    set color blue
    set size spice-per-turn
    set selected? false
    if is-planet? target [ask target [set color [color] of owner]]

    ]
  set selected-unit ""
  update-map
end

to toggle-auto-explore
  ask planets with [selected? = true] [
    ifelse auto-explore? = true [
      set auto-explore? false
    ][
      set auto-explore? true
      set auto-defense? false
    ]
    set color blue
    set size spice-per-turn
    set selected? false
    if is-planet? target [ask target [set color [color] of owner]]
  ]
  set selected-unit ""
  update-map
end

to toggle-auto-off
  ask planets with [selected? = true] [
    set auto-explore? false
    set auto-defense? false
    set color blue
    set size spice-per-turn
    set selected? false
    if is-planet? target [ask target [set color [color] of owner]]
  ]
  set selected-unit ""
  update-map
end



to auto-defend-planets [planet-owner]
  ask planets with [owner = planet-owner and auto-defense? = true and ready-timer = 0] [
    if [spice] of planet-owner >= 250 and [will] of planet-owner >= 1 [
        build-fighter planet-owner self
    ]
  ]
end

to auto-explore-planets [planet-owner]
  ask planets with [owner = planet-owner and auto-explore? = true and ready-timer = 0] [
    if [spice] of planet-owner >= 10 [
        build-scout planet-owner self
    ]
  ]
end


to move-miners [miner-owner]

  ;mourn and remove lost miners
  ask miner-owner [
    set will will - ((count miners with [shape = "x" and owner = miner-owner]) * 10)
    ask miners with [shape = "x" and owner = miner-owner] [die]
  ]

  ;if there are no more planets to conquer, salvage miners for 10 spice each
  if count planets with [owner = "none"] = 0 [
    ask miners [
      ask owner [
        set spice spice + 10
      ]
      die
    ]
  ]

  ;set course
  ask miners with [ready-timer = 0 and owner = miner-owner] [
    set color [color] of miner-owner
    set label ""
    if is-player? miner-owner [ask my-links [die]]

    ;Set course
    if not is-planet? destination [
      ifelse is-player? miner-owner [
        let planet-to-mine (min-one-of planets with [owner = "none" and hidden? = false] [distance myself])
        if planet-to-mine != nobody [set destination planet-to-mine]
      ][
        let planet-to-mine (min-one-of planets with [owner = "none"] [distance myself])
        if planet-to-mine != nobody [set destination planet-to-mine]
      ]

    ]

    ;no was available last turn, try to recalculate destination
    if destination = nobody [
      ifelse is-player? miner-owner [
        let planet-to-mine (min-one-of planets with [owner = "none" and hidden? = false] [distance myself])
        if planet-to-mine != nobody [set destination planet-to-mine]
      ][
        let planet-to-mine (min-one-of planets with [owner = "none"] [distance myself])
        if planet-to-mine != nobody [set destination planet-to-mine]
      ]
    ]

    if is-planet? destination [
      if [owner] of destination != "none" [
        set destination nobody
        ask my-links [die]
      ]
    ]

    ;set heading and create course
    if is-planet? destination [
      carefully [set heading towards destination] []
      if is-player? miner-owner [ask my-links [die]]
      if is-player? miner-owner [create-course-to destination]
    ]

    ;move forward
    if is-turtle? [patch-owner] of patch-here and is-planet? destination [fd 1]
    if not is-turtle? [patch-owner] of patch-here and is-planet? destination [fd 0.1]

    ;check for lost in space.  The further a miner gets from friendly planets, the greater the chance of being lost.
    carefully [if random 500 + 1 < (distance one-of planets with [owner = miner-owner and home?]) and ([pcolor] of patch-here = black) [
      set size 1
      set color red
      set shape "x"
      ;      print (word "Miner " who " was lost in space.")
      ]
    ] []

]

end

to setup-mining [player-taking-turn]
  ask miners with [owner = player-taking-turn] [
    if any? planets-here with [owner = "none"] [
      ask patch-here [
        if is-player? player-taking-turn [
          set explored? true
        ]
      ]

      ask planets-here [
        set color [color] of player-taking-turn
        set owner player-taking-turn
        set size spice-per-turn
        set home? false
        if is-alien? player-taking-turn [set hidden? true]
        carefully [set frontier round distance one-of planets with [owner = player-taking-turn and home? = true]][]

        ask patches in-radius 2 [
          set patch-owner player-taking-turn
          if is-player? player-taking-turn [
            set pcolor lime
            set explored? true
          ]
          ;if is-alien? player-taking-turn [set pcolor [color + 4] of player-taking-turn]
        ]

        carefully [set frontier round distance one-of planets with [owner = player-taking-turn and home? = true]][]
        if is-player? owner [set label (word "You [" spice-per-turn "]")]
        set label-color black
      ]
      ask player-taking-turn [
        set will will + 5
        set max-will max-will + 1
      ]
      die
    ]
  ]

  ;if there are no more unoccupied planets, give spice back
  if count planets with [owner = "none"] = 0 [
    ask miners with [owner = player-taking-turn] [
      if any? planets-here with [owner = player-taking-turn] [
        ask player-taking-turn [set spice spice + 25]
        die
      ]
    ]
  ]


end

to move-traders [trader-owner]

  ;move traders in route to new planets
  ask traders with [ready-timer = 0 and owner = trader-owner] [
    set color [color] of trader-owner
    set label ""

    carefully [set heading towards destination][]

    ;head to random planet
    if destination = 0 [set destination one-of planets]

    ;if by chance the randomly selected planet is the home planet, choose another planet
    if planets-here = destination [set destination one-of planets]

    ;move forward
    if is-turtle? [patch-owner] of patch-here and is-planet? destination [fd 1]
    if not is-turtle? [patch-owner] of patch-here and is-planet? destination [fd 0.1]

    ;accumulate miles
    set distance-traveled distance-traveled + 1
  ]

end

to trade-with-planets [trader-owner]

  ;trade with planet and then set a new course
  ask traders with [ready-timer = 0 and owner = trader-owner] [
    if destination = one-of planets-here [
      let profit distance-traveled
      ask trader-owner [
        set spice spice + profit
      ]

      ;the owner of the planet gets profit as well (if different than the owner of the trader)

      carefully [ask one-of planets-here [
        if owner != trader-owner and owner != "none" [
          ask owner [
            set spice spice + profit
            ask my-links with [other-end = trader-owner] [
              set sentiment sentiment + 0.5
              if show-ai? [print (word trader-owner "'s trading fleet has completed a successful business deal with " myself ". This will benefit the relationship.")]
            ] ;trading improves relationships
          ]
        ]
        ]
      ][set destination one-of planets]

      set distance-traveled 0
      set destination one-of planets
    ]
  ]

end

to move-blackholes
  ask blackholes [

    ;move them off screen
    if round xcor = -50 or round xcor = 50 [die]
    if round ycor = -25 or round ycor = 25 [die]

    fd 1
    ask patches in-radius horizon [
      set patch-owner 0
    ]

    ask other turtles in-radius horizon [

      ifelse (breed = players) or (breed = aliens) [
        print "Blackhole did not kill a player or alien"
      ][die]

    ]


  ]
end


to move-scouts [scout-owner]

  ;remove scouts with no fuel
  ask scouts [
    if fuel < 1 [die]
  ]

  ;move scouts
  ask scouts with [ready-timer = 0 and owner = scout-owner] [

    set label ""
    ; Set a random heading.  If the scout it over 10 spaces from one of the players planets then set the heading to the closest friendly planet.
    set heading random 360
    ;distance too great, head back to friendly territory
    carefully [ifelse (distance min-one-of planets with [owner = scout-owner] [distance myself] > 10) [
      set heading towards min-one-of planets with [owner = scout-owner] [distance myself]
      if (patch-ahead 1 != nobody) and (not any? turtles-on patch-ahead 1) [fd 1]
      set fuel fuel - 1
    ][
      ;if scout isn't to far away from home, move him 1 space forward (check to make sure it's empty first)
      if (patch-ahead 1 != nobody) and (not any? turtles-on patch-ahead 1) [fd 1]
      set fuel fuel - 1
      ]
    ][]

  ]

end

to move-workers [worker-owner]
  ;move workers
  ask workers with [ready-timer = 0 and owner = worker-owner] [

    ask patch-here [
      if not any? planets-here and (patch-owner = 0) [
        set patch-owner worker-owner
        ask neighbors [
          if patch-owner != 0 and patch-owner != nobody [
            ask patch-owner [
              ask my-links with [other-end = worker-owner] [
                set sentiment sentiment - 0.25
                if show-ai? [print (word worker-owner " has stolen a patch of space from " myself ". This will not be good for the relationship")]
              ]
            ]
          ] ;workers that steal patches from other players cause damage to the relationship
          set patch-owner worker-owner]
      ]
    ]

    set heading random 360
    ifelse (distance min-one-of patches with [patch-owner = worker-owner] [distance myself] > 5) [
      carefully [set heading towards min-one-of planets with [owner = worker-owner] [distance myself]][]
      set label ""
      fd 1
    ][
      set label ""
      fd 1
    ]


    ask patch-here [
      if not any? planets-here and (patch-owner = 0) [
        ask workers-here [
          set ready-timer 20
          set label ready-timer
        ]
      ]
    ]
  ]

end

to move-fighters [fighter-owner]

  ;fighters move
;  ask fighters with [ready-timer = 0 and owner = fighter-owner] [
;    set color [color] of fighter-owner
;    set label ""
;    if is-turtle? destination [
;      set heading towards destination
;
;      ;move forward
;      if is-turtle? [patch-owner] of patch-here and is-planet? destination [fd 1]
;      if not is-turtle? [patch-owner] of patch-here and is-planet? destination [fd 0.1]
;    ]
;  ]

end

to move-strikers [striker-owner]
  ;strikers move
  ask strikers with [ready-timer = 0 and owner = striker-owner] [
    set color [color] of striker-owner
    set label ""
    if is-turtle? target-planet [
      carefully [set heading towards target-planet][]

      ;move forward
      if is-turtle? [patch-owner] of patch-here and is-planet? target-planet [fd 1]
      if not is-turtle? [patch-owner] of patch-here and is-planet? target-planet [fd 0.1]
    ]
  ]

end

to move-seekers [seeker-owner]
  ;seekers move
  ask seekers with [ready-timer = 0 and owner = seeker-owner] [
    set color [color] of seeker-owner
    set label ""
    if is-outpost? target-outpost [
      carefully [set heading towards target-outpost][]

      ;move forward
      fd 0.5
    ]
  ]

end

to move-moabs [moab-owner]
  ;moabs move
  ask moabs with [ready-timer = 0 and owner = moab-owner] [
    set color [color] of moab-owner
    set label ""
    if is-outpost? target-outpost [
      carefully [set heading towards target-outpost][]

      ;move forward
      fd 0.5
    ]
  ]
end

to move-outposts [outpost-owner]

  ask outposts with [ready-timer = 0 and owner = outpost-owner] [
    let defending-outpost self
    let outpost-target 0

    ;inspect each patch that is in range.  If a target is found, attack it

    ask patches in-radius 5 [

      ;inspect each turtle in the radius
      ifelse [ammo] of defending-outpost > 0 [
        carefully [
          ask one-of strikers-here with [owner != outpost-owner] [
            ;assuming unit is an enemy until proven otherwise
            set outpost-target self
            ask owner [
              ask my-links with [other-end = outpost-owner] [
                if at-war? = false [
                  ;unit is not enemy, standing down
                  set outpost-target 0
                ]
              ]
            ]
          ]
        ][]
      ][
        ;out of ammo, standing down
        set outpost-target 0
      ]


      ;if the unit is an enemy, attack!
      ask defending-outpost [
        if outpost-target != 0 [
          ifelse random 100 <= accuracy [
            ask outpost-target [
              create-attack-vector-from defending-outpost [set shape "default" set color red]
              set size 2
              set color red
              wait 0.1
              ask my-links [die]
              die
              stop
            ]
            set ammo ammo - 1
            set outpost-target 0
          ] [
            ask outpost-target [
              create-attack-vector-from defending-outpost [set shape "default" set color red]
              wait 0.1
              ask my-links [die]
              stop
            ]
            set ammo ammo - 1
            set outpost-target 0
          ]
        ]
      ]
    ]
  ]
end



to recharge-outposts [outpost-owner]
  ask outposts with [owner = outpost-owner] [
    set ammo ammo + 0.5
    if ammo > max-ammo [set ammo max-ammo]
  ]
end

to upgrade-outpost [outpost-owner outpost-being-upgraded]

  let upgrade-allowed? true

  ;check to make sure player can do the upgrade
  ask outpost-owner [
    if spice < 10000 [user-message "You need 10,000 spice to upgrade an outpost." set upgrade-allowed? false]
    if will < 10 [user-message "You do not have the political will to upgrade the outpost." set upgrade-allowed? false]
  ]

  ask outpost-being-upgraded [
    if upgrade-level = 4 [user-message "This outpost is already fully upgraded." set upgrade-allowed? false]
  ]


  ask outpost-owner [
    if upgrade-allowed? = true and spice >= 10000 and will >= 10 and ([selected?] of outpost-being-upgraded = [true] or is-alien? outpost-owner) [

      ask outpost-being-upgraded [
        set upgrade-level upgrade-level + 1
        set ready-timer round ((50 * upgrade-level) / [spice-per-turn] of outpost-home-planet)
        set max-ammo upgrade-level
        set accuracy (50 + (upgrade-level * 10))
          ask outpost-owner [
            set spice spice - 10000
            set will will - 10
          ]

        ;unselect
        set selected? false
        set color [color] of outpost-owner
        set size 1
        set label ready-timer
        set label-color yellow
      ]
    ]
  ]




end



to attack-planets [striker-owner]
  ask strikers with [owner = striker-owner] [
    let damage (random 50 + 1)

    if target-planet = one-of planets-here  [

      ;add to aliens' attack-goal decision making
      carefully [ask target-planet [
        if is-alien? owner [
          ask owner [
            ;declare war on attacker
            ask my-links with [other-end = striker-owner] [
              set sentiment 0
            ]
            set attack-goal attack-goal + damage * 5
          ]
        ]
      ]][]

      ;if there are fighters, attack them first, then any outposts, then go for the planet
      ifelse any? fighters with [protected-planet = [target-planet] of myself] [

        ask one-of fighters with [protected-planet = [target-planet] of myself] [
          set health health - damage
          ask protected-planet [
            set attack-timer 20
            set under-attack? true
          ]

          set size 5
          set color red
          wait 0.1
          set color [color] of owner
          set size 1
          wait 0.1

          if health < 1 [die]

          if show-AI? [print (word self " took " damage " damage")]
        ]

      ][

        ;attack planet
        ask planets-here [
          set defenses defenses - damage
          set under-attack? true
          set attack-timer 20
          set size 5
          set color red
          wait 0.1
          if is-player? [owner] of myself [set label (word "You [" spice-per-turn "]")]
          set label-color black
          if is-alien? owner [set color [color] of owner]
          if is-player? owner [set color blue]
          set size spice-per-turn
          wait 0.1
          if is-alien? owner [ask owner [set attack-goal attack-goal + 100]]

          ;planet conquered!
          if defenses < 1 [

            ;add to attack goal of the alien who just lost a planet, and subtrack from their max-will
            if is-alien? owner [
              ask owner[
                set attack-goal attack-goal + 100
                set max-will max-will - 1
              ]
            ]

            ;everything produced by the planet dies from lack of support
            ask strikers with [striker-home-planet = myself] [die]
            ask fighters with [fighter-home-planet = myself] [die]
            ask miners with [miner-home-planet = myself] [die]
            ask workers with [worker-home-planet = myself] [die]
            ask traders with [trader-home-planet = myself] [die]
            ask scouts with [scout-home-planet = myself] [die]
            ask outposts with [outpost-home-planet = myself] [die]

            set has-outpost? false

            if is-alien? owner [set color [color] of owner]
            if is-player? owner [set color blue]
            set owner [owner] of myself
            set size spice-per-turn
            set defenses (spice-per-turn * 20)
            set home? false
            set has-outpost? false
            set attack-timer 0
            set ready-timer 0
            set target 0
            if is-alien? [owner] of myself [set hidden? true]

            ask patches in-radius 2 [
              set patch-owner [owner] of myself
              if is-player? [owner] of myself [set explored? true]
              ;if is-alien? player-taking-turn [set pcolor [color + 4] of player-taking-turn]
            ]

            if is-player? [owner] of myself [set label (word "You [" spice-per-turn "]")]
            set label-color black
            set under-attack? false

            ;remove inbound strikers and clear attacking planet's target
            ask strikers with [target-planet = myself] [die]
            ask planets with [target = myself] [
              set target 0
              ask my-links [die]
            ]

            ask striker-owner [set max-will max-will + 1]
          ]

        ]

      ]

      die
    ]
  ]

end

to attack-outposts [seeker-owner]
  ask seekers with [owner = seeker-owner] [
    let damage (random 100 + 1)

    ;kill seeker if the outpost is already destroyed
    if target-outpost = nobody [die]

    ;check to see if seeker has arrived on target
    if target-outpost = one-of outposts-here  [

      ;add to aliens' attack-goal decision making
      ask target-outpost [
        if is-alien? owner [
          ask owner [
            ;declare war on attacker
            ask my-links with [other-end = seeker-owner] [
              set sentiment 0
            ]
            set attack-goal attack-goal + damage * 5
          ]
        ]
      ]

      ;attack outpost
        ask outposts-here [
          set size 5
          set color red
          wait 0.1
          if is-alien? owner [set color [color] of owner]
          if is-player? owner [set color blue]
          set size 1
          wait 0.1

          if is-alien? owner [ask owner [set attack-goal attack-goal + 100]]

          ;chance of destroying outpost
          if random 100 < 50 [


            ;downgrade outpost, or destroy it if it's only a level 1
            if upgrade-level = 1 [ ; the outpost is destroyed
              ask seekers with [target-outpost = myself] [die] ;all seekers bound for this outpost being destroyed are removed from the game
              ask seekers with [seeker-home-outpost = myself] [die]
              ask outposts with [target = myself] [set target 0] ;reset all outposts who were targeting this outpost
              ask outpost-home-planet [set has-outpost? false]
              die
            ]
            if upgrade-level = 2 [set upgrade-level 1]
            if upgrade-level = 3 [set upgrade-level 2]
            if upgrade-level = 4 [set upgrade-level 3]

            ;recalc based on new upgrade level
            set max-ammo upgrade-level
            set accuracy (50 + (upgrade-level * 10))
          ]
        ]
      die
    ]

  ]
end


to check-moabs [moab-owner]
  ask moabs with [owner = moab-owner] [
    let damage 0

    ;kill seeker if the outpost is already destroyed
    if target-outpost = nobody [die]

    ;check to see if seeker has arrived on target
    if target-outpost = one-of outposts-here  [

      ;add to aliens' attack-goal decision making
      ask target-outpost [
        if is-alien? owner [
          ask owner [
            ;declare war on attacker
            ask my-links with [other-end = moab-owner] [
              set sentiment 0
            ]
            set attack-goal attack-goal + damage * 5
          ]
        ]
      ]


      ;explode moab
      ask patches in-radius 3 [set pcolor yellow]
      set size 5
      set color red
      if is-alien? owner [set color [color] of owner]
      if is-player? owner [set color blue]
      set size 1
      wait 0.5

      ask turtles with [breed = fighters or breed = seekers or breed = workers or breed = traders] in-radius 5 [
        set damage random 100 + 1
        if damage < 50 [
          set size 5
          set color red
          wait 0.1
          set color [color] of owner
          set size 1
          die
        ]
      ]

      ;moab finishes and dies
      die
    ]

  ]
end



to continue-construction [unit-owner]
  ;continue contruction
  ask miners with [ready-timer > 0 and owner = unit-owner] [
    set ready-timer ready-timer - 1
    if not hidden? [set label ready-timer]
  ]

  ask fighters with [ready-timer > 0 and owner = unit-owner] [
    set ready-timer ready-timer - 1
    if hidden? = false [set label ready-timer]
  ]

  ask traders with [ready-timer > 0 and owner = unit-owner] [
    set ready-timer ready-timer - 1
    if not hidden? [set label ready-timer]
  ]

  ask workers with [ready-timer > 0 and owner = unit-owner] [
    set ready-timer ready-timer - 1
    if not hidden? [set label ready-timer]
  ]

  ask scouts with [ready-timer > 0 and owner = unit-owner] [
    set ready-timer ready-timer - 1
    if not hidden? [set label ready-timer]
  ]

  ask strikers with [ready-timer > 0 and owner = unit-owner] [
    set ready-timer ready-timer - 1
    if not hidden? [set label ready-timer]
  ]

  ask outposts with [ready-timer > 0 and owner = unit-owner] [
    set ready-timer ready-timer - 1
    if not hidden? [set label ready-timer]
  ]

  ask seekers with [ready-timer > 0 and owner = unit-owner] [
    set ready-timer ready-timer - 1
    if not hidden? [set label ready-timer]
    if ready-timer = 0 [
    ]
  ]

  ask moabs with [ready-timer > 0 and owner = unit-owner] [
    set ready-timer ready-timer - 1
    if not hidden? [set label ready-timer]
    if ready-timer = 0 [
    ]
  ]



  ;update values for player planets
  ask planets with [owner = unit-owner] [
    if ready-timer > 0 [set ready-timer ready-timer - 1]
  ]
end

to update-explored [unit-owner]

  if is-player? unit-owner [
    ask turtles with [owner = unit-owner] [
      ask patch-here [set explored? true]
      ask neighbors [set explored? true]
    ]
  ]
end


to check-relationships

  ;cap relationships to be between 0 and 100
  ask relationships [
    if sentiment < 0 [set sentiment 0]
    if sentiment > 100 [set sentiment 100]
  ]

  ;warn player of aliens getting mad or declaring war
  ask aliens [
    let disgruntled-alien self
    ask my-relationships [
      let other-player other-end

      ;check for putting on-notice
      if sentiment <= 40 and on-notice? = false [
        print (word disgruntled-alien " has put " other-end " on notice")
        if is-player? other-end [
          if alien1 = disgruntled-alien [user-message (word "Alien 1 has put you ON NOTICE!")]
          if alien2 = disgruntled-alien [user-message (word "Alien 2 has put you ON NOTICE!")]
          if alien3 = disgruntled-alien [user-message (word "Alien 3 has put you ON NOTICE!")]
          if alien4 = disgruntled-alien [user-message (word "Alien 4 has put you ON NOTICE!")]
          if alien5 = disgruntled-alien [user-message (word "Alien 5 has put you ON NOTICE!")]
        ]
        set on-notice? true
      ]

      ;check for declaring war
      if sentiment <= 20 and at-war? = false and (random 100 <= 10) [
        print (word disgruntled-alien " and " other-end " have declared WAR on each other!")
        if is-player? other-end [
          if alien1 = disgruntled-alien [user-message (word "Alien 1 has declared WAR on you!")]
          if alien2 = disgruntled-alien [user-message (word "Alien 2 has declared WAR on you!")]
          if alien3 = disgruntled-alien [user-message (word "Alien 3 has declared WAR on you!")]
          if alien4 = disgruntled-alien [user-message (word "Alien 4 has declared WAR on you!")]
          if alien5 = disgruntled-alien [user-message (word "Alien 5 has declared WAR on you!")]
        ]
        set at-war? true
        ask disgruntled-alien [
          set attack-goal max (list explore-goal improve-goal trade-goal defend-goal)
        ]
        if is-alien? other-end [
          ask other-end [
            set attack-goal max (list explore-goal improve-goal trade-goal defend-goal)
          ]
        ]
      ]

      ;check for bullying due to significant power imbalanaces
      if [score / 4] of end1 > [score] of end2 and [score] of disgruntled-alien > [score] of other-player and random 10000 = 1 [set sentiment 0]
      if [score / 4] of end2 > [score] of end1 and [score] of disgruntled-alien > [score] of other-player and random 10000 = 1 [set sentiment 0]


      if at-war? = true [set sentiment sentiment + 0.5] ;war fatigue

      ;offer truce
      if sentiment >= 30 and at-war? = true and (random 100 <= 5) and truces? = true [
        ifelse is-player? other-end [
          if user-yes-or-no? (word disgruntled-alien " has offered you a truce. Do you accept?") [
            set at-war? false
            set on-notice? false
            set sentiment 75 ;improve the relationship a bit in the spirit of rebuilding
            ask disgruntled-alien [
              ;remove inbound strikers and stand down planets
              ask strikers with [owner = disgruntled-alien] [
                if [owner] of target-planet = other-player [die]
              ]
              ask planets with [owner = disgruntled-alien] [
                if is-turtle? target [
                  if [owner] of target = other-player [set target 0]
                ]
              ]
            ]
          ]

        ][
          print (word disgruntled-alien " and " other-end " have entered into a truce.")
          set at-war? false
          set on-notice? false
          set sentiment 75 ;improve the relationship a bit in the spirit of rebuilding
          ask disgruntled-alien [
            ask strikers with [owner = disgruntled-alien] [
              if [owner] of target-planet = other-player [die]
            ]

            set attack-goal max (list explore-goal improve-goal trade-goal defend-goal);reset attack goal to be equal to the largest of any other goal
          ]

          if is-alien? other-player [
            ask other-player [
              set attack-goal max (list explore-goal improve-goal trade-goal defend-goal);reset attack goal to be equal to the largest of any other goal
            ]
          ]
        ]
      ]

    ]
  ]
end

to check-for-game-over
  ;kill off aliens with no planets, check for win
  ask aliens [
    if count planets with [owner = myself] = 0 [
      ask strikers with [owner = myself] [die]
      ask fighters with [owner = myself] [die]
      ask miners with [owner = myself] [die]
      ask workers with [owner = myself] [die]
      ask traders with [owner = myself] [die]
      ask scouts with [owner = myself] [die]
      die
    ]
  ]
  if count aliens = 0 [
    user-message "You WIN!"
    ask patches [set explored? true]
    ask turtles [set hidden? false]
    ask players [set hidden? true]
  ]


  if count planets with [is-player? owner] = 0 [
    user-message "Game Over."
    stop
  ]


end




to update-map


  ask players [set hidden? true]
  ask aliens [set hidden? true]

  ask turtles with [breed != traders and breed != fighters and breed != workers and breed != players and breed != aliens] [
    ifelse [explored?] of patch-here = true [set hidden? false] [set hidden? true]
  ]



  ask patches [
    ifelse explored? = false [
      set pcolor 3
    ] [
      if is-alien? patch-owner [set pcolor [color + 4] of patch-owner]
      if is-player? patch-owner [set pcolor lime]
      if patch-owner = 0 [set pcolor black]
      if patch-owner = nobody [set pcolor black set patch-owner 0]
    ]
  ]

  ask blackholes [
    ifelse [explored?] of patch-here = true [set hidden? false] [set hidden? true]
    ask patches in-radius horizon [if explored? = true [set pcolor 49]]
  ]


  ask outposts with [ready-timer = 0] [
    set label (word "[" upgrade-level "] A:" ammo "/" max-ammo)
    set label-color white
    if target = nobody [set target 0] ;reset targeting so outpost can be redirected to another target
    if outpost-home-planet = nobody [die]
  ]

  ask seekers [
    if target-outpost = nobody [die] ;remove seekers whos targets have been destroyed
    if is-alien? owner [set color red]
    if seeker-home-outpost = nobody [die]
  ]

  ask planets [
    if is-alien? owner [
      set color [color] of owner
      if alien1 = owner [set label "Alien 1"]
      if alien2 = owner [set label "Alien 2"]
      if alien3 = owner [set label "Alien 3"]
      if alien4 = owner [set label "Alien 4"]
      if alien5 = owner [set label "Alien 5"]
      set label-color black
    ]
    if is-player? owner [
      set color blue
      if auto-explore? = false and auto-defense? = false [set label (word "You [" size "]")]
      if auto-explore? = true [set label "Explore"]
      if auto-defense? = true [set label "Defense"]
      set label-color black
    ]
  ]

  ask miners [
    if miner-home-planet = nobody [die]
  ]

  ask fighters [
    if [explored?] of patch-here = true and show-fighters? = true [set hidden? false]
    if [explored?] of patch-here = true and show-fighters? = false [set hidden? true]
    if [explored?] of patch-here = false [set hidden? true]
    if fighter-home-planet = nobody [die]
    if ready-timer = 0 [set label ""]
  ]

  ask scouts [
    if scout-home-planet = nobody [die]
  ]

  ask strikers [
    if striker-home-planet = nobody [die]
  ]

  ask traders [
    if [explored?] of patch-here = true and show-traders? = true [set hidden? false]
    if [explored?] of patch-here = true and show-traders? = false [set hidden? true]
    if [explored?] of patch-here = false [set hidden? true]
    if trader-home-planet = nobody [die]
  ]

  ask workers [
    if [explored?] of patch-here = true and show-workers? = true [set hidden? false]
    if [explored?] of patch-here = true and show-workers? = false [set hidden? true]
    if [explored?] of patch-here = false [set hidden? true]
    if worker-home-planet = nobody [die]
  ]

  ;update relationship monitors on GUI
  ifelse alien1 = nobody [
    set alien1-status "Dead"
  ][
    if [on-notice?] of relationship [who] of player1 [who] of alien1 = false and [at-war?] of relationship [who] of player1 [who] of alien1 = false [set alien1-status "Peace"]
    if [on-notice?] of relationship [who] of player1 [who] of alien1 = true and [at-war?] of relationship [who] of player1 [who] of alien1 = false [set alien1-status "On-Notice"]
    if [at-war?] of relationship [who] of player1 [who] of alien1 = true [set alien1-status "War"]
  ]

  ifelse alien2 = nobody [
    set alien2-status "Dead"
  ][
    if [on-notice?] of relationship [who] of player1 [who] of alien2 = false and [at-war?] of relationship [who] of player1 [who] of alien2 = false [set alien2-status "Peace"]
    if [on-notice?] of relationship [who] of player1 [who] of alien2 = true and [at-war?] of relationship [who] of player1 [who] of alien2 = false [set alien2-status "On-Notice"]
    if [at-war?] of relationship [who] of player1 [who] of alien2 = true [set alien2-status "War"]
  ]

  ifelse alien3 = nobody [
    set alien3-status "Dead"
  ][
    if [on-notice?] of relationship [who] of player1 [who] of alien3 = false and [at-war?] of relationship [who] of player1 [who] of alien3 = false [set alien3-status "Peace"]
    if [on-notice?] of relationship [who] of player1 [who] of alien3 = true and [at-war?] of relationship [who] of player1 [who] of alien3 = false [set alien3-status "On-Notice"]
    if [at-war?] of relationship [who] of player1 [who] of alien3 = true [set alien3-status "War"]
  ]

  ifelse alien4 = nobody [
    set alien4-status "Dead"
  ][
    if [on-notice?] of relationship [who] of player1 [who] of alien4 = false and [at-war?] of relationship [who] of player1 [who] of alien4 = false [set alien4-status "Peace"]
    if [on-notice?] of relationship [who] of player1 [who] of alien4 = true and [at-war?] of relationship [who] of player1 [who] of alien4 = false [set alien4-status "On-Notice"]
    if [at-war?] of relationship [who] of player1 [who] of alien4 = true [set alien4-status "War"]
  ]

  ifelse alien5 = nobody [
    set alien5-status "Dead"
  ][
    if [on-notice?] of relationship [who] of player1 [who] of alien5 = false and [at-war?] of relationship [who] of player1 [who] of alien5 = false [set alien5-status "Peace"]
    if [on-notice?] of relationship [who] of player1 [who] of alien5 = true and [at-war?] of relationship [who] of player1 [who] of alien5 = false [set alien5-status "On-Notice"]
    if [at-war?] of relationship [who] of player1 [who] of alien5 = true [set alien1-status "War"]
  ]


end




to alien-decision [alien-making-decision]
  set alien-moving? true
  if show-AI? [type alien-making-decision print "'s turn"]

  ;update priorities
  ask alien-making-decision [

    ;explore
    ;heavy exploration for the first 20 turns
    if ticks < 20 [set explore-goal explore-goal + 10]

    ;+num_unexplored_planets
    set explore-goal explore-goal + (count planets with [owner = "none"] * 10)
    if show-AI? [print (word "Explore +" count planets with [owner = "none" and distance self < 10] " for unexplored planets")]

    ;-1 for each planet owned
    set explore-goal explore-goal - count planets with [owner = alien-making-decision]
    if show-AI? [print (word "Explore - " count planets with [owner = alien-making-decision] " for each owned planet")]

    ;-5 for each miner in existance
    set explore-goal explore-goal - count miners with [owner = alien-making-decision]
    if show-AI? [print (word "Explore - " count miners with [owner = alien-making-decision] " for each miner in existance")]


    ;improve
    ;+ for each owned planet
    set improve-goal improve-goal + (count planets with [owner = alien-making-decision] * 10)
    if show-AI? [print (word "Improve +" count planets with [owner = alien-making-decision] " for each owned planet")]


    ;- for each worker
    set improve-goal improve-goal - (count workers with [owner = alien-making-decision] * 2)
    if show-AI? [print (word "Improve -" (count workers with [owner = alien-making-decision] * 5) " for workers in existance")]

    ;trade
    ;+1 for each planet owned
    ifelse count traders with [owner = alien-making-decision] < 20 [
      set trade-goal trade-goal + 10
    ][
      set trade-goal trade-goal - 1
    ]


    ;defend
    ;+ for owned planets
    set defend-goal defend-goal + (count planets with [owner = alien-making-decision] * 10)
    if show-AI? [print (word "Defend +" count planets with [owner = alien-making-decision] " for each owned planet to defend")]

    ;- for fighters owned
    set defend-goal defend-goal - count fighters with [owner = alien-making-decision]
    if show-AI? [print (word "Defend -" count fighters with [owner = alien-making-decision] " for each fighter in existance")]

    ;attack
    ;increase each tick if at war
    ifelse count my-links with [at-war? = true] > 0 [set attack-goal attack-goal + 1] [set attack-goal attack-goal - 1]

    ;simulates getting frustrated at a max-will that's not enough to progress civilization and no more planets to capture
    if max-will < 5 and count planets with [owner = "none"] = 0 [set attack-goal attack-goal + 1]
    if max-will < 10 and count planets with [owner = "none"] = 0 [set attack-goal attack-goal + 1]


    ;no negative goals
    if explore-goal <= 0 [set explore-goal 1]
    if improve-goal <= 0 [set improve-goal 1]
    if trade-goal <= 0 [set trade-goal 1]
    if defend-goal <= 0 [set defend-goal 1]
    if attack-goal <= 0 [set attack-goal 1]

    ;show goals
    if show-AI? [type "Explore Goal: " print [explore-goal] of alien-making-decision]
    if show-AI? [type "Improve Goal: " print [improve-goal] of alien-making-decision]
    if show-AI? [type "Trade Goal: " print [trade-goal] of alien-making-decision]
    if show-AI? [type "Defend Goal: " print [defend-goal] of alien-making-decision]
    if show-AI? [type "Attack Goal: " print [attack-goal] of alien-making-decision]


    ;now execute on the decision some percentage of the time.  The higher the percentage
    if random 100  <= difficulty-level [
      loop [

        if show-AI? [print "Thinking..."]

        set decision-number random (explore-goal + improve-goal + trade-goal + defend-goal + attack-goal) + 1
        if show-AI? [print (word "Decision Total: " (explore-goal + trade-goal + improve-goal + defend-goal + attack-goal))]
        if show-AI? [print (word "Decision Number: " decision-number)]

        ;explore
        if decision-number <= explore-goal [
          if show-AI? [print "Decision is to explore."]
          if (spice < 10) [stop] ;can't do what I want to, so end turn
          if (spice >= 10) and (count planets with [ready-timer = 0 and owner = myself] > 0) and ((count planets with [owner = alien-making-decision] * 5) > count scouts with [owner = alien-making-decision]) [
            build-scout self (one-of planets with [owner = myself and ready-timer = 0])
          ]

          ifelse (spice >= 25) and (will >= 1) and (count planets with [ready-timer = 0 and owner = myself] > 0) and (count planets with [owner = "none"] > 0) [
            if show-AI? [print "Building miner."]
            build-miner self (one-of planets with [owner = myself and ready-timer = 0])
          ][stop]
        ]

        ;improve
        if decision-number > explore-goal and decision-number <= (explore-goal + improve-goal) [
          if show-AI? [print "Decision is to improve."]
          ifelse (spice >= 500) and (will >= 3) and (count planets with [ready-timer = 0 and owner = myself] > 0) [
            if show-AI? [print "Building worker."]
            build-worker self (one-of planets with [owner = myself and ready-timer = 0])
          ][stop]
        ]

        ;trade
        if decision-number > (explore-goal + improve-goal) and decision-number <= (explore-goal + improve-goal + trade-goal) [
          if show-AI? [print "Decision is to trade."]
          if show-AI? [print (word "Spice: " spice)]
          if show-AI? [print (word "Will: " will)]
          if show-AI? [print (word "Planets ready to build: " count planets with [ready-timer = 0 and owner = myself])]
          ifelse (spice >= 1000) and (will >= 5) and (count planets with [ready-timer = 0 and owner = myself] > 0) [
            if show-AI? [print "Building trader."]
            build-trader self (one-of planets with [owner = myself and ready-timer = 0])
          ][stop]
        ]

        ;defend
        ;ask planets under attack to build fighters
        if spice >= 250 and will > 0 [
          ask planets with [owner = alien-making-decision and ready-timer = 0] [
            if under-attack? and attack-timer > 0 [
              ask owner [
                if show-AI? [print "Building fighter."]
                if will > 0 [build-fighter alien-making-decision myself]
              ]
            ]
          ]
        ]

        ;build fighters and outposts
        if decision-number > (explore-goal + improve-goal + trade-goal) and decision-number <= (explore-goal + improve-goal + trade-goal + defend-goal) [
          if show-AI? [print "Decision is to defend."]

          ;upgrade outpost
          if (spice >= 10000) and (will >= 10) and count outposts with [owner = myself and ready-timer = 0 and upgrade-level < 4] > 0 [
            if show-AI? [print "Upgrading outpost."]
            upgrade-outpost self (one-of outposts with [owner = myself and ready-timer = 0 and upgrade-level < 4])
          ]

          ;build outpost
          if (spice >= 5000) and (will >= 10) and (count planets with [ready-timer = 0 and owner = myself] > 0) [
            if show-AI? [print "Building outpost."]
            build-outpost self (max-one-of planets with [owner = myself and ready-timer = 0 and has-outpost? = false][size])
          ]

          ;build fighter
          if (spice >= 250) and (will > 0) and (count planets with [ready-timer = 0 and owner = myself] > 0) [
            if show-AI? [print "Building fighter."]
            build-fighter self (one-of planets with [owner = myself and ready-timer = 0])
          ]
        ]

        ;attack
        if decision-number > (explore-goal + improve-goal + trade-goal + defend-goal) [
          if show-AI? [print "Decision is to attack."]

          ;attack enemy planets
          if show-ai? [print "Looking at relationships. . ."]

          ;continue attacking if at war with anyone
          ask alien-making-decision [
            ask my-links [
              ifelse at-war? = true [
                let my-enemy other-end
                let enemy-outpost-density 0
                if count planets with [owner = my-enemy] >= 1 [
                  set enemy-outpost-density count outposts with [owner = my-enemy] / count planets with [owner = my-enemy]
                ]

                if show-ai? [print (word "Sentiment with " my-enemy " is " sentiment ". Attacking " my-enemy)]
                if show-ai? [print (word my-enemy " outpost density is " enemy-outpost-density)]

                ;depending on outpost density, either target enemy planets with strikers or save up and send seekers.  Also, if alien doesn't have any outposts to build seekers, just start with strikers
                ifelse enemy-outpost-density < 0.20 or (count outposts with [owner = alien-making-decision] = 0) [
                  ;outpost density less than 20%, so let's send in the strikers
                  ;first, let's do some retargeting.  10% change that each planet retargets
                  ask planets with [owner = alien-making-decision and target != 0] [
                    if random 100 <= 10 [set target 0]
                  ]

                  ask planets with [owner = alien-making-decision and target = 0] [
                    set target min-one-of planets with [owner = my-enemy] [distance myself]
                    if show-ai? [print (word alien-making-decision " is targeting " target)]
                    if [owner] of target = alien-making-decision [set target 0]
                  ]
                ]
                [
                  ;outpost density is still too high.  Take them out with seekers
                  ;first, stop planets from targeting and creating strikers.
                  ask planets with [owner = alien-making-decision] [set target 0]
                  ;next, build seekers when we have the spice/will to do so
                  if [spice] of alien-making-decision >= 5000 and [will] of alien-making-decision >= 10 and count outposts with [owner = alien-making-decision] > 0 [
                    if show-ai? [print "Establishing outposts targets. . . "]
                    if any? outposts with [owner = alien-making-decision and target = 0] [
                      ask min-one-of outposts with [owner = alien-making-decision and target = 0] [distance self] [
                        let mytarget target
                        set target max-one-of outposts with [owner = my-enemy] [upgrade-level] ;target the most capable outposts first
                        if show-ai? [print (word self " is targeting " target)]
                        if target != nobody [build-seeker alien-making-decision self]
                      ]
                    ]
                  ]
                ]

              ] [if show-ai? [print "No enemies found."]]
            ]

            ;if attack-goal is 5x higher than any other goal (and a % chance), then pick on the smallest opponent and try to take over planets
            if attack-goal > (explore-goal * 5) or attack-goal > (improve-goal * 5) or attack-goal > (trade-goal * 5) or attack-goal > (defend-goal * 5) and random 100 = 1 [
              let my-enemy min-one-of other turtles with [breed = aliens or breed = players] [score]
              ask relationship [who] of alien-making-decision [who] of my-enemy [
                set sentiment 0
              ]
            ]

            ;build an outpost if possible
            if (spice >= 5000) and (will > 10) and (count planets with [ready-timer = 0 and owner = myself] > 0) [
              if show-AI? [print "Building outpost."]
              build-outpost self (max-one-of planets with [owner = myself and ready-timer = 0 and has-outpost? = false][size])
            ]
          ]
          stop
        ] ;end of attack

        if spice < 10 [stop]
        if will < 1 [stop]
        if count planets with [ready-timer = 0 and owner = myself] = 0 [stop]


      ];bottom of loop
    ]
  ]
end

to update-planet-attack-timers [player-taking-turn]
  ask planets with [owner = player-taking-turn and attack-timer > 0] [
    set attack-timer attack-timer - 1
    if attack-timer < 0 [set attack-timer 0]
  ]

  ask planets with [owner = player-taking-turn and attack-timer = 0] [
    set under-attack? false
  ]

end

to save-game
  let filepath "../flyers.csv"
  ifelse user-yes-or-no? (word "File will be saved at: " filepath "\nIf this file already exists, it will be overwritten.\nAre you sure you want to save?") [
    export-world filepath
    user-message "File Saved."
  ][
    user-message "Save Canceled. File not saved."
  ]
end

to load-game
  let filepath (word "../flyers.csv")
  ifelse user-yes-or-no? (word "Load File: " filepath "\nThis will clear your current level and replace it with the level loaded." "\nAre you sure you want to Load?") [
    import-world filepath
    user-message "Successfully loaded!"
  ][
    user-message "Load Canceled. File not loaded."
  ]
end

to calculate-scores
  ask players [
    set score
    spice +
    (will * 5) +
    (count miners with [owner = myself] * 30) +
    (count fighters with [owner = myself] * 255) +
    (count traders with [owner = myself] * 1025) +
    (count workers with [owner = myself] * 515) +
    (count scouts with [owner = myself] * 10) +
    (count strikers with [owner = myself] * 105) +
    (count seekers with [owner = myself] * 1050) +
    (count outposts with [owner = myself and upgrade-level = 1] * 5050) +
    (count outposts with [owner = myself and upgrade-level = 2] * 15050) +
    (count outposts with [owner = myself and upgrade-level = 3] * 25050) +
    (count outposts with [owner = myself and upgrade-level = 4] * 35050) +
    (round (count patches with [patch-owner = myself] / 10))
  ]

  ask aliens [
    set score
    spice +
    (will * 5) +
    (count miners with [owner = myself] * 30) +
    (count fighters with [owner = myself] * 255) +
    (count traders with [owner = myself] * 1025) +
    (count workers with [owner = myself] * 515) +
    (count scouts with [owner = myself] * 10) +
    (count strikers with [owner = myself] * 105) +
    (count seekers with [owner = myself] * 1050) +
    (count outposts with [owner = myself and upgrade-level = 1] * 5050) +
    (count outposts with [owner = myself and upgrade-level = 2] * 15050) +
    (count outposts with [owner = myself and upgrade-level = 3] * 25050) +
    (count outposts with [owner = myself and upgrade-level = 4] * 35050) +
    (round (count patches with [patch-owner = myself] / 10))
  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
4
10
1527
784
-1
-1
15.0
1
11
1
1
1
0
0
0
1
-50
50
-25
25
0
0
1
ticks
30.0

BUTTON
1628
10
1701
43
Restart
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
1532
46
1587
79
Turn
go
NIL
1
T
OBSERVER
NIL
T
NIL
NIL
1

MONITOR
1801
11
1891
68
Will
sum [will] of players
0
1
14

MONITOR
1707
11
1798
68
Spice
sum [spice] of players
0
1
14

BUTTON
1703
276
1888
309
Miner [25 Spice / 1 Will]
ask players [\nbuild-miner self planets with [selected? = true]\n]
NIL
1
T
OBSERVER
NIL
M
NIL
NIL
1

MONITOR
1768
70
1891
127
Spice Production
sum [spice-per-turn] of planets with [is-player? owner] +\nround (count patches with [is-player? patch-owner] / 10)
0
1
14

BUTTON
1703
310
1889
343
Fighter [250 Spice / 1 Will]
ask players [\nbuild-fighter self planets with [selected? = true]\n]
NIL
1
T
OBSERVER
NIL
F
NIL
NIL
1

SLIDER
1704
173
1876
206
alien-count
alien-count
1
5
5.0
1
1
aliens
HORIZONTAL

BUTTON
1628
82
1731
115
Select Planet
select-planet
T
1
T
OBSERVER
NIL
+
NIL
NIL
1

BUTTON
1703
381
1888
414
Trader [1000 Spice / 5 Will]
ask players [\nbuild-trader self planets with [selected? = true]\n]
NIL
1
T
OBSERVER
NIL
R
NIL
NIL
1

BUTTON
1703
346
1888
379
Worker [500 Spice / 3 Will]
ask players [\nbuild-worker self planets with [selected? = true]\n]
NIL
1
T
OBSERVER
NIL
W
NIL
NIL
1

BUTTON
1704
240
1888
273
Scout [10 Spice]
ask players [\nbuild-scout self planets with [selected? = true]\n]
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

SWITCH
1783
763
1894
796
aliens-on?
aliens-on?
0
1
-1000

BUTTON
1769
691
1894
724
Show Everything
ask patches [set explored? true]\nask turtles [set hidden? false]\nask players [set hidden? true]\ngo
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
1785
727
1894
760
Show-AI?
Show-AI?
1
1
-1000

BUTTON
1627
120
1733
153
Clear Targets
clear-target
NIL
1
T
OBSERVER
NIL
-
NIL
NIL
1

BUTTON
1789
656
1894
689
Cheat Button
ask players [set spice 10000 set max-will 1000 set will 1000]\nask planets with [is-player? owner] [set defenses 90000]
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
1748
135
1811
168
Save
save-game
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
1813
135
1876
168
Load
load-game
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
1755
582
1890
615
show-traders?
show-traders?
1
1
-1000

SWITCH
1755
614
1894
647
show-workers?
show-workers?
1
1
-1000

BUTTON
1703
428
1889
461
Outpost [5000 Spice / 10 Will]
ask players [\nbuild-outpost self planets with [selected? = true]\n]
NIL
1
T
OBSERVER
NIL
O
NIL
NIL
1

PLOT
1545
584
1705
704
alien1
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"explore" 1.0 0 -13791810 true "" "plot [explore-goal] of alien1"
"improve" 1.0 0 -955883 true "" "plot [improve-goal] of alien1"
"attack" 1.0 0 -2674135 true "" "plot [attack-goal] of alien1"
"defend" 1.0 0 -6459832 true "" "plot [defend-goal] of alien1"
"trade" 1.0 0 -13840069 true "" "plot [trade-goal] of alien1"

MONITOR
1625
165
1691
222
Traders
count traders with [is-player? owner]
0
1
14

BUTTON
1651
463
1890
496
Upgrade Outpost [10k Spice / 10 Will]
ask players [\nupgrade-outpost self outposts with [selected? = true]\n]
NIL
1
T
OBSERVER
NIL
U
NIL
NIL
1

SWITCH
1774
206
1877
239
truces?
truces?
1
1
-1000

BUTTON
1705
499
1894
532
Seeker [5000 Spice / 10 Will]
ask players [\nbuild-seeker self one-of outposts with [selected? = true]\n]
NIL
1
T
OBSERVER
NIL
E
NIL
NIL
1

MONITOR
1616
237
1690
294
Score
[score] of one-of players
0
1
14

PLOT
485
789
1012
1123
Score
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"player" 1.0 0 -16777216 true "set-plot-pen-color [color] of one-of players" "plot [score] of one-of players"
"Alien 1" 1.0 0 -2674135 true "set-plot-pen-color [color] of alien1" "plot [score] of alien1"
"Alien 2" 1.0 0 -6459832 true "set-plot-pen-color [color] of alien2" "plot [score] of alien2"
"Alien 3" 1.0 0 -1184463 true "set-plot-pen-color [color] of alien3" "plot [score] of alien3"
"Alien 4" 1.0 0 -13840069 true "set-plot-pen-color [color] of alien4" "plot [score] of alien4"
"Alien 5" 1.0 0 -13791810 true "set-plot-pen-color [color] of alien5" "plot [score] of alien5"

BUTTON
1589
46
1645
79
5 Turns
repeat 5 [go]
NIL
1
T
OBSERVER
NIL
5
NIL
NIL
1

BUTTON
1648
46
1707
79
10 Turns
repeat 10 [go]
NIL
1
T
OBSERVER
NIL
0
NIL
NIL
1

BUTTON
1612
346
1697
379
Auto-Defense
toggle-auto-defense
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
1612
380
1697
413
Auto-Explore
toggle-auto-explore
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
1613
415
1698
448
All Auto OFF
ask planets with [is-player? owner] [\nset auto-defense? false\nset auto-explore? false\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1533
132
1614
189
Alien 1
alien1-status
0
1
14

MONITOR
1533
189
1614
246
Alien 2
alien2-status
0
1
14

MONITOR
1533
246
1614
303
Alien 3
alien3-status
0
1
14

MONITOR
1533
302
1614
359
Alien 4
alien4-status
0
1
14

MONITOR
1533
358
1614
415
Alien 5
alien5-status
0
1
14

SWITCH
1755
550
1893
583
show-fighters?
show-fighters?
0
1
-1000

SLIDER
1533
746
1711
779
difficulty-level
difficulty-level
5
100
20.0
5
1
difficulty
HORIZONTAL

BUTTON
1549
499
1697
532
MOAB [5000 Spice / 10 Will]
ask players [\nbuild-moab self one-of outposts with [selected? = true]\n]
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

fighter
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -7500403 true true 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -13791810 true false 135 90 30
Line -7500403 true 75 60 75 105
Line -7500403 true 225 60 225 105

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

minefield
true
0
Circle -7500403 true true 45 165 30
Circle -7500403 true true 75 60 30
Circle -7500403 true true 45 90 30
Circle -7500403 true true 105 120 30
Circle -7500403 true true 120 60 30
Circle -7500403 true true 225 60 30
Circle -7500403 true true 165 75 30
Circle -7500403 true true 135 0 30
Circle -7500403 true true 90 255 30
Circle -7500403 true true 90 180 30
Circle -7500403 true true 120 210 30
Circle -7500403 true true 180 135 30
Circle -7500403 true true 165 255 30
Circle -7500403 true true 135 150 30
Circle -7500403 true true 210 210 30
Circle -7500403 true true 255 135 30

miner
true
0
Rectangle -7500403 true true 75 180 75 270
Rectangle -7500403 true true 75 180 75 270
Polygon -7500403 true true 195 45 90 45 75 255 225 255 195 45
Polygon -7500403 true true 75 255 45 255 90 135
Polygon -7500403 true true 225 255 255 255 195 120
Line -7500403 true 105 105 60 75
Line -7500403 true 180 105 225 75
Line -7500403 true 75 195 45 195
Line -7500403 true 255 195 225 195
Line -7500403 true 135 60 135 30
Line -7500403 true 165 60 165 30

moab
true
0
Polygon -7500403 true true 135 90 150 285 165 90
Polygon -7500403 true true 135 285 105 255 105 240 120 210 135 180 150 165 165 180 180 210 195 240 195 255 165 285
Rectangle -1184463 true false 135 45 165 90
Line -16777216 false 150 285 150 180
Polygon -2674135 true false 150 45 135 45 146 35 150 0 155 35 165 45
Line -16777216 false 135 75 165 75
Line -16777216 false 135 60 165 60

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

scout
true
0
Circle -7500403 true true 135 135 30
Line -7500403 true 150 135 150 120
Line -7500403 true 165 150 180 150
Line -7500403 true 135 150 120 150
Line -7500403 true 150 165 150 180

seeker
true
0
Polygon -7500403 true true 150 15 135 15 90 60 75 105 75 120 75 135 90 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 210 180 225 150 225 120 225 105 210 60 165 15

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
NetLogo 6.1.1
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

spacelane
0.0
-0.2 1 4.0 4.0 2.0 2.0
0.0 1 1.0 0.0
0.2 1 4.0 4.0 2.0 2.0
link direction
true
0

vector
2.0
-0.2 0 0.0 1.0
0.0 1 4.0 4.0
0.2 0 0.0 1.0
link direction
true
0
Line -2674135 false 150 150 120 210
Line -2674135 false 150 150 180 210
@#$#@#$#@
0
@#$#@#$#@
