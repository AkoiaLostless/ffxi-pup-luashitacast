# FFXI Puppetmaster LuAshitacast profile

Puppetmaster job profile for LuAshitacast (Ashita v4), built on Rag's LuAshitacast (RAGS) v320 common files. Level-75 era content (Horizon).

## Install

```
Ashita/config/addons/luashitacast/
├── <CharacterName_ID>/
│   └── PUP.lua                from this repo (your gear and settings)
└── common/
    ├── gcinclude-pup.lua      from this repo (all PUP-specific logic)
    ├── gcinclude-rag.lua      Rag's v320 (not in this repo)
    ├── gcmelee.lua            Rag's v320 (not in this repo)
    ├── gcmage.lua             Rag's v320 (not in this repo)
    └── gcdisplay-rag.lua      Rag's v320 (not in this repo)
```

- `PUP.lua` goes in your character folder.
- `common/gcinclude-pup.lua` goes in the `common` folder inside `luashitacast`, next to Rag's files.
- Rag's four files are not in this repo; get them from RAGS: https://github.com/yzyii/luashitacast

## PUP commands

| Command | What it does |
|---|---|
| `/pupmode` | Cycles the automaton mode: Tank → Melee → Ranged → Mage → Heals. While the automaton is engaged, the set with that name is worn on top. Pet magic legs follow it: Heals → `Pet_Magic` + `Pet_Magic_Cure`, Mage → `Pet_Magic` + `Pet_Magic_Black`. |
| `/pupmode <name>` | Jumps straight to a mode, e.g. `/pupmode ranged`. |
| `/tp` (or `/tpset`) | Cycles LowAcc → Hybrid → HighAcc. Engaged: `TP_LowAcc` is the base, plus `TP_Hybrid` or `TP_HighAcc`. Automaton engaged and you not: `Pet_Only_Tp_LowAcc` / `_Hybrid` / `_HighAcc`. Weaponskills: `WS`, plus `WS_HighAcc` in HighAcc. |
| `/petdt` | Toggles `Pet_Dt` on top of everything else. |
| `/petws` | Toggles automatic pet weaponskill gear (`Pet_WS` melee, `Pet_RNGWS` ranged). On by default. |
| `/staff` | Toggles weapon swaps while casting. Off by default, so Main and Sub stay put during precast and midcast. Turn it on to let a staff in your spell sets or Rag's elemental staves go on. Starting value: `allow_staff_swaps` in `PUP.lua`. |
| `/pupdebug` | Prints PupMode, IdleSet, pet, Lock, the pet magic legs, your Status, SubJob and the `Resting_MPSub` staff. |

## Automatic PUP behavior

- **Maneuvers:** using a maneuver puts on that element's set before the maneuver is sent and holds it 0.5 seconds after it finishes: `Fire_Maneuver`, `Ice_Maneuver`, `Wind_Maneuver`, `Earth_Maneuver`, `Thunder_Maneuver`, `Water_Maneuver`, `Light_Maneuver`, `Dark_Maneuver`.
- **Other job abilities:** Activate / Deus Ex Automata → `Activate`, Repair / Maintenance → `Repair`, Overdrive → `Overdrive` (also kept on while the buff is up), Ventriloquy → `Ventriloquy`, Role Reversal → `Role_Reversal`.
- **Resting on an MP subjob:** on DRK, WHM, RDM, BLM or BLU, `Resting_MPSub` (your Dark Staff) goes on over Rag's Resting set after the same 16 second wait.
- **/DRK extras (Rag v320):** Weapon Bash → `WeaponBash`; Stun with `/mode` Accuracy → `StunACC`.
- **Subjob TP pieces:** while engaged, `TP_DRG` on /DRG and `TP_THF` on /THF.
- **Automaton out:** `Idle_Pet` is layered over Idle while the automaton is out and you are idle.

## Rag's commands

### Idle overrides

Each one switches your idle set to that set. Type the same command again to go back.

| Command | Set |
|---|---|
| `/idle` | Swaps `Idle` ↔ `IdleALT` |
| `/dt`, `/pdt` | `DT` |
| `/mdt` | `MDT` |
| `/fireres`, `/fres` | `FireRes` |
| `/iceres`, `/ires`, `/bres` | `IceRes` |
| `/lightningres`, `/lres`, `/tres` | `LightningRes` |
| `/earthres`, `/eres`, `/sres` | `EarthRes` |
| `/windres`, `/wires`, `/ares` | `WindRes` |
| `/waterres`, `/wares`, `/wres` | `WaterRes` |
| `/evasion`, `/eva` | `Evasion` |
| `/override`, `/or` | `Override` |

### Melee and general

| Command | What it does |
|---|---|
| `/kite` | Toggles the `Movement` set on. |
| `/lock` | Toggles an equipment lock (`/lac disable all` / `enable all`), so nothing swaps until you turn it off. |
| `/lockset <1-3>` | Equips `LockSet1`, `LockSet2` or `LockSet3` and locks your gear. Use `/lock` to unlock. |
| `/weapon`, `/wl` | Cycles your weapon loadout 1 → 2 → 3 (`Weapon_Loadout_1`-`3`). `/wl 2` jumps to loadout 2. |
| `/dps` | Toggles DPS mode (on by default). Off stops TP sets and weapon loadouts going on when you engage. |
| `/lag` | Toggles lag mode. On turns off midcast delays, for a laggy connection. |
| `/sethp <number>` | HP below which regen gear goes on while idle. Overrides `max_hp_in_idle_with_regen_gear_equipped` in `PUP.lua`. |
| `/addhp <number>` | Extra HP added to that threshold. |
| `/resethp` | Clears `/sethp` and `/addhp`. |
| `/warpme` | Equips your Warp Cudgel and uses it after 31 seconds. |
| `/reraise` | Equips your Reraise Hairpin and uses it after 31 seconds. |
| `/horizonmode` | Horizon Mode Toggle |

### Magic (for your subjob spells)

| Command | What it does |
|---|---|
| `/mode` | Cycles magic mode Potency ↔ Accuracy. Accuracy uses `EnfeeblingACC` and gcmage's accuracy sets. |
| `/setmp <number>` | Your max MP, for gcmage's MP-based gear checks. Overrides the `*SJMaxMP` settings in `PUP.lua`. |
| `/addmp <number>` | Extra MP added to that value. |
| `/resetmp` | Clears `/setmp` and `/addmp`. |

## What Horizon Mode turns off

With LuAshitacast's Horizon Mode on, your normal gear check runs only once after each of your own actions (an ability, spell, weaponskill, ranged attack, item or `/lac fwd` command). It does not keep re-checking in the background. Your action gear (job abilities, maneuvers, precast, midcast, weaponskills) still works as normal. Anything that waits for something else to happen does not update until your next action:

- **Pet weaponskill gear:** `Pet_WS` and `Pet_RNGWS` don't go on when the automaton reaches TP or starts a weaponskill.
- **Pet magic by spell type:** the profile can't react to which spell the automaton casts. That's why the pet magic legs follow `/pupmode` (Heals / Mage) instead.
- **Automaton engaging or disengaging:** `Pet_Only_Tp_*`, the `/pupmode` sets and `Idle_Pet` don't switch when the automaton engages, disengages or is deployed.
- **Movement, town and buff changes:** `Movement`, `Town`, Aftermath / Mjollnir Haste TP sets and similar only change on your next action.

Typing any profile command (for example `/pupdebug`) counts as an action and makes the gear check run once.

Whether these features can be used may need approval from the HorizonXI team.
