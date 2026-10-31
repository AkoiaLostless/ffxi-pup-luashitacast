--[[
gcinclude-pup.lua - Puppetmaster addendum for Rag's LuAshitacast common files (version 320).

This file sits in common\ next to Rag's files and does NOT change any of them:
    gcmelee.lua, gcmage.lua, gcinclude-rag.lua, gcdisplay-rag.lua

It loads BOTH gcmelee and gcmage and decides which one handles each event so they never fight:
    Idle / TP / overrides / movement / town   -> gcmelee (DoDefault, DoDefaultOverride)
    Job abilities, items, weaponskills, ranged -> gcmelee
    Spell precast + midcast delay / interim set -> gcmage (DoPrecast)
    Spell midcast gear (cure, enhancing, enfeebling, elemental, dark, divine, staves, obis) -> gcmage (DoMidcast)
    Sets: gcmelee.AppendSets + gcmage.AppendSets (both feed gcinclude-rag's AppendSets)

Conflicts between the two and how they are settled here:
    Only gcmelee.Load is called. gcmage.Load would load gcinclude-rag a second time (stylist, aliases, display) and
        would create its own 'TP' cycle that fights gcmelee's /tp. gcmage only needs its 'Mode' cycle, which is created here.
    /tp /tpset               -> this file's TPSet cycle (LowAcc / Hybrid / HighAcc), which flips gcmelee's LowAcc / HighAcc when needed
    /weapon /wl              -> gcmelee only (shared 'Weapon Loadout' cycle is created once by gcmelee)
    /mode                    -> gcmage magic Mode (Potency / Accuracy). Use /tp for LowAcc / Hybrid / HighAcc.
    /lag                     -> toggled in BOTH so melee and magic midcast delays stay in sync
    /addmp /setmp /resetmp   -> gcmage only
    Job abilities            -> gcmelee.DoAbility only (gcmage.DoAbility would fire /displayhead a second time)

There is nothing to edit in this file. All gear and settings live in your PUP.lua.
]]

local gcpup = {}

gcmage = gFunc.LoadFile('common\\gcmage.lua')
gcmelee = gFunc.LoadFile('common\\gcmelee.lua')
-- Both files load gcinclude-rag.lua (and through it gcdisplay-rag.lua). Every common file reads them through the
-- globals gcinclude / gcdisplay at call time, and no cycles or toggles exist yet, so everyone shares the last loaded copy.

local VERSION = 320

local settings = {
    pet_ws_tp_threshold = 950,
    allow_staff_swaps = false,
    maneuver_lock_seconds = 0.5,
    max_hp_in_idle_with_regen_gear_equipped = 0,
    fastCastValue = 0.00,
    snapShotValue = 0.00,
    ninSJMaxMP = nil,
    whmSJMaxMP = nil,
    blmSJMaxMP = nil,
    rdmSJMaxMP = nil,
    drkSJMaxMP = nil,
}

-- Subjobs that give you MP. Only these get Resting_MPSub while resting.
local MPSubjobs = T{ 'DRK','WHM','RDM','BLM','BLU' }
local restStart = nil
-- The maneuver set waiting to be held once the maneuver finishes (see DoAbility / DoDefault)
local pendingManeuverSet = nil
local pendingManeuverExpires = 0

-- Weapon slots a gear set can claim back from Rag's weapon loadout (see DoDefault)
local WeaponSlots = T{ 'Main','Sub','Range' }

local PupModeTable = {
    [1] = 'Tank',
    [2] = 'Melee',
    [3] = 'Ranged',
    [4] = 'Mage',
    [5] = 'Heals',
}
-- Lets /pupmode <name> jump straight to a mode. The names are the same five modes as above, typed in lowercase.
local PupModeIndex = {
    ['tank'] = 1,
    ['melee'] = 2,
    ['ranged'] = 3,
    ['mage'] = 4,
    ['heals'] = 5,
}

-- Commands this file owns. 'mode' and 'lag' are already aliased by gcmelee so they are not repeated here.
local PupAliases = T{ 'pupmode','petdt','petws','staff','pupdebug' }

-- PUP's /tp cycle. Rag's gcmelee only has LowAcc / HighAcc, so Hybrid is added here on top of it.
-- Hybrid runs Rag's LowAcc sets and adds TP_Hybrid; HighAcc runs Rag's HighAcc (TP_HighAcc, WS_HighAcc).
local TPSetTable = { [1] = 'LowAcc', [2] = 'Hybrid', [3] = 'HighAcc' }
local MageAliases = T{ 'addmp','setmp','resetmp' }
local MageCommands = T{ 'addmp','setmp','resetmp','mode' }

local AutomatonMeleeWS = T{ 'Slapstick','Knockout','Chimera Ripper','String Clipper','Cannibal Blade','Bone Crusher','Magic Mortar' }
local AutomatonRangedWS = T{ 'Arcuballista','Daze','Armor Piercer' }

-- Idle sets where pet weaponskill swaps are allowed. Any override (/dt, /mdt, resists, evasion, override) takes priority over pet WS gear.
local PetWSIdleSets = T{ 'Normal','Alternate','LowAcc','HighAcc' }

-- Every set name gcmelee / gcmage / this file can ask for. Any your PUP.lua leaves out is added empty so nothing errors.
local RequiredSets = T{
    'Idle','IdleALT','IdleMaxMP','Resting','Town','Movement','Movement_TP',
    'DT','DTNight','MDT','FireRes','IceRes','LightningRes','LightningRes_NoBarthunder','LightningRes_WithBarthunderCarol',
    'EarthRes','WindRes','WaterRes','Evasion','Override',
    'Precast','SIRD','SIRD_NIN','Haste','ConserveMP',
    'TP_LowAcc','TP_Aftermath','TP_Mjollnir_Haste','TP_HighAcc','TP_DRG','Jump','HighJump','TP_THF',
    'Weapon_Loadout_1','Weapon_Loadout_2','Weapon_Loadout_3',
    'WS','WS_HighAcc',
    'Idle_Pet','Pet_Dt','Pet_Only_Tp_LowAcc','Pet_Only_Tp_Hybrid','Pet_Only_Tp_HighAcc','TP_Hybrid',
    'Tank','Melee','Ranged','Mage','Heals','Pet_WS','Pet_RNGWS','Pet_Magic','Pet_Magic_Cure','Pet_Magic_Black','Pet_Casting','Pet_Casting_Cure','Pet_Casting_Black',
    'Activate','Repair','WeaponBash',
    'Fire_Maneuver','Ice_Maneuver','Wind_Maneuver','Earth_Maneuver','Thunder_Maneuver','Water_Maneuver','Light_Maneuver','Dark_Maneuver',
    'Overdrive','Ventriloquy','Role_Reversal',
    'Cure','Cure5','Cursna','Enhancing','Phalanx','PhalanxExtra','Stoneskin','StoneskinExtra','Spikes',
    'Enfeebling','EnfeeblingMND','EnfeeblingINT','EnfeeblingACC',
    'Nuke','NukeHNM','NukeDOT','NukeExtra','NukeACC','MB','MBHNM',
    'Dark','Stun','StunACC','Banish','BanishExtra','Support_Flash','Hate','Hate_Flash',
    'Cheat_HPUp','Cheat_C3HPDown','Cheat_C4HPDown','Yellow','YellowHNM',
    'Preshot','Midshot',
    'LockSet1','LockSet2','LockSet3','VileElixir','Resting_MPSub',
}

function gcpup.SetSettings(userSettings)
    for k, v in pairs(userSettings) do
        settings[k] = v
    end
end

function gcpup.AppendSets(sets)
    for _, name in ipairs(RequiredSets) do
        if (sets[name] == nil) then
            sets[name] = {}
        end
    end

    sets = gcmelee.AppendSets(sets)
    sets = gcmage.AppendSets(sets)

    return sets
end

function gcpup.Load()
    gcinclude.SetAlias(PupAliases)
    gcinclude.SetAlias(MageAliases)
    gcdisplay.CreateCycle('PupMode', PupModeTable)
    gcdisplay.CreateCycle('TPSet', TPSetTable)
    gcdisplay.CreateCycle('Mode', {[1] = 'Potency', [2] = 'Accuracy'})
    gcdisplay.CreateToggle('PetDT', false)
    gcdisplay.CreateToggle('PetWS', true)
    gcdisplay.CreateToggle('Staff', settings.allow_staff_swaps == true)

    gcmelee.Load(VERSION)

    if (gcmage.GetVer() ~= VERSION or gcinclude.GetVer() ~= VERSION) then
        print(chat.header('GCPup'):append(chat.message('Version mismatch found. gcinclude-pup expects version ' .. VERSION .. ' of gcmage / gcmelee / gcinclude-rag.')))
    end
end

function gcpup.Unload()
    gcmelee.Unload()
    gcinclude.ClearAlias(PupAliases)
    gcinclude.ClearAlias(MageAliases)
end

function gcpup.DoCommands(args, sets)
    local cmd = args[1]

    if (cmd == 'pupmode') then
        local index = (args[2] ~= nil) and PupModeIndex[string.lower(args[2])] or nil
        if (index ~= nil) then
            gcdisplay.SetCycleIndex('PupMode', index)
        else
            gcdisplay.AdvanceCycle('PupMode')
        end
        gcinclude.Message('PupMode', gcdisplay.GetCycle('PupMode'))
    elseif (cmd == 'tp' or cmd == 'tpset') then
        -- Cycle LowAcc -> Hybrid -> HighAcc, and flip Rag's own LowAcc / HighAcc only when it needs to change
        gcdisplay.AdvanceCycle('TPSet')
        local tpSet = gcdisplay.GetCycle('TPSet')
        local ragSet = (tpSet == 'HighAcc') and 'HighAcc' or 'LowAcc'
        if (gcmelee.GetAccuracyMode() ~= ragSet) then
            gcmelee.DoCommands({ 'tp' })
        end
        if (tpSet == 'Hybrid') then
            gcinclude.Message('TP Set', tpSet)
        end
    elseif (cmd == 'petdt') then
        gcdisplay.AdvanceToggle('PetDT')
        gcinclude.Message('PetDT', gcdisplay.GetToggle('PetDT'))
    elseif (cmd == 'pupdebug') then
        local pet = gData.GetPet()
        local function legs(set)
            return (set ~= nil and set.Legs ~= nil) and tostring(set.Legs) or 'none'
        end
        print(chat.header('GCPup'):append(chat.message('PupMode=' .. gcdisplay.GetCycle('PupMode') .. '  IdleSet=' .. gcdisplay.IdleSet
            .. '  Pet=' .. ((pet ~= nil) and tostring(pet.Name) or 'none') .. '  Lock=' .. tostring(gcdisplay.GetToggle('Lock')))))
        print(chat.header('GCPup'):append(chat.message('Pet_Magic_Cure Legs=' .. legs(sets.Pet_Magic_Cure) .. '  Pet_Magic_Black Legs=' .. legs(sets.Pet_Magic_Black))))
        local player = gData.GetPlayer()
        local restMain = (sets.Resting_MPSub ~= nil and sets.Resting_MPSub.Main ~= nil) and tostring(sets.Resting_MPSub.Main) or 'none'
        print(chat.header('GCPup'):append(chat.message('Status=' .. tostring(player.Status) .. '  SubJob=' .. tostring(player.SubJob) .. '  Resting_MPSub Main=' .. restMain)))
    elseif (cmd == 'staff') then
        gcdisplay.AdvanceToggle('Staff')
        gcinclude.Message('Staff Swaps', gcdisplay.GetToggle('Staff'))
    elseif (cmd == 'petws') then
        gcdisplay.AdvanceToggle('PetWS')
        gcinclude.Message('PetWS', gcdisplay.GetToggle('PetWS'))
    elseif (MageCommands:contains(cmd)) then
        gcmage.DoCommands(args, sets)
    elseif (cmd == 'lag') then
        gcmelee.DoCommands(args)
        gcmage.DoCommands(args, sets)
    else
        -- Everything else (weapon, wl, dps, sethp, idle overrides, kite, lock, lockset, warpme, reraise, horizonmode)
        -- goes through gcmelee, which passes anything it does not own on to gcinclude-rag.
        gcmelee.DoCommands(args)
    end
end

-- LuAshitacast's gData.GetPetAction() gives the automaton's current action with Name, ActionType ('Spell', 'Ability' or 'MobSkill'),
-- and for spells also Skill (e.g. 'Healing Magic', 'Elemental Magic') and Type ('White Magic' or 'Black Magic').
local function GetPetAction()
    local petAction = gData.GetPetAction()
    if (type(petAction) == 'table') then
        return petAction
    elseif (petAction ~= nil) then
        return { Name = petAction }
    end
    return nil
end

function gcpup.DoDefault(sets)
    -- Rag's gcmelee puts your Weapon_Loadout on after the normal gear sets, so a weapon you list in a set
    -- (Idle, TP, Pet_Only_Tp, /pupmode sets, ...) gets replaced by the loadout. To let the set win, every
    -- Main / Sub / Range a set lists before the loadout is remembered and put back on right after it.
    local setWeapons = {}
    local realEquipSet = gFunc.EquipSet
    gFunc.EquipSet = function(set)
        local name = (type(set) == 'string') and set or nil
        local t = (name ~= nil) and sets[name] or set
        if (type(t) == 'table' and not (name ~= nil and string.startswith(name, 'Weapon_Loadout_'))) then
            for _, slot in ipairs(WeaponSlots) do
                local item = t[slot]
                -- An empty '' or 'ignore' in a set means no weapon there, so the loadout's stays on
                if (item ~= nil and item ~= '' and item ~= 'ignore') then
                    setWeapons[slot] = item
                end
            end
        end
        return realEquipSet(set)
    end
    local ok, err = pcall(function()
        gcmelee.DoDefault(settings.max_hp_in_idle_with_regen_gear_equipped)
        gcpup.DoDefaultLayers(sets)
        gcmelee.DoDefaultOverride()
    end)
    gFunc.EquipSet = realEquipSet
    if (not ok) then
        error(err, 0)
    end
    if (next(setWeapons) ~= nil) then
        gFunc.EquipSet(setWeapons)
    end

    gcpup.DoDefaultAfterOverride(sets)
end

function gcpup.DoDefaultLayers(sets)
    local player = gData.GetPlayer()
    local pet = gData.GetPet()
    local pupMode = gcdisplay.GetCycle('PupMode')
    local tpSet = gcdisplay.GetCycle('TPSet')

    if (player.Status == 'Engaged') then
        if (tpSet == 'Hybrid') then
            gFunc.EquipSet(sets.TP_Hybrid)
        end
        if (player.SubJob == 'DRG') then
            gFunc.EquipSet(sets.TP_DRG)
        elseif (player.SubJob == 'THF') then
            gFunc.EquipSet(sets.TP_THF)
        end
    end

    if (pet ~= nil) then
        if (pet.Status == 'Engaged') then
            if (player.Status ~= 'Engaged') then
                gFunc.EquipSet(sets['Pet_Only_Tp_' .. tpSet])
            end
            gFunc.EquipSet(sets[pupMode])
        elseif (player.Status == 'Idle') then
            gFunc.EquipSet(sets.Idle_Pet)
        end
    end
end

function gcpup.DoDefaultAfterOverride(sets)
    local player = gData.GetPlayer()
    local pet = gData.GetPet()
    local pupMode = gcdisplay.GetCycle('PupMode')

    if (pet ~= nil and pet.Status == 'Engaged' and PetWSIdleSets:contains(gcdisplay.IdleSet)) then
        local petAction = GetPetAction()
        if (petAction ~= nil) then
            if (AutomatonRangedWS:contains(petAction.Name)) then
                gFunc.EquipSet(sets.Pet_RNGWS)
            elseif (AutomatonMeleeWS:contains(petAction.Name)) then
                gFunc.EquipSet(sets.Pet_WS)
            end
        elseif (gcdisplay.GetToggle('PetWS') and pet.TP > settings.pet_ws_tp_threshold) then
            if (pupMode == 'Ranged') then
                gFunc.EquipSet(sets.Pet_RNGWS)
            elseif (pupMode == 'Melee' or pupMode == 'Tank') then
                gFunc.EquipSet(sets.Pet_WS)
            end
        end
    end

    -- Horizon Mode only runs this once after one of YOUR actions, never when the automaton starts a spell,
    -- so the pet magic legs follow /pupmode: Heals wears the cure legs, Mage wears the black magic legs.
    -- This does not wait for the automaton to be out: after Activate, Horizon Mode checks gear before the automaton
    -- has spawned and then not again until your next action, so a pet check here would leave the legs off.
    if (PetWSIdleSets:contains(gcdisplay.IdleSet)) then
        if (pupMode == 'Heals') then
            gFunc.EquipSet(sets.Pet_Magic)
            gFunc.EquipSet(sets.Pet_Magic_Cure)
        elseif (pupMode == 'Mage') then
            gFunc.EquipSet(sets.Pet_Magic)
            gFunc.EquipSet(sets.Pet_Magic_Black)
        end
    end

    -- Pet_Casting: only while the automaton is casting. Horizon Mode never runs this check when the automaton
    -- starts a spell, so it is switched off whenever LuAshitacast's Horizon Mode checkbox is on.
    if (not gSettings.HorizonMode and pet ~= nil and PetWSIdleSets:contains(gcdisplay.IdleSet)) then
        local petAction = GetPetAction()
        if (petAction ~= nil and petAction.ActionType == 'Spell') then
            -- Same split as /pupmode Heals and Mage: healing spells get Pet_Casting_Cure, everything else Pet_Casting_Black
            gFunc.EquipSet(sets.Pet_Casting)
            if (petAction.Skill == 'Healing Magic' or string.match(petAction.Name, '^Cur')) then
                gFunc.EquipSet(sets.Pet_Casting_Cure)
            else
                gFunc.EquipSet(sets.Pet_Casting_Black)
            end
        end
    end

    if (pet ~= nil and gcdisplay.GetToggle('PetDT')) then
        gFunc.EquipSet(sets.Pet_Dt)
    end

    if (gData.GetBuffCount('Overdrive') > 0) then
        gFunc.EquipSet(sets.Overdrive)
    end

    gFunc.EquipSet(gcinclude.BuildLockableSet(gData.GetEquipment()))

    -- Alternate resting set: on an MP subjob, Resting_MPSub (Dark Staff) goes on over Rag's Resting set automatically.
    -- It uses the same 16 second wait Rag uses before his Resting set, and goes on last so nothing above
    -- (weapon loadouts, lockable set) can put your weapon back over the staff.
    local player = gData.GetPlayer()
    if (player.Status == 'Resting' and MPSubjobs:contains(player.SubJob)) then
        if (restStart == nil) then
            restStart = os.clock()
        end
        if (os.clock() > restStart + 16) then
            gFunc.EquipSet(sets.Resting_MPSub)
        end
    else
        restStart = nil
    end

    -- First gear check after a maneuver finishes: hold the maneuver set a little longer instead of swapping back.
    -- LuAshitacast does not run this check while the maneuver is still going, so this is the moment it ends.
    if (pendingManeuverSet ~= nil) then
        if (os.clock() < pendingManeuverExpires) then
            gFunc.LockSet(pendingManeuverSet, settings.maneuver_lock_seconds)
        end
        pendingManeuverSet = nil
    end
end

function gcpup.DoAbility(sets)
    gcmelee.DoAbility()
    gcmelee.DoWeaponBash() -- Rag's v320 WeaponBash set for Weapon Bash on /DRK

    local action = gData.GetAction()

    if (action.Name == 'Activate' or action.Name == 'Deus Ex Automata') then
        gFunc.EquipSet(sets.Activate)
    elseif (string.match(action.Name, 'Repair') or string.match(action.Name, 'Maintenance')) then
        gFunc.EquipSet(sets.Repair)
    elseif (string.contains(action.Name, 'Maneuver')) then
        -- 'Fire Maneuver' -> sets.Fire_Maneuver, and so on for all 8 elements. It goes on before the maneuver is sent,
        -- and DoDefault keeps it on for maneuver_lock_seconds after the maneuver finishes.
        local maneuverSet = sets[(string.gsub(action.Name, ' ', '_'))]
        if (maneuverSet ~= nil and next(maneuverSet) ~= nil) then
            gFunc.EquipSet(maneuverSet)
            pendingManeuverSet = maneuverSet
            pendingManeuverExpires = os.clock() + 10
        end
    elseif (action.Name == 'Overdrive') then
        gFunc.EquipSet(sets.Overdrive)
    elseif (action.Name == 'Ventriloquy') then
        gFunc.EquipSet(sets.Ventriloquy)
    elseif (action.Name == 'Role Reversal') then
        gFunc.EquipSet(sets.Role_Reversal)
    elseif (action.Name == 'Jump') then
        gFunc.EquipSet(sets.Jump)
    elseif (action.Name == 'High Jump') then
        gFunc.EquipSet(sets.Jump)
        gFunc.EquipSet(sets.HighJump)
    end
end

function gcpup.DoItem(sets)
    gcinclude.DoItem()
end

function gcpup.DoPreshot(sets)
    gcmelee.DoPreshot(sets.Preshot, gFunc.Combine(sets.Preshot, sets.Midshot), settings.snapShotValue)
end

function gcpup.DoMidshot(sets)
    gcmelee.DoMidshot(sets, gFunc.Combine(sets.Preshot, sets.Midshot))
end

function gcpup.DoWS(sets)
    -- Rag's WS handling: WS, plus WS_HighAcc when /tp is HighAcc
    gcmelee.DoWS()
end

local function KeepWeapons()
    if (not gcdisplay.GetToggle('Staff')) then
        gFunc.Equip('Main', 'ignore')
        gFunc.Equip('Sub', 'ignore')
    end
end

function gcpup.DoPrecast(sets)
    gcmage.DoPrecast(sets, settings.fastCastValue, 0)

    local player = gData.GetPlayer()
    if (player.SubJob == 'RDM') then
        gFunc.EquipSet('warlocks_mantle')
    end

    KeepWeapons()
end

function gcpup.DoMidcast(sets)
    gcmage.DoMidcast(sets, settings.ninSJMaxMP, settings.whmSJMaxMP, settings.blmSJMaxMP, settings.rdmSJMaxMP, settings.drkSJMaxMP)

    local action = gData.GetAction()

    -- gcmage has no Phalanx potency step, so it is added on top of its Enhancing set
    if (action.Skill == 'Enhancing Magic') then
        if (string.match(action.Name, 'Phalanx')) then
            gFunc.EquipSet(sets.Phalanx)
        end
    end


    KeepWeapons()
end

return gcpup
