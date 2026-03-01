#version 2
#include "script/include/common.lua"

------------------------------------------------
-- 实体引用
------------------------------------------------

-- 飞船 Vehicle
local shipVeh
-- 飞船 Body
local shipBody
-- 武器发射器 Shape（tag: primaryWeaponLauncher）
local laserShape

------------------------------------------------
-- 激光参数
------------------------------------------------

local maxDist             = 100   -- 最大射程（米）
local clientLaserDuration = 0.15  -- 激光持续显示时间（秒）

------------------------------------------------
-- 客户端激光状态
------------------------------------------------

local clientLaserTimer = 0
local clientLaserStart = nil
local clientLaserEnd   = nil

------------------------------------------------
-- 初始化
------------------------------------------------

function server.init()
    shipVeh  = FindVehicle("ship", false)
    shipBody = GetVehicleBody(shipVeh)
end

function client.init()
    shipVeh    = FindVehicle("ship", false)
    shipBody   = GetVehicleBody(shipVeh)
    laserShape = FindShape("primaryWeaponLauncher", false)
end

------------------------------------------------
-- 辅助：在指定位置生成激光发光粒子
-- 必须从 tick 回调中调用
------------------------------------------------

local function spawnLaserGlow(pos)
    ParticleReset()
    ParticleType("plain")
    ParticleColor(0.3, 0.8, 1.0)
    ParticleEmissive(8, 0)
    ParticleRadius(0.05, 0)
    ParticleGravity(0)
    ParticleDrag(1)
    SpawnParticle(pos, Vec(0, 0, 0), 0.08)
end

------------------------------------------------
-- 辅助：绘制激光（从 start --> end）
-- DrawLine 和 SpawnParticle 必须在 tick 中调用
------------------------------------------------

local function drawLaser()
    if not clientLaserStart or not clientLaserEnd then return end

    local segLength = 5.0
    local jitter    = 0.5

    local function rndVec(scale)
        return Vec(
            (math.random() - 0.5) * 4 * scale,
            (math.random() - 0.5) * 4 * scale,
            (math.random() - 0.5) * 4 * scale
        )
    end

    local dist     = VecLength(VecSub(clientLaserEnd, clientLaserStart))
    local segments = math.max(1, math.floor(dist / segLength + 0.5))

    local last = clientLaserStart
    for i = 1, segments do
        local t = i / segments
        local p = VecLerp(clientLaserStart, clientLaserEnd, t)
        p = VecAdd(p, rndVec(jitter * t))
        DrawLine(last, p, 1, 0.3, 0.8)
        spawnLaserGlow(p)
        last = p
    end
end

------------------------------------------------
-- 客户端：处理激光发射请求
------------------------------------------------

local function client_laserRequest()
    if not laserShape then
        DebugPrint("[Laser] laserShape 未找到，请确认 primaryWeaponLauncher tag 正确")
        return
    end

    local shapeT  = GetShapeWorldTransform(laserShape)
    local muzzleW = TransformToParentPoint(shapeT, Vec(0, 0, 3))
    local fwdW    = VecNormalize(TransformToParentVec(shapeT, Vec(0, 0, 1)))

    QueryRejectBody(shipBody)
    local hit, hitDist = QueryRaycast(muzzleW, fwdW, maxDist)

    clientLaserStart = muzzleW
    if hit then
        clientLaserEnd = VecAdd(muzzleW, VecScale(fwdW, hitDist))
        Command("laserHit",
            clientLaserEnd[1],
            clientLaserEnd[2],
            clientLaserEnd[3])
    else
        clientLaserEnd = VecAdd(muzzleW, VecScale(fwdW, maxDist))
    end

    clientLaserTimer = clientLaserDuration
end

------------------------------------------------
-- 客户端 tick
-- 注意：common.lua 框架的 client.tick 不传 dt 参数
-- 用 1/GetFps() 估算帧时间
------------------------------------------------

function client.tick()
    local dt = 1 / math.max(1, GetFps())

    DebugWatch("PlayerVehicle", GetPlayerVehicle())
    DebugWatch("shipVeh",       shipVeh)
    DebugWatch("laserShape",    laserShape)

    if GetPlayerVehicle() ~= shipVeh then
        return
    end

    DebugWatch("clientLaserTimer", clientLaserTimer)

    if InputPressed("lmb") then
        client_laserRequest()
    end

    -- 计时倒数
    if clientLaserTimer > 0 then
        clientLaserTimer = clientLaserTimer - dt
        if clientLaserTimer <= 0 then
            clientLaserStart = nil
            clientLaserEnd   = nil
        end
    end

    -- DrawLine + SpawnParticle 必须在 tick 中调用，不能放在 draw 里
    if clientLaserTimer > 0 then
        drawLaser()
    end
end

------------------------------------------------
-- 服务端：激光命中，在命中点制造爆炸
------------------------------------------------

function server.laserHit(x, y, z)
    Explosion(Vec(x, y, z), 1.5)
end


