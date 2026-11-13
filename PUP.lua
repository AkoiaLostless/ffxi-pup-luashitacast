local profile = {}

--[[
Puppetmaster profile for Rag's LuAshitacast common files (version 320).

Install:
    PUP.lua                    -> your character folder (replaces your old PUP.lua)
    common\gcinclude-pup.lua   -> luashitacast\common (not the character folder), next to Rag's files

Rag's 4 common files (gcmelee.lua, gcmage.lua, gcinclude-rag.lua, gcdisplay-rag.lua) are not changed.
gcinclude-pup.lua loads both gcmelee and gcmage and keeps them from conflicting. This file only holds your gear and settings.
The old common\gcinclude.lua (GetAwayCoxn style) is not used by this profile.

Rag's melee commands all work: /dt /mdt /eva /fres etc. (idle overrides), /idle, /or, /kite, /lock, /lockset #, /tp, /wl #, /dps,
    /lag, /sethp, /addhp, /resethp, /warpme, /reraise, /horizonmode
Rag's mage commands for PUP: /mode (magic Potency / Accuracy), /addmp, /setmp, /resetmp

PUP commands (carried over from your old PUP.lua):
    /pupmode          cycle the automaton mode: Tank -> Melee -> Ranged -> Mage -> Heals
    /pupmode <name>   jump straight to a mode, e.g. /pupmode ranged
    /tp               cycle LowAcc -> Hybrid -> HighAcc (replaces Rag's two-step /tp and the old /meleeset; drives TP_ and Pet_Only_Tp_ sets)
    /petdt            toggle the Pet_Dt set on top of everything else
    /petws            toggle automatic pet weaponskill gear swaps
    /staff            toggle gcmage elemental staff swaps while casting (shows as Staff on the display)
    /pupdebug         print PupMode, IdleSet, pet, Lock and the pet magic legs, your status, subjob and Resting_MPSub staff to the chat log
]]

local settings = {
    fastCastValue = 0.00, -- 0% from gear listed in Precast set
    snapShotValue = 0.00, -- 0% from gear listed in Preshot set

    -- The following is provided as a convenient saved setting over using the /sethp command. HP will fluctuate with SJ and usage of the command for this is required.
    max_hp_in_idle_with_regen_gear_equipped = 0, -- Set this to 0 if you do not wish to ever use regen gear.

    -- Your max MP per subjob, used by gcmage for water ring / uggalepih / ice ring checks, and for IdleMaxMP on RDM / WHM / BLM / BLU.
    -- Leave nil if you don't care. /setmp overrides these.
    ninSJMaxMP = nil,
    whmSJMaxMP = nil,
    blmSJMaxMP = nil,
    rdmSJMaxMP = nil,
    drkSJMaxMP = nil,
    bluSJMaxMP = nil, -- Only used for IdleMaxMP (gcmage has no BLU checks)

    -- Automaton TP at which Pet_WS / Pet_RNGWS goes on. Automatons weaponskill at 1000 TP, so swapping slightly early makes sure the gear is on in time.
    pet_ws_tp_threshold = 950,

    -- gcmage swaps in your elemental staves (set up in gcmage.lua) when you cast. On PUP that would take off your weapon and lose TP,
    -- so it is blocked by default. This is only the starting value on load; use /staff in game to turn it on and off.
    allow_staff_swaps = false,
}

-- Comment out the equipment within these sets if you do not have them or do not wish to use them
local warlocks_mantle = { -- Don't add 2% to fastCastValue for this as it is SJ dependant
    -- Back = 'Warlock\'s Mantle',
}

local sets = {
    Idle = {
        Main = '',
        Range = '',
        Ammo = '',
        Head = '',
        Neck = '',
        Ear1 = '',
        Ear2 = '',
        Body = '',
        Hands = '',
        Ring1 = '',
        Ring2 = '',
        Back = '',
        Waist = '',
        Legs = '',
        Feet = '',
    },
    IdleALT = {},
    Resting = {},
    Resting_MPSub = { -- Goes on automatically over Resting when you rest on a DRK, WHM, RDM, BLM or BLU subjob. Put your Dark Staff here.
        Main = 'Pluto\'s Staff',
        -- Sub = 'Bugard Strap +1',
    },
    Town = {},
    Movement = {},
    Movement_TP = {},

    DT = {}, -- Your old Dt set. Use /dt to lock it on (was /dt + DTset toggle before)
    MDT = {},
    FireRes = {},
    IceRes = {},
    LightningRes = {},
    LightningRes_NoBarthunder = {},
    LightningRes_WithBarthunderCarol = {},
    EarthRes = {},
    WindRes = {},
    WaterRes = {},
    Evasion = {},
    Override = { -- An additional override set explicitly to be used for sets such as HELM or any other special sets. n.b. Any unused Resist or Evasion set can be used similarly.
    },

    Precast = {},
    IdleMaxMP = {}, -- MP+ gear, RDM / WHM / BLM / BLU subjob only: worn while idle with full MP (needs /setmp or the *SJMaxMP settings above) and while resting from 95% MP
    SIRD = { -- Override sets (Resistance / Evasion) take precedence if in use.
    },
    Haste = {}, -- Utsusemi and other no-potency spells
    SIRD_NIN = {},

    -- Your TP sets, used whenever YOU are engaged. TP_LowAcc is always the base; /tp picks what goes on top.
    TP_LowAcc = {},
    TP_Aftermath = {},
    TP_Mjollnir_Haste = {},
    TP_Hybrid = {}, -- On top of TP_LowAcc when /tp is Hybrid
    TP_HighAcc = {}, -- On top of TP_LowAcc when /tp is HighAcc

    -- Subjob specific, layered on top while you are engaged
    TP_DRG = {
        -- Ear1 = 'Wyvern Earring',
    },
    Jump = {}, -- /DRG: worn when you use Jump
    HighJump = {}, -- /DRG: layered on Jump when you use High Jump
    TP_THF = {
        -- Ear2 = 'Pilferer\'s Earring',
    },

    Weapon_Loadout_1 = {},
    Weapon_Loadout_2 = {},
    Weapon_Loadout_3 = {},

    --[[ Automaton sets, in the order they go on (later ones layer on top) ]]

    -- Automaton out, you and it both idle
    Idle_Pet = {}, -- Layered over Idle

    -- Automaton engaged, you not engaged (/tp picks one). When you are engaged too, your TP_ sets above are used instead.
    Pet_Only_Tp_LowAcc = {},
    Pet_Only_Tp_Hybrid = {},
    Pet_Only_Tp_HighAcc = {},

    -- /pupmode sets: worn the whole time the automaton is out (idle or engaged), layered over Idle_Pet / Pet_Only_Tp_ / your TP sets.
    -- Put pet HP/MP+ pieces here so its max HP/MP is already up before it engages. Can be empty but do not delete.
    Tank = {},
    Melee = {},
    Ranged = {},
    Mage = {},
    Heals = {},

    -- Automaton weaponskills: while it is engaged and above pet_ws_tp_threshold TP, or doing the weaponskill. Toggle with /petws.
    Pet_WS = {}, -- Melee weaponskills (/pupmode Melee or Tank)
    Pet_RNGWS = {}, -- Ranged weaponskills (/pupmode Ranged)

    -- Pet magic: worn the whole time in /pupmode Heals or Mage (works with Horizon Mode)
    Pet_Magic = {},
    Pet_Magic_Cure = { -- Layered on Pet_Magic in /pupmode Heals
        -- Legs = '',
    },
    Pet_Magic_Black = { -- Layered on Pet_Magic in /pupmode Mage
        -- Legs = '',
    },

    -- Pet casting: worn only while the automaton is casting a spell, in any /pupmode, layered over Pet_Magic.
    -- DISABLED BY HORIZON MODE: LuAshitacast's Horizon Mode never checks gear when the automaton starts casting, so these only work on servers without it.
    Pet_Casting = {}, -- Every spell
    Pet_Casting_Cure = { -- Layered on Pet_Casting for healing spells
        -- Legs = '',
    },
    Pet_Casting_Black = { -- Layered on Pet_Casting for every other spell
        -- Legs = '',
    },

    -- Toggled with /petdt while the automaton is out; goes on over every automaton set above
    Pet_Dt = {},

    --[[ Your weaponskills ]]
    WS = {}, -- Every weaponskill
    WS_HighAcc = {}, -- Layered on WS when /tp is HighAcc

    --[[ Job abilities ]]
    Activate = {}, -- Also used for Deus Ex Automata
    Repair = {
        -- Ammo = 'Automat. Oil +3', -- Repair needs oil in the ammo slot
    },
    Maintenance = {
        Ammo = 'Automat. Oil +2', -- Maintenance uses the oil in the ammo slot for its effect
    },
    -- Worn only while you use the maneuver, not for the length of the buff
    Fire_Maneuver = {}, -- STR
    Ice_Maneuver = {}, -- INT
    Wind_Maneuver = {}, -- AGI
    Earth_Maneuver = {}, -- VIT
    Thunder_Maneuver = {}, -- DEX
    Water_Maneuver = {}, -- MND
    Light_Maneuver = {}, -- CHR
    Dark_Maneuver = {}, -- Scales with MP
    Overdrive = { -- This set is forced on for the ability AND stays on for the whole duration of Overdrive, dont change the body out because of that
    },
    Ventriloquy = {},
    Role_Reversal = {},
    WeaponBash = {}, -- Weapon Bash on /DRK

    --[[ Your own spellcasting (subjob) ]]
    -- gcmage picks these for your subjob spells. Any gcmage set not listed here (Nuke, Dark, Stun, Banish, etc.) is added empty automatically,
    -- so you can add any set name from gcmage.lua here if you want to use it.
    ConserveMP = {},
    Cure = {},
    Cursna = {},
    Enhancing = {},
    Phalanx = {},
    Stoneskin = {},
    Enfeebling = {},
    EnfeeblingMND = {},
    EnfeeblingINT = {},
    EnfeeblingACC = {}, -- Used with /mode Accuracy and for accuracy spells (Sleep, Bind, Gravity, Silence, ...)
    Spikes = {},
    StunACC = {}, -- Stun on /DRK with /mode Accuracy

    Preshot = {}, -- This set is pointless until ToAU+ when Snapshot on equipment is available
    Midshot = {}, -- Your ranged attack set (used with Preshot)

    LockSet1 = {},
    LockSet2 = {},
    LockSet3 = {},

    VileElixir = {},
}

profile.SetMacroBook = function()
    -- AshitaCore:GetChatManager():QueueCommand(1, '/macro book 9')
    -- AshitaCore:GetChatManager():QueueCommand(1, '/macro set 1')
end

profile.Packer = {
    {Name = 'Automat. Oil +3', Quantity = 'all'},
}

--[[
--------------------------------
Everything below can be ignored.
--------------------------------
]]

gcpup = gFunc.LoadFile('common\\gcinclude-pup.lua')

sets.warlocks_mantle = warlocks_mantle
-- How long the Fire_Maneuver ... Dark_Maneuver set stays on after the maneuver finishes, in seconds
settings.maneuver_lock_seconds = 0.5
gcpup.SetSettings(settings)
profile.Sets = gcpup.AppendSets(sets)

profile.HandleAbility = function()
    gcpup.DoAbility(sets)
end

profile.HandleItem = function()
    gcpup.DoItem(sets)
end

profile.HandlePreshot = function()
    gcpup.DoPreshot(sets)
end

profile.HandleMidshot = function()
    gcpup.DoMidshot(sets)
end

profile.HandleWeaponskill = function()
    gcpup.DoWS(sets)
end

profile.OnLoad = function()
    gcpup.Load()
    profile.SetMacroBook()
end

profile.OnUnload = function()
    gcpup.Unload()
end

profile.HandleCommand = function(args)
    gcpup.DoCommands(args, sets)

    if (args[1] == 'horizonmode') then
        profile.HandleDefault()
    end
end

profile.HandleDefault = function()
    gcpup.DoDefault(sets)
end

profile.HandlePrecast = function()
    gcpup.DoPrecast(sets)
end

profile.HandleMidcast = function()
    gcpup.DoMidcast(sets)
end

return profile
