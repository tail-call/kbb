# Annotations

See https://github.com/LuaLS/lua-language-server/wiki/Annotations

# Plot

You're a magical kobold princess. You lead your tribe to the prosperity.

You have psy abilities, so your cursor has FOV just like you do.

# Plan

 - [x] Load from images and stuff
 - [x] Guys don't step on one another
 - [x] Sprite batch for background
 - [x] Player looks less like everyone else
 - [x] Read cga8.png bitmap font
 - [x] Sprites for movement animation
 - [x] Sprite turning
 - [x] Use canvas for animated water
 - [x] Squad recruiting
 - [x] Combat
 - [x] Building
 - [x] Wood resource
 - [x] Trees
 - [x] Chop trees
 - [x] Cursor
 - [x] Build houses with cursor
 - [x] Mouselook
 - [x] Zoom in/out
 - [x] FOV
 - [x] Focus mode
 - [x] Build with B
 - [x] Press LMB to show tile info
 - [x] WASD and HJKL movement
 - [x] Use neighbor-count based fov shading
 - [x] Hide objects outside of FOV
 - [x] Day/night cycle
 - [x] Hold arrows to walk
 - [x] Diagonal movement
 - [x] Highlight followers
 - [x] Minimap
 - [x] Pretzels will summon guys
 - [x] RPG stats
 - [x] Lerp over zoom
 - [x] Spawn animation for guys
 - [x] Zoom in on a highlighted tile
 - [x] HP system
 - [x] Diagonal movement should slide along walls
 - [x] Guys should attempt diagonal movement when moving forward doesn't work
 - [x] Order guys to chop trees
 - [x] Fog of war
 - [x] Tiles will change when a guy dies
 - [x] Gather command
 - [x] Only player and cursor reveal the map
 - [x] Everything in revealed fog of war is visible
 - [x] ~~Fade in / fade out objects within FOV~~
 - [x] ~~Combine fog of war with FOV~~
 - [x] Map reveal percent stat
 - [x] ~~Catch enemies into houses to recruit them~~
 - [x] Parallax out-of-border background
 - [x] Destroy rocks
 - [x] Unfightable neutral NPCs
 - [x] Fix: gather command works on frozen units
 - [x] Object extension based on `['X_Foo']` tags
       @class X_SaveToDisk:
       @field X_SaveToDisk X_SaveToDisk
       @field saveToDisk fun(diskSaver: DiskSaver)

       @class GameEntity: X_SaveToDisk

        X_SaveToDisk(entity).saveToDisk(diskSaver)

        function X_SaveToDisk(obj)
            return obj.X_SaveToDisk
        end


 - [x] Save/load
 - [x] Tiles can be picked up like objects
 - [ ] Load level immediately on game start
 - [ ] Save level immediately on game exit
 - [ ] Game is an editable image
 - [ ] Event system
 - [ ] Random terrain generation in a selected area
 - [ ] Lua console in focus mode
 - [ ] Timer type
 - [ ] Game is a GuyDelegate
 - [ ] Lerp cursor
 - [ ] Arbitrary resolution tilemaps
 - [ ] You must build roads for guys to navigate freely
 - [ ] Friendly guys wander when not in squad
 - [ ] Each guy has wander area they may never leave when not in squad
 - [ ] Humans don't have fast diagonal movement
 - [ ] Wander area moves as guy moves with the player
 - [ ] Wander areas of guys are resizable
 - [ ] Minimap fog of war
 - [ ] Flight ability
 - [ ] Flying mountable dragon
 - [ ] Coroutines for animations
 - [ ] Items on the ground are 2D sprites rotating around Z axis
 - [ ] Skills: combat, defence, chopping, etc. All of these grant XP. +1 level means +1 weight in table and +1 to the effect.
 - [ ] Chest for resources
 - [ ] Chest for treasures
 - [ ] Different types of tiles yield different movement speeds
 - [ ] Travelling through void is veeeeery slow but possible, even outside of the map
 - [ ] Teleport a group of guys
 - [ ] Multi-layer parallax pseudo 3D of world
 - [ ] Constantly lower HP in the area of enemy's spawn
 - [ ] Pixies visibly jump when they walk (shadow stays on the ground)
 - [ ] Damage numbers will display as damage is dealt
 - [ ] Remove from squad when too far
 - [ ] Unit highlight line will begin blinking when this happens
 - [ ] Add units to highlight continuously as button is held
 - [ ] Focus mode: unit and terrain are stacked like cards
 - [ ] Cards have actions
 - [ ] Command for bringing your troops closer to you
 - [ ] Underworld
 - [ ] Chopping wood is performed like combat
 - [ ] Mining stone is performed like combat
 - [ ] Fishing is performed like combat
 - [ ] Digging for treasures is performed like combat
 - [ ] Building is performed like combat
 - [ ] Buried treasures
 - [ ] Every guy may carry up to 10 of any item
 - [ ] Items may be dropped
 - [ ] Every guy may also have an item equipped: a tool or a weapon
 - [ ] A tool or a weapon affects ability rings
 - [ ] Squad's turn follows cursor
 - [ ] Workshop where foundations of buildings are made
 - [ ] A group of units must carry foundation to its place
 - [ ] Then unit carries wood to the site and builds the thing
 - [ ] Wolves
 - [ ] Dragons
 - [ ] Unicorns
 - [ ] Circle shaped cursor when pointing to unit/building
 - [ ] All guys have ability rings: they're being spinned during the battle to determine next action. Player is invited to optimize the ability rings towards most preferable outcome.
 - [ ] Ability rings has non-combat use, too: they may affect the outcome of other tasks such as gathering wood
 - [ ] Tavern
 - [ ] Boats
 - [ ] Ponies
 - [ ] Town hall
 - [ ] Mushrooms
 - [ ] Dynamic lighting
 - [ ] Noisy texture details when zooming in
 - [ ] Daily routines
 - [ ] Jobs
 - [ ] Hunger
 - [ ] Bonuses for exploring map

# Sources

`cga8.png` font taken from here: https://www.seasip.info/VintagePC/cga.html