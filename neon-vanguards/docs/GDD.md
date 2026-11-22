# Mark N' Shoot
Team: [Team Name]  
Platform: Android  
Orientation: Landscape (1280 x 720)

## 1. Pitch
A high-mobility 2D twin-stick jetpack shooter where players fly across floating arenas to outmaneuver and eliminate rogue combat drones offline or duel classmates over local Wi-Fi. Features 5 distinct playable hero operators.

## 2. Genre and Target Players
2D Arcade Jetpack Shooter / Arena Combat.  
Target players: Mobile gamers aged 16–25 seeking fast-paced competitive and tactical dual-stick action.

## 3. Playable Operators (5 Characters)
1. **Mark**: Balanced commando (100 HP, 300 Speed, 100 Fuel).
2. **Rene**: Agile stealth scout (80 HP, 360 Speed, fast recharge).
3. **Lebron**: Heavy power juggernaut (150 HP, 240 Speed, blast armor).
4. **Manny**: Rapid-fire boxing champion (90 HP, 35% faster trigger rate).
5. **Ronaldo**: High-flying aerial superstar (95 HP, 150 Fuel, 570 Thrust).

## 4. Weapons Arsenal (4 Primary Weapons)
1. **Plasma Carbine**: Fully-automatic rifle (22 DMG, 30 Ammo, 1.4s Reload, 850 Bullet Speed).
2. **Scatter Shotgun**: 5-pellet buckshot spread (14 DMG x 5, 8 Ammo, 2.0s Reload).
3. **Laser Railgun**: Hyper-velocity piercing sniper (85 DMG, 5 Ammo, 2.4s Reload, 1600 Speed).
4. **Rocket Launcher**: Heavy explosive warhead with splash damage (100 DMG, 4 Ammo, 2.6s Reload).

## 5. Game Mode Management
- **Survival Mode**: 1–2 players battle escalating waves of AI rogue drones across the 5 planetary arenas.
- **Deathmatch (FFA)**: Real-time 1v1 peer-to-peer duel over local Wi-Fi. First to 5 frags wins.
- **Team Deathmatch (TDM)**: Blue Team vs Red Team competitive shootout. First team to 10 frags claims victory.

## 3. Core Mechanic: What the Player Does Every Few Seconds, and the Touch Controls
- **Movement (Left Thumb)**: Floating virtual joystick. Moving left/right drives horizontal movement; pulling upward activates the jetpack thrusters to fly, consuming rechargeable fuel.
- **Aim & Shoot (Right Thumb)**: Floating virtual joystick for 360-degree aiming and continuous projectile firing when angled.
- **Special Action**: On-screen Grenade/Dash button to lob explosive plasma grenades.

## 4. Goal, Win Condition, Lose Condition
- **Goal**: Clear the arena of all hostiles before time expires.
- **Win Condition**: All enemy drones destroyed (`enemies_remaining == 0`) within the time limit.
- **Lose Condition**: Player health reaches 0 or timer reaches 0.

## 5. Level Plan (5 Distinct Themed Maps)
| Level | Map Name & Theme | Goal | What is New or Harder | Time Limit |
|:---:|---|---|---|:---:|
| **1** | **Jungle Outpost** (Tropical base, watchtowers, lush foliage) | Eliminate 1 Training Drone | Teaches basic flight, hover shooting, and cover | 60s |
| **2** | **Cyber Rooftops** (Neon city skyline, high-rise skyscrapers) | Eliminate 2 Scout Drones | Enemies move faster, take cover behind neon platforms | 55s |
| **3** | **Magma Caverns** (Underground volcano, lava pit, obsidian) | Eliminate 2 Magma Drones | Vertical cavern layout with glowing lava danger zone | 50s |
| **4** | **Orbital Station** (Deep cosmic space, ringed planet, moon base) | Eliminate 3 Combat Drones | Multi-tier low-gravity style platforms and 3 drones | 45s |
| **5** | **Desert Citadel** (Sunset ancient ruins, golden monoliths) | Defeat the Overlord Boss | Final Boss with 150 HP, rapid blasters, and high speed | 65s |

## 6. Unlocking Rule
Level $n+1$ remains locked until Level $n$ is cleared.  
Stars awarded based on remaining time:
- **3 Stars**: Clear level with $> 50\%$ time remaining.
- **2 Stars**: Clear level with $> 25\%$ time remaining.
- **1 Star**: Clear level before time expires.
Progress is saved immediately to `user://save.cfg`.

## 7. Offline Mode
Solo campaign mode playable with airplane mode on. Player fights intelligent state-machine AI opponents that hover, patrol, track the player, and take evasive maneuvers.

## 8. Online Mode (Same Wi-Fi)
1-vs-1 real-time deathmatch over local Wi-Fi using Godot's `ENetMultiplayerPeer`.
- Host creates lobby on port 7777 and displays local IP address.
- Guest enters IP and joins within 5 seconds.
- Positions, jetpack thruster particles, and rotation angles synced via `MultiplayerSynchronizer`.
- Host acts as network authority for hits, frags, and declaring the match winner.

## 9. Screens List
- `TitleScreen.tscn`: Game logo, start button, animated backdrop.
- `MainMenu.tscn`: Play, Settings, Credits, Quit buttons.
- `ModeSelect.tscn`: Play Offline vs Play Online buttons.
- `LevelSelect.tscn`: 5-level grid showing lock status and 1–3 star ratings.
- `Level01.tscn` to `Level05.tscn`: Battle arenas with HUD (health, jetpack bar, ammo, timer, pause).
- `PauseMenu.tscn`: Resume, Restart, Audio on/off, Quit to Level Select.
- `Result.tscn`: Win/Lose banner, stars, score, Retry, Next Level, Menu buttons.
- `Lobby.tscn`: Host, Join IP text field, connection status, error feedback.
- `Credits.tscn`: Attribution for all assets and open-source licenses.

## 10. Art and Sound Style + Asset Sources and Licenses
- Visuals: Vector sci-fi sprites, clean neon neon aesthetic, glowing particle thrusts.
- Assets: Kenney.nl Sci-Fi & UI Packs (CC0 Public Domain).
- Audio: jsfxr / Kenney Game Audio (laser shoot, thruster hum, explosions, level victory) (CC0).
- Fonts: Google Fonts (Rajdhani / Orbitron, SIL Open Font License).

## 11. Risks and Simpler Fallback
- **Risk**: Packet latency and position jitter over congested school Wi-Fi.
- **Fallback**: Dead reckoning / linear interpolation (`lerp`) on client synchronization and short 5-second timeout with friendly disconnect dialog.

