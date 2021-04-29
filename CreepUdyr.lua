if Player.CharName ~= "Udyr" then return end
require("common.log")
module("Creep Udyr", package.seeall, log.setup)
clean.module("Creep Udyr", clean.seeall, log.setup)
RTime = 0
AACounter = 0

--[[ SDK ]]
local SDK         = _G.CoreEx
local Obj         = SDK.ObjectManager
local Event       = SDK.EventManager
local Game        = SDK.Game
local Enums       = SDK.Enums
local Geo         = SDK.Geometry
local Renderer    = SDK.Renderer
local Input       = SDK.Input
--[[Libraries]] 
local TS          = _G.Libs.TargetSelector()
local Menu        = _G.Libs.NewMenu
local Orb         = _G.Libs.Orbwalker
local Collision   = _G.Libs.CollisionLib
local Pred        = _G.Libs.Prediction
local HealthPred  = _G.Libs.HealthPred
local DmgLib      = _G.Libs.DamageLib
local ImmobileLib = _G.Libs.ImmobileLib
local Spell       = _G.Libs.Spell
local SpellSlots, SpellStates = Enums.SpellSlots, Enums.SpellStates
TS = _G.Libs.TargetSelector(Orb.Menu)

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
local Udyr = {}


local Q = Spell.Active({
    Slot = Enums.SpellSlots.Q,
    Delay = 0.09,
    Key = "Q",
    Range = 600
})
local W = Spell.Active({
    Slot = Enums.SpellSlots.W,
    Delay = 0.09,
    Range = 600,
    Key = "W"
})
local E = Spell.Active({
    Slot = Enums.SpellSlots.E,
    Delay = 0.09,
    Range = 600,
    Key = "E"
})
local R = Spell.Active({
    Slot = Enums.SpellSlots.R,
    Delay = 0.09,
    Range = 325,
    Key = "R"

})

local function currentStance()
    if Player:GetBuff("UdyrTigerStance") then
        return "tiger"
    elseif Player:GetBuff("UdyrTurtleStance")  then
        return "turtle"
    elseif Player:GetBuff("UdyrBearStance")  then
        return "bear"
    elseif Player:GetBuff("udyrphoenixstance")  then
        return "pheonix"
    else
        return "none"
    end
end

local function GameIsAvailable()
    return not (Game.IsChatOpen() or Game.IsMinimized() or Player.IsDead or Player.IsRecalling)
end

local function CanCast(spell,mode)
    return spell:IsReady() and (Player.Mana > spell:GetManaCost())
end

function Udyr.OnHighPriority() 
    if not GameIsAvailable() then return end
	if not Orb.CanCast() then return end
    if Orb.GetMode() == "Combo" then
        Udyr.Combo()
    elseif Orb.GetMode() == "Waveclear" then
        Udyr.Waveclear()
    elseif Orb.GetMode() == "Flee" then
        Udyr.Flee()
    end
    local gameTime = Game.GetTime()
    local rCD = Player:GetSpell(SpellSlots.R).RemainingCooldown
    if RTime <= gameTime and rCD > 0 then
        AACounter = 0
        RTime = gameTime + rCD
    end
end

function Udyr.OnPostAttack()
    if Player:GetBuff("udyrphoenixstance") then
        AACounter = AACounter+1
    end

end

function Udyr.Combo()
    local mode = "Combo"
    local target = Orb.GetTarget() or TS:GetTarget(Player.AttackRange + Player.BoundingRadius, false)
        if target then
        if Menu.Get("Combo.CastE") and CanCast(E,mode) and not Player:GetBuff("udyrbearstuncheck") then
             E:Cast()
        elseif Player:GetBuff("udyrbearstance") or Player:GetBuff("udyrbearstuncheck") then
            if Menu.Get("QMax") then
                if Menu.Get("Combo.CastQ") and CanCast(Q,mode) and not Player:GetBuff("udyrtigerpunch") then
                    Q:Cast()
                end
            elseif Menu.Get("RMax") then
            if Menu.Get("Combo.CastR") and CanCast(R,mode) and not Player:GetBuff("udyrphoenixactivation") then
                    R:Cast()
                end
            elseif Menu.Get("Combo.CastW") and CanCast(W,mode) then
                W:Cast()
            end
        end
    elseif Menu.Get("GapClose.CastE") and CanCast(E,mode) then
        E:Cast()
    elseif Menu.Get("GapClose.CastW") and CanCast(W,mode) then
        W:Cast()
    end
end

function Udyr.Waveclear()
    for k, v in pairs(Obj.Get("neutral", "minions")) do
        local minion = v.AsAI
        local minionInRange = Q:IsInRange(minion)
        if minionInRange and minion.IsMonster  and minion.IsTargetable then
    local mode = "Waveclear"
    local gameTime = Game.GetTime()
    local manap = Player.Mana / Player.MaxMana * 100
    if Menu.Get("RMax") then
        
        if Menu.Get("Clear.W") and CanCast(W,mode) and manap >= Menu.Get("Clear.WMana") then
            if currentStance() == "pheonix" then
                if AACounter >= 4  then
                    W:Cast()
                elseif CanCast(R,mode) and RTime + 1500 <= gameTime then
                    W:Cast()
                end
            elseif currentStance() ~= "pheonix" then
                W:Cast()
            end
        elseif Menu.Get("Clear.R")  and CanCast(R,mode)  and manap >= Menu.Get("Clear.RMana") then
            if currentStance() == "pheonix" and AACounter >= 4 then
                R:Cast()
            elseif currentStance() ~= "pheonix" then
                R:Cast()
            end
        elseif Menu.Get("Clear.Q") and CanCast(Q,mode)  and manap >= Menu.Get("Clear.QMana") then
            if currentStance() == "pheonix" then
                if AACounter >= 4 then
                    Q:Cast()
                elseif RTime + 1500 <= gameTime then
                    Q:Cast()
                end
            elseif currentStance() ~= "pheonix" then
                Q:Cast()
            end
        end
     elseif Menu.Get("QMax") then
        if Menu.Get("Clear.W") and CanCast(W,mode)  and manap >=  Menu.Get("Clear.WMana") then
            W:Cast()
        elseif Menu.Get("Clear.Q") and CanCast(Q,mode)  and manap >=  Menu.Get("Clear.WMana") then
            W:Cast()
        elseif Menu.Get("Clear.R") and CanCast(R,mode) and manap >=  Menu.Get("Clear.RMana")  and not Player:GetBuff("udyrtigerpunch") then
            R:Cast()
        end
    else
        print("[CreepUdyr]You have no skill max priority - please set one in the menu")
        end
    end
end
    end

    function Udyr.Flee()
        if Menu.Get("Flee.E") and CanCast(E) then
            E:Cast()
        elseif Menu.Get("Flee.W") and CanCast(W) then
            W:Cast()
        end
    end

function Udyr.LoadMenu()
    Menu.RegisterMenu("CreepUdyr", "Creep Udyr", function()
        Menu.NewTree("Style", "Playstyle settings", function()
            Menu.Checkbox("QMax",   "Maxing Q", true)
            Menu.Checkbox("RMax",   "Maxing R", true)
        end)
        Menu.NewTree("Combo", "Combo Options", function()
            Menu.Checkbox("Combo.CastQ",   "Use [Q]", true)
            Menu.Checkbox("Combo.CastW",   "Use [W]", true)
            Menu.Checkbox("Combo.CastE",   "Use [E]", true)
            Menu.Checkbox("Combo.CastR",   "Use [R]", true)

        end)
        Menu.NewTree("GapClose", "GapClose Options", function()
            Menu.Checkbox("GapClose.CastW",   "Use [W]", true)
            Menu.Checkbox("GapClose.CastE",   "Use [E]", true)

        end)
        Menu.NewTree("Clear", "Clear Options", function()
                Menu.Checkbox("Clear.Q",   "Use [Q]", true)
                Menu.Slider("Clear.QMana","Q Min Mana",20,1,100,5)
                Menu.Checkbox("Clear.W",   "Use [W]", true)
                Menu.Slider("Clear.WMana","W Min Mana",20,1,100,5)
                Menu.Checkbox("Clear.E",   "Use [E]", true)
                Menu.Slider("Clear.EMana","E Min Mana",20,1,100,5)
                Menu.Checkbox("Clear.R",   "Use [R]", true)
                Menu.Slider("Clear.RMana","R Min Mana",20,1,100,5)
            end)
            Menu.NewTree("Flee", "Flee Options", function() 
                Menu.Checkbox("Flee.W",   "Use [w] ", true)
                Menu.Checkbox("Flee.E",   "Use [E] ", true)
            end)
        end)
end

function OnLoad()
    Udyr.LoadMenu()
    for eventName, eventId in pairs(Enums.Events) do
        if Udyr[eventName] then
            Event.RegisterCallback(eventId, Udyr[eventName])
        end
    end    
    return true
end