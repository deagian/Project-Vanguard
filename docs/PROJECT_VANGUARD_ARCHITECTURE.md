# Project Vanguard Architecture

Current branch: `main`  
Current inspected commit: `5816dda Add SMG placeholder weapon`

## 1. Repository Tree

```text
src/
    client/
        Controllers/
            MovementController.lua
        Input/
            InputManager.lua
        Movement/
            MovementPro.client.lua
        UI/
            HUD/
                AmmoUI.client.lua
                CrosshairUI.client.lua
                HitMarkerUI.client.lua
                StaminaUI.client.lua
                WaveHUD.client.lua
                WeaponSlotsUI.client.lua
        Weapons/
            ADSController.lua
            AimCamera.client.lua
            AssaultRifleClient.client.lua
            PistolClient.client.lua
            SMGClient.client.lua
            WeaponEffects.lua
            WeaponPickupClient.client.lua
    server/
        EnemySystem/
            EnemyAI.lua
            EnemyConfig.lua
            EnemySpawner.lua
            GameLoop.server.lua
            WaveManager.lua
        MovementSystem/
            MovementServer.server.lua
        WeaponSystem/
            WeaponPickupServer.server.lua
            WeaponServer.server.lua
        TestArena.server.lua
    shared/
        Modules/
            GameSettings.lua
            MovementConfig.lua
            WeaponConfig.lua
        Remotes/
            MovementAction.model.json
            RequestWeaponPickup.model.json
            WeaponFire.model.json
            WeaponHitConfirm.model.json
    starterpack/
        AssaultRifle/
            AssaultRifleVisual.client.lua
            Barrel/init.meta.json
            GripPart/init.meta.json
            Handle/init.meta.json
            Magazine/init.meta.json
            Receiver/init.meta.json
            Stock/init.meta.json
            init.meta.json
        Pistol/
            PistolVisual.client.lua
            Barrel/init.meta.json
            Body/init.meta.json
            GripPart/init.meta.json
            Handle/init.meta.json
            init.meta.json
        SMG/
            SMGVisual.client.lua
            Barrel/init.meta.json
            GripPart/init.meta.json
            Handle/init.meta.json
            Magazine/init.meta.json
            Receiver/init.meta.json
            Stock/init.meta.json
            init.meta.json
```

Rojo mapping in `default.project.json`:

```text
ReplicatedStorage/Shared -> src/shared
ServerScriptService/Server -> src/server
StarterPack -> src/starterpack
StarterPlayer/StarterPlayerScripts/Client -> src/client
```

## 2. Weapon System

`src/server/WeaponSystem/WeaponServer.server.lua` is the authoritative firing server. Clients request shots through `WeaponFire`; the server validates weapon name, config existence, equipped Tool ownership, character state, cooldown, ray direction, raycast hit, friendly/self hit, and applies damage. It also tags enemy kill credit with `LastDamagedBy` and fires `WeaponHitConfirm` back to the shooter for hitmarker UI.

Weapon client scripts live in `src/client/Weapons/`:

- `PistolClient.client.lua`: semi-auto pistol, local ammo, reload, recoil, effects, and `WeaponFire` requests.
- `AssaultRifleClient.client.lua`: automatic rifle, local ammo, reload, automatic fire loop, recoil, effects, and `WeaponFire` requests.
- `SMGClient.client.lua`: placeholder automatic SMG using the rifle pattern with SMG config.
- `ADSController.lua`: right mouse ADS FOV and mouse sensitivity state.
- `AimCamera.client.lua`: over-the-shoulder aim camera offset and character facing for supported weapons.
- `WeaponEffects.lua`: muzzle flash, fire sound, muzzle position, and tracer helpers.
- `WeaponPickupClient.client.lua`: listens for pickup `ProximityPrompt` triggers and sends `RequestWeaponPickup`.

Weapon stats live in `src/shared/Modules/WeaponConfig.lua`.

Current weapons:

```text
Pistol
AssaultRifle
SMG
```

Tool locations:

```text
src/starterpack/Pistol
src/starterpack/AssaultRifle
src/starterpack/SMG
```

All three are currently default `StarterPack` weapons. Each Tool has a Rojo `init.meta.json`, a `Handle`, visual parts, and a local visual weld script. The visuals are placeholders; gameplay logic is not inside the Tools.

Weapon slot mapping is in `src/client/UI/HUD/WeaponSlotsUI.client.lua`:

```text
1 = Pistol
2 = AssaultRifle
3 = SMG
4 = empty
5 = empty
```

Pickup mapping is in `src/server/WeaponSystem/WeaponPickupServer.server.lua`:

```text
Pistol
AssaultRifle
```

At the inspected commit, `SMG` is not included in pickup mapping, so `WeaponId = "SMG"` pickups are not supported unless that mapping is extended.

Weapon remotes:

```text
WeaponFire: client -> server shot request
WeaponHitConfirm: server -> client hitmarker confirmation
RequestWeaponPickup: client -> server pickup request
```

## 3. Movement System

Input starts in `src/client/Input/InputManager.lua`.

Implemented:

- Sprint: `LeftShift`, client-side state, speed from `GameSettings.SprintSpeed`.
- Stamina: local stamina pool in `MovementController`, displayed by `StaminaUI`.
- Crouch: `C` toggles crouch, changes speed, camera offset, character attributes, and attempts crouch animations from configured asset ids.
- Dodge/slide: `LeftControl` plus `A` or `D` while sprinting. Client requests `MovementAction:FireServer("Dodge", side)`, server validates cooldown/basic state, then returns `DodgeAccepted`.
- ADS: right mouse via `ADSController`, with `AimCamera` handling shoulder camera offset for `Pistol`, `AssaultRifle`, and `SMG`.

Disabled or not implemented:

- Prone is not implemented.
- Slide/dodge is not fully server-authoritative; local velocity is applied after server accepts.
- Stamina is local; there is a TODO to move stamina validation server-side.

Server movement file:

- `src/server/MovementSystem/MovementServer.server.lua`: validates dodge direction, cooldown, alive state, crouch state, and stores replicated crouch attributes.

Shared movement settings:

- `src/shared/Modules/GameSettings.lua`: walk speed, sprint speed, stamina values, round time.
- `src/shared/Modules/MovementConfig.lua`: slide/dodge and crouch settings.

## 4. UI System

HUD files live in `src/client/UI/HUD/`.

`WeaponSlotsUI.client.lua`:

- Hides Roblox default Backpack.
- Creates a custom 5-slot weapon bar.
- Uses keybinds `1-5` through `ContextActionService`.
- Equips via `Humanoid:EquipTool`.
- Pressing the same equipped slot unequips.
- Shows weapon silhouettes/placeholders, not weapon name text.
- Supports visual slot feedback with `TweenService` and `UIScale`.
- Supports auto-fade after inactivity.
- Destroys old `WeaponSlotsUI` on startup to avoid duplicate ScreenGui during Rojo hot-sync.

`AmmoUI.client.lua`:

- Reads player attributes set by weapon clients.
- Shows equipped weapon ammo or reload text.
- Does not affect gameplay.

`CrosshairUI.client.lua`:

- Shows crosshair for supported Tools.
- Shrinks crosshair while `ADSActive` attribute is true.
- Supported: `Pistol`, `AssaultRifle`, `SMG`.

`HitMarkerUI.client.lua`:

- Listens to `WeaponHitConfirm`.
- Shows center hitmarker, red for headshot.

`StaminaUI.client.lua`:

- Requires `MovementController`.
- Reads local stamina every render step.
- Displays stamina bar and color state.
- Cleans legacy stamina HUD names and avoids duplicate main HUD.

`WaveHUD.client.lua`:

- Reads player attributes from wave system: `CurrentWave`, `PlayerKills`, `PlayerDeaths`, `WaveMessage`.
- Displays wave/kills/deaths and wave messages.

Communication style:

- Weapon UI uses player attributes and Tool presence in Backpack/Character.
- Hitmarker uses `WeaponHitConfirm`.
- Movement UI reads local controller state.
- Wave UI reads replicated player attributes.

## 5. Folder Responsibilities

`src/client/`:

Client-only local scripts and modules. Handles input, local movement feel, HUD, weapon controls, local recoil/effects, ADS camera, and pickup request forwarding.

`src/server/`:

Server-only systems. Handles trusted weapon damage, pickup validation/grants, movement action validation, generated test arena, enemy AI, enemy spawning, and wave loop.

`src/shared/`:

Replicated modules and remotes. Contains weapon/movement/game settings and RemoteEvent model declarations.

`src/starterpack/`:

Default Tool instances given to players on spawn. Currently contains `Pistol`, `AssaultRifle`, and `SMG`.

## 6. Current Implemented Features

- Generated urban blockout/test arena.
- Player spawn and enemy spawn markers.
- Default weapons: Pistol, AssaultRifle, SMG.
- Custom weapon slot HUD for 5 slots.
- Slot animations and auto-fade.
- Hidden default Roblox Backpack.
- Pistol shooting, reload, recoil, muzzle/tracer/fire sound effects.
- AssaultRifle automatic shooting, reload, recoil, muzzle/tracer/fire sound effects.
- SMG placeholder automatic shooting, reload, recoil, muzzle/tracer/fire sound effects.
- Server-authoritative weapon damage and cooldown validation.
- Headshot/body shot damage handling.
- Hitmarker feedback.
- ADS FOV and shoulder camera/facing system.
- Crosshair with ADS style change.
- Sprint, stamina, crouch, and dodge/slide.
- Server-side enemy AI with detection, line-of-sight, movement, ranged attack, muzzle flash, sound, and tracer.
- Wave manager with two defined waves.
- Player kill/death/wave HUD.
- Weapon pickup flow for Pistol and AssaultRifle via `WeaponId`.

## 7. Current Placeholder Systems

- Pistol, AssaultRifle, and SMG visual models are simple placeholder parts.
- Weapon slot icons are drawn with UI frames as silhouettes.
- SMG is a placeholder weapon using cloned rifle-style logic.
- Fire sounds use temporary Roblox asset ids.
- Reload sound ids are intentionally empty to avoid blocked asset errors.
- Enemy rifle is a generated placeholder part.
- Test arena/map is generated by `TestArena.server.lua`.
- Enemy rigs are generated from a blank `HumanoidDescription`.
- Pickup prompt system is minimal and does not include inventory database, respawn, or drop lifecycle.

## 8. Current Technical Debt

- Weapon clients duplicate a lot of logic across Pistol, AssaultRifle, and SMG.
- Weapon pickup mapping is separate from `WeaponConfig`; SMG config exists but pickup mapping does not include SMG.
- All weapons are default StarterPack tools; there is no dedicated weapon template storage yet.
- Ammo is client-local, while damage/cooldown is server-authoritative.
- Several debug prints are noisy, especially in weapon firing.
- Hitmarker comment mentions pistol even though it listens to generic weapon hit confirmation.
- UI idempotence varies: WeaponSlotsUI and StaminaUI clean old GUIs; some other HUDs create ScreenGuis without old-GUI cleanup.
- Stamina is local and not server-authoritative.
- Dodge/slide has server acceptance but client applies velocity locally.
- Crouch animation asset ids may require ownership/availability validation.
- Free/real weapon asset import pipeline is not formalized.
- Pickup object lifecycle has no respawn or persistence layer.
- No automated tests or lint config are present in repo.

## 9. Future Expansion Points

Weapons:

- Add stats in `src/shared/Modules/WeaponConfig.lua`.
- Add or generalize client logic under `src/client/Weapons/`.
- Add Tool visual under `src/starterpack/` or a future server-only template folder.
- Register supported weapon names in `WeaponSlotsUI`, `CrosshairUI`, `AimCamera`, and `WeaponEffects`.
- Extend `WeaponPickupServer` mapping if pickup support is needed.

Enemy types:

- Add variants to `src/server/EnemySystem/EnemyConfig.lua`.
- Extend `EnemySpawner` to choose enemy type/model.
- Extend `EnemyAI` or split behavior modules for specialized enemies.

Movement abilities:

- Add input in `InputManager` or `MovementPro.client.lua`.
- Add config in `MovementConfig`.
- Add validation in `MovementServer.server.lua`.
- Keep server validation separate from local feel.

UI:

- Add HUD scripts under `src/client/UI/HUD/`.
- Prefer idempotent ScreenGui creation: destroy/reuse existing GUI by stable name.
- Communicate through player attributes or remotes, not direct server state assumptions.

Inventory:

- Current inventory is Tool presence in Backpack/Character.
- A future inventory should centralize owned weapon state, loadout slots, pickup grants, respawn behavior, and duplicate rules.

## 10. Important Conventions

WeaponId usage:

- Pickup objects should use `WeaponId` attribute.
- Current supported pickup ids: `Pistol`, `AssaultRifle`.
- Do not infer weapon type from model name.

Slot system:

- Slot mapping lives in `WeaponSlotsUI.client.lua`.
- Current mapping: `1=Pistol`, `2=AssaultRifle`, `3=SMG`, `4/5=nil`.
- Slot equip searches local Character and Backpack for a Tool with matching name.
- Weapon names should not be displayed in slot UI.

Pickup system:

- Client only sends pickup root instance through `RequestWeaponPickup`.
- Server validates distance and supported `WeaponId`.
- Server checks both Backpack and Character to prevent duplicates.
- Server clones from `StarterPack` and consumes pickup on success.

Rojo structure:

- `default.project.json` maps `src/shared`, `src/server`, `src/starterpack`, and `src/client`.
- Remotes use `.model.json` files under `src/shared/Remotes`.
- Tool folders use `init.meta.json` for Tool/Part metadata.

Naming conventions:

- Tool names must match weapon ids and config keys exactly: `Pistol`, `AssaultRifle`, `SMG`.
- Client weapon scripts are named by weapon: `PistolClient`, `AssaultRifleClient`, `SMGClient`.
- Generated/test world objects use explicit names such as `Map`, `PlayerSpawn`, `EnemySpawn1`.

Idempotent UI rules:

- Use stable ScreenGui names.
- Destroy or reuse old ScreenGui on script start when Rojo hot-sync can rerun scripts.
- Avoid duplicate input/action bindings; `WeaponSlotsUI` unbinds its `ContextActionService` action before rebinding.
- Use connection guards for repeated Tool watches where possible.

Server authoritative rules:

- Server decides damage, hit validation, equipped weapon validity, cooldowns, and pickup grants.
- Clients may request fire or pickup, but should not decide damage or grant inventory.
- Movement is partly authoritative for dodge acceptance but still has local stamina/velocity debt.

