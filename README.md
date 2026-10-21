# FFXI Puppetmaster LuAshitacast profile

Puppetmaster job profile for LuAshitacast (Ashita v4), built on Rag's LuAshitacast (RAGS) v310 common files. Level-75 era content (Horizon).

## Install

Copy into `Ashita/config/addons/luashitacast/<CharacterName_ID>/`:

```
PUP.lua
common/gcinclude-pup.lua   PUP addendum (all PUP-specific logic)
```

It also needs Rag's v310 common files in the same `common` folder. They are not in this repo: get them from RAGS (link below).

```
common/gcinclude-rag.lua
common/gcmelee.lua
common/gcmage.lua
common/gcdisplay-rag.lua
```

## Rules

- Never edit the four RAGS files (`gcinclude-rag.lua`, `gcmelee.lua`, `gcmage.lua`, `gcdisplay-rag.lua`). Extra logic goes in `common/gcinclude-pup.lua`.
- RAGS upstream: https://github.com/yzyii/luashitacast (upstream is now v320; this profile targets v310).

## Commands (from the addendum)

- `/pupmode` cycles the automaton mode; pet magic legs follow it (Heals -> `Pet_Magic_Cure`, Mage -> `Pet_Magic_Black`).
- `/tp` cycles LowAcc -> Hybrid -> HighAcc (TP, Pet_Only_Tp and WS sets follow it).
- `/pupdebug` prints Status / SubJob / staff state.
