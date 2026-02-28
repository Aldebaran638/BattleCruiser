#version 2
#include "script/include/common.lua"

------------------------------------------------
-- 实体引用
------------------------------------------------

local shipVeh
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
    shipVeh  = GetVehicle()
    shipBody = GetVehicleBody(shipVeh)
end

function client.init()
    shipVeh  = GetVehicle()
    shipBody = GetVehicleBody(shipVeh)
end

------------------------------------------------
-- 客户端输入
------------------------------------------------

function client.update(dt)

    DebugWatch("PlayerVehicle", GetPlayerVehicle())

    DebugWatch("shipVeh", shipVeh)


    if GetPlayerVehicle() == shipVeh then
        DebugWatch("clientLaserTimer3", 33333)
        if InputPressed("lmb") then
            DebugWatch("clientLaserTimer4", 44444)
            net.call("server_fireLaser")
        end
    end
    DebugWatch("clientLaserTimer2", 22222)
    if clientLaserTimer > 0 then
        clientLaserTimer = clientLaserTimer - dt
    end

end

------------------------------------------------
-- 客户端画线
------------------------------------------------

function client.draw()

    if clientLaserTimer > 0 then
        DrawLine(clientLaserStart, clientLaserEnd)
    end

end

------------------------------------------------
-- 服务器处理激光
------------------------------------------------

function server_fireLaser()

    local driver = GetVehicleDriver(shipVeh)
    if driver == 0 then return end

    local cam = GetPlayerCameraTransform(driver)

    local dir = TransformToParentVec(cam, Vec(0,0,-1))
    local hit, dist = QueryRaycast(cam.pos, dir, 1000)

    local endPos = VecAdd(cam.pos, VecScale(dir, dist))

    if hit then
        Explosion(endPos, 2)
    end

    net.broadcast("client_syncLaser", cam.pos, endPos)

end

------------------------------------------------
-- 客户端接收同步
------------------------------------------------

function client_syncLaser(startPos, endPos)

    clientLaserStart = startPos
    clientLaserEnd   = endPos
    clientLaserTimer = 0.08

end