#version 2
#include "script/include/common.lua"

------------------------------------------------
-- 实体引用
------------------------------------------------

-- 飞船Vehicle
local shipVeh
-- 飞船Body
local shipBody

------------------------------------------------
-- 客户端激光变量
------------------------------------------------

local clientLaserStart
local clientLaserEnd
local clientLaserTimer = 0

-- 服务器端输入边沿检测回退（当 InputPressed("lmb", playerId) 不可用时使用）
local serverPrevLmbDown = {}

------------------------------------------------
-- 初始化
------------------------------------------------

function server.init()
    shipVeh  = FindVehicle("ship", false)
    shipBody = GetVehicleBody(shipVeh)

    shared.lastClickPlayerId = -1
    shared.pilot = -1
end

function client.init()
    shipVeh  = FindVehicle("ship", false)
    shipBody = GetVehicleBody(shipVeh)
end

------------------------------------------------
-- 激光模块
------------------------------------------------

-- 服务器端:

function client.tick(dt)
    DebugWatch("PlayerVehicle", GetPlayerVehicle())

    DebugWatch("PushPlayer", shared.lastClickPlayerId)

    DebugWatch("shipVeh", shipVeh)

    DebugWatch("clientLaserTimer", clientLaserTimer)
    -- 本地仅用于验证：我自己是否按下了左键（不做网络发送）
    DebugWatch("LocalLmbDown", InputDown("lmb"))
    DebugWatch("LocalLmbPressed", InputPressed("lmb"))
end


function server.tick()
    DebugWatch("server",114514)

    local players = GetAllPlayers()
    if shipVeh ~= 0 then
        for i = 1, #players do
            local p = players[i]
            if IsPlayerValid(p) and IsPlayerVehicleDriver(shipVeh, p) then
                shared.pilot = p
                break
            end
        end
    else
        shared.pilot = -1
    end

    -- PlaneMain 思路：服务器端轮询每个玩家的输入，捕获谁按下了左键
    for i = 1, #players do
        local p = players[i]
        if IsPlayerValid(p) then
            local ok, pressed = pcall(InputPressed, "lmb", p)
            if ok then
                if pressed then
                    shared.lastClickPlayerId = p
                    break
                end
            else
                local down = InputDown("lmb", p)
                if down and not serverPrevLmbDown[p] then
                    shared.lastClickPlayerId = p
                    serverPrevLmbDown[p] = down
                    break
                end
                serverPrevLmbDown[p] = down
            end
        end
    end
end