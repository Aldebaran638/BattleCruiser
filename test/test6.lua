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

------------------------------------------------
-- 客户端激光请求（鼠标左键点击发送请求）
------------------------------------------------

-- 客户端接收鼠标信息向服务端发送激光请求
function client_laserRequest()
    DebugWatch("client_laserRequest", 1)

    if not shipVeh then
        return  -- 如果没有飞船对象，忽略
    end

    -- 获取飞船的变换信息
    local shipTransform = GetVehicleTransform(shipVeh)

    -- 获取激光发射方向，这里使用飞船本地坐标系的 (0, 0, -1)
    local dir = TransformToParentVec(shipTransform, Vec(0, 0, -1))

    -- 设置激光发射起始点，飞船的本地坐标系中的 (0, -6, 0)
    local localStartPos = Vec(0, -6, 0)
    local startPos = TransformToParentVec(shipTransform, localStartPos)

    -- 向服务器发送激光请求，包含起始位置和发射方向
    net.send("server_fireLaser", startPos, dir)
end

------------------------------------------------
-- 服务端处理射线检测
------------------------------------------------

-- 服务端处理射线检测
function server_fireLaser_raycast(startPos, dir)
    DebugWatch("server_fireLaser_raycast", 1)

    local distance = 1000  -- 设置射线检测的最大距离
    -- 进行射线检测，返回是否命中和射线的命中距离
    local hit, dist = QueryRaycast(startPos, dir, distance)
    
    return hit, dist
end

------------------------------------------------
-- 服务器处理爆炸逻辑
------------------------------------------------

-- 服务器处理爆炸逻辑
function server_fireLaser_explosion(endPos, hit)
    DebugWatch("server_fireLaser_explosion", 1)

    if not hit then
        return
    end
    -- 在激光射线的终点位置产生一个爆炸效果
    Explosion(endPos, 2)  -- 第二个参数是爆炸的范围
end

------------------------------------------------
-- 服务端向客户端广播激光信息
------------------------------------------------

-- 服务端向客户端广播激光信息
function server_fireLaser_broadcastLaser(startPos, endPos, hit)
    DebugWatch("server_fireLaser_broadcastLaser", 1)

    -- 使用 net.broadcast 向所有客户端广播激光的起始位置、终点和命中状态
    net.broadcast("client_syncLaser", startPos, endPos, hit)
end

------------------------------------------------
-- 服务端接受请求并处理激光逻辑(射线检测+爆炸逻辑)最后向客户端广播激光信息
------------------------------------------------

-- 服务端接受请求并处理激光逻辑(射线检测+爆炸逻辑)最后向客户端广播激光信息
function server_fireLaser(startPos, dir)
    DebugWatch("server_fireLaser", 1)

    -- 进行射线检测
    local hit, dist = server_fireLaser_raycast(startPos, dir)

    -- 计算激光终点
    local endPos = VecAdd(startPos, VecScale(dir, dist))

    -- 处理爆炸逻辑（如果有碰撞）
    server_fireLaser_explosion(endPos, hit)

    -- 向所有客户端广播激光信息
    server_fireLaser_broadcastLaser(startPos, endPos, hit)
end

------------------------------------------------
-- 客户端接收服务端广播的激光信息
------------------------------------------------

-- 客户端接收服务端广播的激光信息
function client_syncLaser(startPos, endPos, hit)
    DebugWatch("client_syncLaser", 1)

    clientLaserStart = startPos
    clientLaserEnd = endPos
    clientLaserHit = hit
end

------------------------------------------------
-- 客户端绘制激光
------------------------------------------------

-- 客户端绘制激光
function client.draw()
    DebugWatch("client.draw", 1)

    if clientLaserStart and clientLaserEnd then
        client_syncLaser_drawLaser(clientLaserStart, clientLaserEnd)  -- 绘制激光
    end

    if clientLaserHit then
        client_syncLaser_drawExplosion(clientLaserEnd, clientLaserHit)   -- 绘制爆炸效果
    end
end

-- 客户端绘制激光
function client_syncLaser_drawLaser(startPos, endPos)
    DebugWatch("client_syncLaser_drawLaser", 1)

    -- 激光发射参数（段数会根据全局 maxDist 自动跟随）
    local segLength = 5.0  -- 每一小段的长度（越小越细腻）
    local segments = math.max(1, math.floor(VecLength(VecSub(startPos, endPos)) / segLength + 0.5))
    local jitter = 0.5  -- 随机闪烁幅度

    -- 简单 rndVec 函数
    local function rndVec(scale)
        return Vec(
            (math.random() - 0.5) * 4 * scale,
            (math.random() - 0.5) * 4 * scale,
            (math.random() - 0.5) * 4 * scale
        )
    end

    -- 绘制激光（是否调用由外部状态 laserShotActive 决定）
    local last = startPos
    for i = 1, segments do
        local t = i / segments
        local p = VecLerp(startPos, endPos, t)
        p = VecAdd(p, rndVec(jitter * t))  -- 可选随机偏移，制造闪烁效果
        DrawLine(last, p, 1, 1, 1)  -- DrawLine(from, to, thickness, r, g, b)
        last = p
    end
end

------------------------------------------------
-- 客户端绘制爆炸效果
------------------------------------------------

-- 客户端绘制爆炸效果
function client_syncLaser_drawExplosion(endPos, hit)
    DebugWatch("client_syncLaser_drawExplosion", 1)

    if not hit then
        return
    end

    -- 使用官方的 Explosion 函数在指定位置生成爆炸效果
    -- 第二个参数是爆炸的范围大小，通常设置为 2 即可
    Explosion(endPos, 2)
end

------------------------------------------------
-- 客户端播放爆炸声音
------------------------------------------------

-- 客户端播放爆炸声音
function client_playExplosionSound(endPos, hit)
    DebugWatch("client_playExplosionSound", 1)

    if not hit then
        return
    end

    -- 假设你已经加载了爆炸音效文件，例：`explosionSound = LoadSound("MOD/sounds/explosion.ogg")`
    -- 播放爆炸音效
    local explosionSound = LoadSound("MOD/sounds/explosion.ogg")
    PlaySound(explosionSound, endPos, 1.0)  -- 参数 1.0 控制音量
end

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