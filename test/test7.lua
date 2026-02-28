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

------------------------------------------------
-- 初始化
------------------------------------------------

function server.init()
    shipVeh  = FindVehicle("ship", false)
    shipBody = GetVehicleBody(shipVeh)
end

function client.init()
    shipVeh  = FindVehicle("ship", false)
    shipBody = GetVehicleBody(shipVeh)
end

function 

------------------------------------------------
-- 客户端处理输入
------------------------------------------------

function client.tick(dt)
    DebugWatch("PlayerVehicle", GetPlayerVehicle())

    DebugWatch("shipVeh", shipVeh)

    if not GetPlayerVehicle() == shipVeh then
        return  -- 如果玩家不在飞船上，忽略输入
    end

    DebugWatch("clientLaserTimer", clientLaserTimer)

    -- 检查鼠标左键是否被按下
    if InputPressed("lmb") then
        client_laserRequest()
    end
end