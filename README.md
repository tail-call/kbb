# Annotations

See https://github.com/LuaLS/lua-language-server/wiki/Annotations

# Plot

You're a magical kobold princess. You lead your tribe to the prosperity.

You have psy abilities, so your cursor has FOV just like you do.

Game is an editable image.

# Plan

## Bugs

 - [ ] Dead guys are not deleted from the squad
 - [ ] Player always respawns in the same spot
 - [ ] Game crashes when saving game if a squad is not empty

## Quality of life

 - [ ] Focus mode is a scene
 - [ ] Event system
 - [ ] Path finding
 - [ ] Use normal methods in all modules
 - [ ] Savefile: index strings and object keys
 - [ ] Console command history
 - [ ] Use meshes and vertex shading for smooth fog of war
 - [ ] Game is a GuyDelegate
 - [ ] Don't crash on console command errors
 - [ ] Minimap fog of war
 - [ ] Coroutines for animations
 - [ ] Teleport a group of guys
 - [ ] Dynamic lighting
 - [ ] World is generated from randomly assembled 8x8 patches of lands where landmarks are assembled from templates. Certain patches may be marked as special to generate a predefined location like a dungeon or a town (underworld would be very helplful if i had this)
 - [ ] Max world size is 2048x2048 tiles (256x256 patches)
 - [ ] Each patch of land is a separate mesh
 - [ ] Each patch of fog of war is also a mesh
 - [ ] Measure revealed terrytory by patches rather than by tiles
 - [ ] Circle shaped cursor when pointing to unit/building

## Research

 - [ ] Random terrain generation in a selected area
 - [ ] Use FFI for huge arrays like fog of war
 - [ ] Try using native code with ffi
 - [ ] Try using love2d threads for something?

## Game ideas

 - [ ] Paint mode has primitive noise-based terrain generation tools
 - [ ] Guys are *lost* when are in the unexplored area
 - [ ] You can't recruit lost guys
 - [ ] Lost guys despawn after a while
 - [ ] Make fog be a noise rather than uniform color
 - [ ] Telefrags
 - [ ] Die when teleporting into a solid object
 - [ ] Wolves that only walk on forest tiles
 - [ ] Randomly generated dungeons: a door will appear when a new dungeon occurs
 - [ ] Underworld: do I have one huge underworld or many underworlds for many dungeons?
 - [ ] Give pretzels to feral kobolds to adopt them
 - [ ] Damage numbers will display as damage is dealt
 - [ ] Items on the ground are 2D sprites rotating around Z axis
 - [ ] Remove guy from squad when is too far
 - [ ] Unit highlight line will begin blinking when this happens
 - [ ] Humans don't have fast diagonal movement
 - [ ] Notable characters system: building an inn creates a barkeeper, building a smithy creates a blacksmith
 - [ ] Hunger: kobolds need to eat twice per day, or they will grow weak and die
 - [ ] Permadeath: when a player character dies, it dies forever. Next unit becomes the leader
 - [ ] Workshop where foundations of buildings are made
 - [ ] Then unit carries wood to the site and builds the thing
 - [ ] A group of units must carry foundation to its place
 - [ ] Daily routines
 - [ ] Dragon egg in the sanctuary
 - [ ] Sometimes player's character is immobilized (like stuck in rock) and her minions need to rescue her
 - [ ] When last character dies, a new is born from the dragon egg in the dragon shrine, then a new egg spawns immediately
 - [ ] Proximity based combat
 - [ ] You must build roads for guys to navigate freely
 - [ ] Each guy has wander area they may never leave when not in squad
 - [ ] Friendly guys wander when not in squad
 - [ ] Wander area moves as guy moves with the player
 - [ ] Wander areas of guys are resizable
 - [ ] Skills: combat, defence, chopping, etc. All of these grant XP. +1 level means +1 weight in table and +1 to the effect.
 - [ ] Chest for resources
 - [ ] Chest for treasures
 - [ ] Constantly lower HP in the area of enemy's spawn
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
 - [ ] Jobs
 - [ ] Dragons
 - [ ] Tavern
 - [ ] Town hall
 - [ ] All guys have ability rings: they're being spinned during the battle to determine next action. Player is invited to optimize the ability rings towards most preferable outcome.
 - [ ] Ability rings has non-combat use, too: they may affect the outcome of other tasks such as gathering wood

## Nice to have

 - [ ] UI: draggable panels
 - [ ] Tile elevation: let sand be slightly below grass, rocks be much higher than all else, forest is elevated to conceal whoever is walking over them
 - [ ] Built in text editor
 - [ ] Game plays in a window inside the GUI
 - [ ] Multiple game windows may be opened
 - [ ] `bind()` command to assign keys
 - [ ] Save level immediately on game exit
 - [ ] Half-square movement
 - [ ] Lerp cursor
 - [ ] Arbitrary resolution tilemaps
 - [ ] Flight ability
 - [ ] Swim ability
 - [ ] Flying mountable dragon
 - [ ] Boats
 - [ ] Unicorns
 - [ ] Bonuses for exploring map
 - [ ] Travelling through void outside of map is possible
 - [ ] Enemies have vision cones and you can sneak past them
 - [ ] Multi-layer parallax pseudo 3D of world
 - [ ] Pixies visibly jump when they walk (shadow stays on the ground)
 - [ ] Add units to highlight continuously as button is held
 - [ ] Focus mode: unit and terrain are stacked like cards
 - [ ] Cards have actions
 - [ ] Squad's turn follows cursor
 - [ ] Ridable ponies
 - [ ] Mushrooms
 - [ ] Noisy texture details when zooming in

## Completed

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
 - [x] Load level immediately on game start
 - [x] ~~Stack machine based save language like PDF~~

    10 20 30 \{ wood stone pretzels \} Resources \ld
    1130 0.6 \v{262,180}
    \{ time magnFactor playerPos \} Game \ld

 
 - [x] Game is an editable image
 - [x] Object hot reloading
 - [x] Health bars
 - [x] Command for bringing your troops closer to you
 - [x] Lua console in focus mode
 - [x] Travelling through void is veeeeery slow but possible
 - [x] Use mutators instead of methods to mutate objects
 - [x] Sythesize mutators to watch properties
 - [x] Pixelized pointer
 - [x] `init()` and `deinit()` module methods to reload individual objects
 - [x] BUGFIX: combat doesn't switch sides between rounds
 - [x] Different types of tiles yield different movement speeds
 - [x] Use package.preload to load resources
 - [x] Draw current patch only
 - [x] Don't serialize same object twice
 - [x] Timer type
 - [x] Drop GameEntity class: I already have type markers in my objects
 - [x] Use string buffers for text manipulation [1]
 - [x] Object info window near pointer
 - [x] Tile paint mode


# Sources

`cga8.png` font taken from here: https://www.seasip.info/VintagePC/cga.html

[1]: https://luapower.com/files/luapower/csrc/luajit/src/doc/ext_buffer.html