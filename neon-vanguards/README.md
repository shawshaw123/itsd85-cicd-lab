# Mark N' Shoot – ITSD 85 Lab

Team: [Team Name and Roles]  
Section: [Your Section]  
Platform: Android (Touchscreen, Landscape 1280x720)

## About the Game
Mark N' Shoot is a fast-paced 2D twin-stick jetpack shooter inspired by Mini Militia. Players pick from 5 unique playable operators (Mark, Rene, Lebron, Manny, Ronaldo) and take flight across multi-tiered floating arenas. Navigate obstacles, dodge enemy fire, and eliminate rogue AI drones offline or battle a friend in local Wi-Fi multiplayer.

## Playable Characters
- **Mark**: Balanced standard commando (100 HP, 300 Speed).
- **Rene**: Agile stealth scout with high mobility and fast fuel recovery (80 HP, 360 Speed).
- **Lebron**: Heavy blast-armored juggernaut (150 HP, 240 Speed).
- **Manny**: Rapid-fire boxing champ with lightning trigger speed (90 HP, rapid trigger).
- **Ronaldo**: High-flying aerial superstar with massive booster endurance (95 HP, 150 Fuel).

## Weapons Arsenal
- **Plasma Carbine**: Fully-automatic rifle (22 DMG, 30 Ammo, balanced).
- **Scatter Shotgun**: 5-pellet close-range blast (14x5 DMG, 8 Ammo).
- **Laser Railgun**: Long-range piercing sniper (85 DMG, 5 Ammo).
- **Rocket Launcher**: Explosive RPG with area splash damage (100 DMG, 4 Ammo).

## Game Modes
- **Survival**: Campaign level progression fighting AI drone waves.
- **Deathmatch (FFA)**: 1v1 PvP duel over local Wi-Fi (first to 5 frags).
- **Team Deathmatch (TDM)**: Blue Team vs Red Team competitive shootout.

## 5 Unique Themed Battle Maps
1. **Map 1: Jungle Outpost** – Tropical military camp with mountains, watchtowers, and lush foliage.
2. **Map 2: Cyber Rooftops** – Futuristic skyscraper roofs under a purple starry night with glowing neon billboards and windows.
3. **Map 3: Magma Caverns** – Subterranean volcanic bunker with molten lava pits, rock stalactites, and magma veins.
4. **Map 4: Orbital Station** – High-tech space station floating above a ringed planet with starry nebulae and solar platforms.
5. **Map 5: Desert Citadel** – Ancient pyramid ruins and golden sandstone monoliths bathed in a blazing desert sunset (Boss Arena).

## How to Play
- **Left Stick**: Move horizontally; push upward to ignite the jetpack thrusters and fly. Watch your fuel gauge!
- **Right Stick**: Aim 360 degrees and fire laser blaster bolts continuously.
- **Grenade Button**: Throw an explosive grenade towards the aimed direction.
- **Goal**: Destroy all enemy combatants before time runs out.
- **Level Unlocking**: Clearing Level $n$ unlocks Level $n+1$. Performance awards up to 3 stars.

## Offline and Online Modes
- **Offline Mode**: Playable completely in Airplane Mode with 0 internet connection. Progresses through 5 distinct campaign levels with increasing AI challenge.
- **Online Mode (Local Wi-Fi)**:
  - Host phone taps **Host Match** and shares the displayed IP address.
  - Client phone types the Host IP and taps **Join**.
  - Real-time deathmatch synchronizing player transforms, shooting, and health over UDP (`ENetMultiplayerPeer`).

## How to Build
- **Engine**: Godot Engine 4.x (Standard Edition, GL Compatibility Renderer).
- Open Godot 4, click **Import**, select `project.godot` inside this directory.
- For Android: Install OpenJDK 17 & Android SDK command-line tools. In Godot, go to `Project -> Export -> Android`, ensure `Internet` and `Access Network State` permissions are checked, and click `Export Project`.

## Download
- [v1.0 Release APK](https://github.com/)

## Playtest Results
- (To be populated during Week 5 playtest phase)

## Credits
- Refer to [docs/CREDITS.md](docs/CREDITS.md)

## Paper
- Refer to [docs/paper.pdf](docs/paper.pdf)

