PUP LuAshitacast profile - Command reference
=============================================

Puppetmaster profile for LuAshitacast (Ashita v4), built on Rag's
LuAshitacast (RAGS) v320 common files. Level-75 era (Horizon).

Where the files go:
    Ashita\config\addons\luashitacast\<CharacterName_ID>\PUP.lua
        your gear sets and settings (from this repo)
    Ashita\config\addons\luashitacast\common\gcinclude-pup.lua
        PUP addendum, all PUP-specific logic (from this repo)

Also needed in that same luashitacast\common folder, from Rag's
LuAshitacast v320 (https://github.com/yzyii/luashitacast), not included
in this repo:
    gcmelee.lua
    gcmage.lua
    gcinclude-rag.lua
    gcdisplay-rag.lua

All commands below are typed in game as shown (for example /pupmode).
They are aliases for /lac fwd <command>.


---------------------------------------------
1. PUP commands (added by gcinclude-pup.lua)
---------------------------------------------

/pupmode
    Cycles the automaton mode: Tank -> Melee -> Ranged -> Mage -> Heals.
    While the automaton is engaged, the set with the same name
    (Tank, Melee, Ranged, Mage, Heals) is worn on top of your other gear.
    Pet magic legs also follow it:
        Heals -> Pet_Magic + Pet_Magic_Cure
        Mage  -> Pet_Magic + Pet_Magic_Black

/pupmode <name>
    Jumps straight to a mode, e.g. /pupmode ranged

/tp
    Cycles LowAcc -> Hybrid -> HighAcc. This replaces Rag's two-step /tp
    and the old /meleeset.
    - While YOU are engaged: TP_LowAcc is always the base, then
          Hybrid  adds TP_Hybrid
          HighAcc adds TP_HighAcc
    - While only the automaton is engaged:
          Pet_Only_Tp_LowAcc / Pet_Only_Tp_Hybrid / Pet_Only_Tp_HighAcc
    - Weaponskills: WS always, plus WS_HighAcc in HighAcc.
    /tpset does the same thing.

/petdt
    Toggles the Pet_Dt set on top of everything else.

/petws
    Toggles automatic pet weaponskill gear (Pet_WS for melee
    weaponskills, Pet_RNGWS for ranged ones). On by default.

/staff
    Toggles weapon swaps while casting. Off by default: your Main and
    Sub stay put during precast and midcast so you do not lose TP.
    Turn it on to let a staff in your own spell sets (e.g. a Light Staff
    in Cure) or Rag's elemental staves go on.
    Starting value: allow_staff_swaps in PUP.lua settings.

/pupdebug
    Prints PupMode, IdleSet, pet, Lock, the pet magic legs, your Status,
    SubJob and the Resting_MPSub staff to the chat log.


---------------------------------------------
2. Automatic PUP behaviour (no command)
---------------------------------------------

Maneuvers
    Using a maneuver puts on the set for that element, before the
    maneuver is sent, and holds it for maneuver_lock_seconds (0.5) after
    it finishes:
        Fire_Maneuver (STR)    Ice_Maneuver (INT)    Wind_Maneuver (AGI)
        Earth_Maneuver (VIT)   Thunder_Maneuver (DEX) Water_Maneuver (MND)
        Light_Maneuver (CHR)   Dark_Maneuver (MP)
    To wear the set even earlier, use a macro:
        /lac set Fire_Maneuver 3
        /wait 1
        /ja "Fire Maneuver" <me>

Other job abilities
    Activate / Deus Ex Automata -> Activate
    Repair / Maintenance        -> Repair
    Overdrive                   -> Overdrive (also kept on for the whole
                                   time the Overdrive buff is up)
    Ventriloquy                 -> Ventriloquy
    Role Reversal               -> Role_Reversal

Resting on an MP subjob
    On a DRK, WHM, RDM, BLM or BLU subjob, Resting_MPSub (your Dark Staff)
    goes on over Rag's Resting set, after the same 16 second wait.

/DRK extras (Rag v320)
    Weapon Bash -> WeaponBash. Stun with /mode Accuracy -> StunACC.

Subjob TP pieces
    While engaged: TP_DRG on /DRG, TP_THF on /THF.

Automaton out
    Idle_Pet is layered over Idle while the automaton is out and idle.


---------------------------------------------
3. Rag's commands (gcmelee / gcinclude-rag)
---------------------------------------------

Idle overrides. Each one switches your idle set to that set; type the
same command again to go back to the previous one.
    /idle                     swap Idle <-> IdleALT (Normal / Alternate)
    /dt  /pdt                 DT
    /mdt                      MDT
    /fireres  /fres           FireRes
    /iceres  /ires  /bres     IceRes
    /lightningres  /lres  /tres   LightningRes
    /earthres  /eres  /sres   EarthRes
    /windres  /wires  /ares   WindRes
    /waterres  /wares  /wres  WaterRes
    /evasion  /eva            Evasion
    /override  /or            Override

/kite
    Toggles the Movement set on.

/lock
    Toggles an equipment lock (/lac disable all / enable all), so nothing
    swaps until you turn it off.

/lockset <1-3>
    Equips LockSet1, LockSet2 or LockSet3 and locks your gear.
    Use /lock to unlock.

/weapon  /wl
    Cycles your weapon loadout 1 -> 2 -> 3 (Weapon_Loadout_1-3).
    /wl 2 jumps straight to loadout 2.

/dps
    Toggles DPS mode (on by default). Off stops TP sets and weapon
    loadouts from going on when you engage.

/lag
    Toggles lag mode. When on, midcast delays are turned off (for when
    your connection is laggy). Toggles both melee and magic sides.

/sethp <number>
    The HP below which regen gear goes on while idle. Overrides
    max_hp_in_idle_with_regen_gear_equipped in PUP.lua.
/addhp <number>
    Extra HP added to that threshold.
/resethp
    Clears /sethp and /addhp.

/warpme
    Equips your Warp Cudgel and uses it after 31 seconds.

/reraise
    Equips your Reraise Hairpin and uses it after 31 seconds.

/horizonmode
    Re-runs your normal gear check once. It does not turn LuAshitacast's
    Horizon Mode on or off.


---------------------------------------------
4. Rag's magic commands (gcmage), for your subjob spells
---------------------------------------------

/mode
    Cycles magic mode Potency <-> Accuracy. Accuracy uses
    EnfeeblingACC and the accuracy versions of gcmage's sets.

/setmp <number>
    Your max MP, used by gcmage for MP-based gear checks. Overrides the
    ninSJMaxMP / whmSJMaxMP / blmSJMaxMP / rdmSJMaxMP / drkSJMaxMP settings.
/addmp <number>
    Extra MP added to that value.
/resetmp
    Clears /setmp and /addmp.


---------------------------------------------
5. Useful LuAshitacast built-ins
---------------------------------------------

/lac reload            reload the profile after copying new files
/lac set <set> <secs>  equip a set and hold it for that many seconds
/lac disable all       stop all gear swaps (/lac enable all to undo)


---------------------------------------------
6. What Horizon Mode turns off
---------------------------------------------

With LuAshitacast's Horizon Mode on, your normal gear check runs only
once after each of your own actions (ability, spell, weaponskill, ranged
attack, item or /lac fwd command), not continuously. Action gear (job
abilities, maneuvers, precast, midcast, weaponskills) works as normal.
Anything that waits for something else does not update until your next
action:

- Pet weaponskill gear: Pet_WS / Pet_RNGWS do not go on when the
  automaton reaches TP or starts a weaponskill.
- Pet magic by spell type: the profile cannot react to the automaton's
  spell, which is why pet magic legs follow /pupmode (Heals / Mage).
- Automaton engaging, disengaging or being deployed: Pet_Only_Tp_*,
  the /pupmode sets and Idle_Pet do not switch by themselves.
- Resting: Rag's Resting set and Resting_MPSub (Dark Staff) wait
  16 seconds after you sit, so they will not go on by themselves.
- After a maneuver: once the 0.5 second hold ends, normal gear comes
  back on your next action.
- Overdrive ending: the Overdrive set stays on until your next action.
- Movement, town and buff changes (Movement, Town, Aftermath /
  Mjollnir Haste TP sets) only change on your next action.

Typing any profile command (e.g. /pupdebug) counts as an action and runs
the gear check once.
