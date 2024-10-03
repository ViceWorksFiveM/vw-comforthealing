local COMFORT = 0.0
local lastAttackTime = 0
QBCore = nil
PlayerData = nil

if GetResourceState("qb-core") == "started" then
    QBCore = exports['qb-core']:GetCoreObject()
    PlayerData = QBCore.Functions.GetPlayerData()
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        PlayerData = QBCore.Functions.GetPlayerData()
    end)

    RegisterNetEvent('QBCore:Client:OnJobUpdate', function(jobInfo)
        PlayerData.job = jobInfo
    end)

    RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
        PlayerData = val
    end)    
end

local function getPlayerIsSitting()
    local ped = PlayerPedId()
    local skelPos = (GetPedBoneCoords(ped, 51826) + GetPedBoneCoords(ped, 58271)) / 2
    local pedPos = GetEntityCoords(ped)
    return #(skelPos - pedPos) > 0.5
end

local function getComfortMax(data)
    local max = 0
    for k, v in pairs(data) do
        if v and Config.comforts[k] then
            max = math.max(max, Config.comforts[k])
        end
    end
    return max
end

local function calculateHealthRegen(comfort, hunger)
    return (comfort / 100) * (hunger / 100) * Config.maxRegenRate
end

-- Main Thread
Citizen.CreateThread(function()
    while true do
        local ped = PlayerPedId()

        if not IsPedInAnyVehicle(ped) then
            local pos = GetEntityCoords(ped)
            local fireFound, firePos = GetClosestFirePos(pos.x, pos.y, pos.z)
            local dist = #(pos - firePos)
            local isSitting = getPlayerIsSitting()
            
            if fireFound and dist < Config.comfortRadius then
                local comfortMax = getComfortMax({
                    sit_fire = isSitting,
                    stand_fire = not isSitting
                })
                local comfortMultiplier = (comfortMax - dist) / comfortMax
                local comfortLimit = math.min((comfortMax / dist) * 5, comfortMax)
                COMFORT = math.min(COMFORT + Config.comfortIncreaseRate * comfortMultiplier, comfortLimit)
            elseif isSitting and GetEntitySpeed(ped) < 0.1 then
                local comfortMax = getComfortMax({
                    sit = true,
                })
                
                COMFORT = math.min(COMFORT + Config.comfortIncreaseRate, comfortMax)
            else
                local rate = math.abs(Config.comfortDecreaseRate * (Config.comfortRadius - dist) / 10)
                COMFORT = math.max(COMFORT - rate, 0)
            end
            
            if COMFORT > 0 then
                metabolise()
            else
                SetPlayerHealthRechargeMultiplier(PlayerId(), 0.0)
                SetPlayerHealthRechargeLimit(PlayerId(), 0.0)
            end
        end

        Citizen.Wait(Config.metabolismInterval)
    end
end)

function getPlayerHunger()
    if not PlayerData then return 100 end
    return PlayerData.metadata["hunger"] or 100
end

function getPlayerThirst()
    if not PlayerData then return 100 end
    return PlayerData.metadata["thirst"] or 100
end

function getAroundPlayersBoost()
    local list = GetActivePlayers()
    local boost = 0
    for i = 1, #list do
        local ped = GetPlayerPed(list[i])
        if ped == PlayerPedId() then
            goto continue
        end

        local pos = GetEntityCoords(ped)
        local dist = #(GetEntityCoords(PlayerPedId()) - pos)
        if dist < Config.comfortRadius then
            boost = boost + Config.comfortIncreaseRate
        end

        ::continue::
    end
    return boost
end

function isPlayerBleeding()
    if not QBCore then return false end

    local p = promise:new()
    QBCore.Functions.TriggerCallback('hospital:GetPlayerBleeding', function(bleeding)
        p:resolve(bleeding and bleeding > 0)
    end)
    return Citizen.Await(p)
end

function metabolise()
    local ped = PlayerPedId()
    local health = GetEntityHealth(ped) - 100
    local playersBoost = getAroundPlayersBoost()
    local comfort = COMFORT + playersBoost

    local hunger = getPlayerHunger()
    local thirst = getPlayerThirst()
    local isBleeding = isPlayerBleeding()
    if hunger > 75 and
       thirst > 40 and
       (GetGameTimer() - lastAttackTime) > 10000 and
       not isBleeding and
       comfort > (health / 100) * 100 then
        local healthRegen = calculateHealthRegen(comfort, hunger)
        if healthRegen > 1.0 then healthRegen = 1.0 end
        SetPlayerHealthRechargeMultiplier(PlayerId(), healthRegen)
        SetPlayerHealthRechargeLimit(PlayerId(), comfort / 100)

        --updatePlayerHunger(hunger - 1)
        --updatePlayerThirst(thirst - 0.5)
    else
        SetPlayerHealthRechargeMultiplier(PlayerId(), 0.0)
        SetPlayerHealthRechargeLimit(PlayerId(), 0.0)
    end
end

AddEventHandler('gameEventTriggered', function(name, args)
    if name == "CEventNetworkEntityDamage" then
        local victim = args[1]
        local attacker = args[2]
        local isDead = args[4]
        if victim == PlayerPedId() and not isDead then
            lastAttackTime = GetGameTimer()
        end
    end
end)

--Debug
if Config.debug then
    function drawTxt(x, y, width, height, scale, text, r, g, b, a)
        SetTextFont(0)
        SetTextProportional(0)
        SetTextScale(0.25, 0.25)
        SetTextColour(r, g, b, a)
        SetTextDropShadow(0, 0, 0, 0,255)
        SetTextEdge(1, 0, 0, 0, 255)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(x - width/2, y - height/2 + 0.005)
    end

    CreateThread(function()
        while true do
            Wait(0)
            drawTxt(1.0, 0.8, 0.5, 0.5, 0.5, "Comfort: " .. COMFORT, 255, 255, 255, 255)
            drawTxt(1.0, 0.82, 0.5, 0.5, 0.5, "Health: " .. GetEntityHealth(PlayerPedId()), 255, 255, 255, 255)
            
            if PlayerData and PlayerData.metadata then
                drawTxt(1.0, 0.84, 0.5, 0.5, 0.5, "Hunger: " .. PlayerData.metadata["hunger"], 255, 255, 255, 255)
                drawTxt(1.0, 0.86, 0.5, 0.5, 0.5, "Thirst: " .. PlayerData.metadata["thirst"], 255, 255, 255, 255)
            end
            
            drawTxt(1.0, 0.88, 0.5, 0.5, 0.5, "Regen Limit: " .. GetPlayerHealthRechargeLimit(PlayerId()), 255, 255, 255, 255)
        end
    end)

    RegisterCommand("plyhl", function()
        SetEntityHealth(PlayerPedId(), 101)
    end)
end