#version 2

client = client or {}
server = server or {}

------------------------------------------------
-- whirlwindMissiles_promote 模块 开始
------------------------------------------------

-- 推进力大小（可调）
local whirlwindMissiles_promote_THRUST = 15.0

-- 记录 launcherShape 初始所属 body，用于判断“仍然连接”
local whirlwindMissiles_promote_launcherBody0ByShape = {}



-- whirlwindMissiles_promote_findLaunchers 描述：扫描场上所有 launcherShape
local function whirlwindMissiles_promote_findLaunchers ()
    return FindShapes("launcher", false) or {}
end

-- whirlwindMissiles_promote_applyForwardImpulse 描述：对导弹质心施加推进冲量（沿 body 局部 -Z 方向）
local function whirlwindMissiles_promote_applyForwardImpulse (missileBody, thrust, dt)
    if missileBody == 0 then return end
    if dt <= 0 then return end

    local comLocal = GetBodyCenterOfMass(missileBody)
    local t = GetBodyTransform(missileBody)
    local comWorld = TransformToParentPoint(t, comLocal)

    local forward = TransformToParentVec(t, Vec(0, 0, -1))
    forward = VecNormalize(forward)

    local mass = GetBodyMass(missileBody)
    local impulse = VecScale(forward, thrust * mass * dt)
    ApplyBodyImpulse(missileBody, comWorld, impulse)
end

-- whirlwindMissiles_promote_server_tick 描述：服务端 tick（launcherShape 存在且仍连接才推进）
local function whirlwindMissiles_promote_server_tick (dt)
    local launchers = whirlwindMissiles_promote_findLaunchers()
    if #launchers == 0 then
        return
    end

    for i = 1, #launchers do
        local launcherShape = launchers[i]
        -- launcherShape 一旦碎裂（单格玻璃很容易碎），该导弹不再提供推力
        if launcherShape ~= 0 and (not IsShapeBroken(launcherShape)) then
            local missileBody = GetShapeBody(launcherShape)
            if missileBody ~= 0 and HasTag(missileBody, "missile") then
                local body0 = whirlwindMissiles_promote_launcherBody0ByShape[launcherShape]
                if not body0 or body0 == 0 then
                    body0 = missileBody
                    whirlwindMissiles_promote_launcherBody0ByShape[launcherShape] = body0
                end

                if missileBody == body0 then
                    whirlwindMissiles_promote_applyForwardImpulse(missileBody, whirlwindMissiles_promote_THRUST, dt)
                end
            end
        end
    end
end

------------------------------------------------
-- whirlwindMissiles_promote 模块 结束
------------------------------------------------

------------------------------------------------
-- whirlwindMissiles_draw 模块 开始
------------------------------------------------

-- 记录 launcherShape 初始所属 body，用于判断“仍然连接”
local whirlwindMissiles_draw_launcherBody0ByShape = {}



-- whirlwindMissiles_draw_findLaunchers 描述：扫描场上所有 launcherShape
local function whirlwindMissiles_draw_findLaunchers ()
    return FindShapes("launcher", false) or {}
end

-- whirlwindMissiles_draw_drawOneLauncherSmoke 描述：为单个 launcherShape 绘制尾焰（仍连接才绘制）
local function whirlwindMissiles_draw_drawOneLauncherSmoke (launcherShape)
    if launcherShape == 0 or IsShapeBroken(launcherShape) then
        return
    end

    local missileBody = GetShapeBody(launcherShape)
    if missileBody == 0 or (not HasTag(missileBody, "missile")) then
        return
    end

    local body0 = whirlwindMissiles_draw_launcherBody0ByShape[launcherShape]
    if not body0 or body0 == 0 then
        body0 = missileBody
        whirlwindMissiles_draw_launcherBody0ByShape[launcherShape] = body0
    end
    if missileBody ~= body0 then
        return
    end

    local tShape = GetShapeWorldTransform(launcherShape)
    local emitPos = tShape.pos

    local backVel = Vec(0, 0, 0)
    local tBody = GetBodyTransform(missileBody)
    local forward = TransformToParentVec(tBody, Vec(0, 0, -1))
    forward = VecNormalize(forward)
    backVel = VecScale(forward, -5.0)

    ParticleReset()
    ParticleType("plain")
    ParticleColor(0.2, 0.8, 1.0, 0.0, 0.5, 1.0)
    ParticleRadius(0.04, 0.1, "smooth", 0.0, 0.8)
    ParticleAlpha(1.0, 0.0, "smooth", 0.0, 1.0)
    ParticleEmissive(6.0, 0.0)
    ParticleGravity(0.0)
    ParticleDrag(0.1)
    ParticleStretch(1.5)

    for i = 1, 4 do
        local spread = Vec(
            (math.random() - 0.5) * 0.06,
            (math.random() - 0.5) * 0.06,
            (math.random() - 0.5) * 0.06
        )
        local p = VecAdd(emitPos, spread)

        local jitter = Vec(
            (math.random() - 0.5) * 0.4,
            (math.random() - 0.5) * 0.4,
            (math.random() - 0.5) * 0.4
        )
        local v = VecAdd(backVel, jitter)

        local life = 0.25 + math.random() * 0.15
        SpawnParticle(p, v, life)
    end
end

-- whirlwindMissiles_draw_client_draw 描述：客户端 draw（扫描所有导弹并绘制尾焰）
local function whirlwindMissiles_draw_client_draw (dt)
    local launchers = whirlwindMissiles_draw_findLaunchers()
    if #launchers == 0 then
        return
    end

    for i = 1, #launchers do
        whirlwindMissiles_draw_drawOneLauncherSmoke(launchers[i])
    end
end

------------------------------------------------
-- whirlwindMissiles_draw 模块 结束
------------------------------------------------

------------------------------------------------
-- whirlwindMissiles_hit 模块 开始
------------------------------------------------

-- 爆炸半径（可调）
local whirlwindMissiles_hit_explosionSize = 3.0

-- 引信保险时间（秒）：防止刚 Spawn 就撞到自身/发射器导致立刻爆
local whirlwindMissiles_hit_armTime = 0.15

-- 使用 tag 给每个弹头分配稳定 uid，避免句柄复用导致的“奇数炸偶数不炸”
local whirlwindMissiles_hit_uidTag = "whirlwindMissiles_hit_uid"

-- 标记是否已引爆（shape/body tag）
local whirlwindMissiles_hit_detonatedTag = "whirlwindMissiles_hit_detonated"
local whirlwindMissiles_hit_detonatedBodyTag = "whirlwindMissiles_detonated"

-- 弹头状态（uid -> st）
-- st = { t=number, lastPos=Vec, hasLast=bool }
local whirlwindMissiles_hit_stateByUid = {}

-- （去重 tag 已在上方声明）

-- whirlwindMissiles_hit_findHeads 描述：扫描场上所有 missileHeadShape
local function whirlwindMissiles_hit_findHeads ()
    return FindShapes("missileHead", false) or {}
end

-- whirlwindMissiles_hit_getOrAssignUid 描述：为弹头 shape 获取/分配稳定 uid（存到 tag）
local function whirlwindMissiles_hit_getOrAssignUid (missileHeadShape)
    local uid = GetTagValue(missileHeadShape, whirlwindMissiles_hit_uidTag)
    if uid and uid ~= "" then
        return uid
    end

    uid = tostring(missileHeadShape) .. "_" .. tostring(math.random(100000, 999999))
    SetTag(missileHeadShape, whirlwindMissiles_hit_uidTag, uid)
    return uid
end

-- whirlwindMissiles_hit_markDetonated 描述：给弹头/导弹打上已引爆标记，并移除 missileHead tag 防止重复扫描
local function whirlwindMissiles_hit_markDetonated (missileHeadShape, missileBody)
    SetTag(missileHeadShape, whirlwindMissiles_hit_detonatedTag)
    if missileBody and missileBody ~= 0 then
        SetTag(missileBody, whirlwindMissiles_hit_detonatedBodyTag)
    end
    pcall(RemoveTag, missileHeadShape, "missileHead")
end

-- whirlwindMissiles_hit_tryDetonateAt 描述：在指定位置引爆一次（并标记）
local function whirlwindMissiles_hit_tryDetonateAt (missileHeadShape, missileBody, pos)
    if not pos then
        return
    end
    if HasTag(missileHeadShape, whirlwindMissiles_hit_detonatedTag) then
        return
    end
    if missileBody and missileBody ~= 0 and HasTag(missileBody, whirlwindMissiles_hit_detonatedBodyTag) then
        whirlwindMissiles_hit_markDetonated(missileHeadShape, missileBody)
        return
    end

    whirlwindMissiles_hit_markDetonated(missileHeadShape, missileBody)
    Explosion(pos, whirlwindMissiles_hit_explosionSize)
end

-- whirlwindMissiles_hit_updateOne 描述：扫掠射线引信（主）+ 碎裂引信（备）
local function whirlwindMissiles_hit_updateOne (missileHeadShape, dt)
    if missileHeadShape == 0 then
        return
    end

    local missileBody = GetShapeBody(missileHeadShape)
    if missileBody == 0 or (not HasTag(missileBody, "missile")) then
        return
    end

    if HasTag(missileHeadShape, whirlwindMissiles_hit_detonatedTag) or HasTag(missileBody, whirlwindMissiles_hit_detonatedBodyTag) then
        return
    end

    local uid = whirlwindMissiles_hit_getOrAssignUid(missileHeadShape)
    local st = whirlwindMissiles_hit_stateByUid[uid]
    if not st then
        st = { t = 0, lastPos = Vec(0, 0, 0), hasLast = false }
        whirlwindMissiles_hit_stateByUid[uid] = st
    end

    st.t = (st.t or 0) + (dt or 0)

    local tNow = GetShapeWorldTransform(missileHeadShape)
    local posNow = tNow.pos

    -- 备选触发：弹头碎裂就立即爆（不依赖射线）
    if IsShapeBroken(missileHeadShape) then
        whirlwindMissiles_hit_tryDetonateAt(missileHeadShape, missileBody, posNow)
        return
    end

    -- 保险期内：只记录位置，不做命中检测
    if st.t < whirlwindMissiles_hit_armTime then
        st.lastPos = posNow
        st.hasLast = true
        return
    end

    -- 扫掠射线：lastPos -> posNow
    if not st.hasLast then
        st.lastPos = posNow
        st.hasLast = true
        return
    end

    local delta = VecSub(posNow, st.lastPos)
    local dist = VecLength(delta)
    if dist < 0.001 then
        st.lastPos = posNow
        return
    end

    local dir = VecScale(delta, 1.0 / dist)
    QueryRejectBody(missileBody)

    local hit, hitDist = QueryRaycast(st.lastPos, dir, dist)
    if hit then
        local hitPos = VecAdd(st.lastPos, VecScale(dir, hitDist))
        whirlwindMissiles_hit_tryDetonateAt(missileHeadShape, missileBody, hitPos)
        return
    end

    st.lastPos = posNow
end

-- whirlwindMissiles_hit_server_tick 描述：服务端 tick（检测弹头碎裂并爆炸）
local function whirlwindMissiles_hit_server_tick (dt)
    local heads = whirlwindMissiles_hit_findHeads()
    if #heads == 0 then
        return
    end

    for i = 1, #heads do
        whirlwindMissiles_hit_updateOne(heads[i], dt)
    end
end

------------------------------------------------
-- whirlwindMissiles_hit 模块 结束
------------------------------------------------

------------------------------------------------
-- whirlwindMissiles_selfDestruct 模块 开始
------------------------------------------------

-- 最大存活时间（秒）：飞太久自动自毁
local whirlwindMissiles_selfDestruct_maxLife = 12.0

-- 自毁爆炸半径（可调；可与 hit 的爆炸半径不同）
local whirlwindMissiles_selfDestruct_explosionSize = 3.0

-- 使用 tag 给每个导弹 body 分配稳定 uid，避免句柄复用导致的状态串号
local whirlwindMissiles_selfDestruct_uidTag = "whirlwindMissiles_selfDestruct_uid"

-- 导弹状态（uid -> t）
local whirlwindMissiles_selfDestruct_timeByUid = {}



-- whirlwindMissiles_selfDestruct_findMissileBodies 描述：扫描场上所有导弹 body（tag: missile）
local function whirlwindMissiles_selfDestruct_findMissileBodies ()
    return FindBodies("missile", false) or {}
end

-- whirlwindMissiles_selfDestruct_getOrAssignUid 描述：为导弹 body 获取/分配稳定 uid（存到 tag）
local function whirlwindMissiles_selfDestruct_getOrAssignUid (missileBody)
    local uid = GetTagValue(missileBody, whirlwindMissiles_selfDestruct_uidTag)
    if uid and uid ~= "" then
        return uid
    end

    uid = tostring(missileBody) .. "_" .. tostring(math.random(100000, 999999))
    SetTag(missileBody, whirlwindMissiles_selfDestruct_uidTag, uid)
    return uid
end

-- whirlwindMissiles_selfDestruct_try 描述：若超时则在导弹当前位置自毁一次
local function whirlwindMissiles_selfDestruct_try (missileBody, dt)
    if missileBody == 0 then
        return
    end
    if HasTag(missileBody, "whirlwindMissiles_detonated") then
        return
    end

    local uid = whirlwindMissiles_selfDestruct_getOrAssignUid(missileBody)
    local t = whirlwindMissiles_selfDestruct_timeByUid[uid]
    if not t then
        t = 0
    end
    t = t + (dt or 0)
    whirlwindMissiles_selfDestruct_timeByUid[uid] = t

    if t < whirlwindMissiles_selfDestruct_maxLife then
        return
    end

    SetTag(missileBody, "whirlwindMissiles_detonated")

    local tr = GetBodyTransform(missileBody)
    local comLocal = GetBodyCenterOfMass(missileBody)
    local comWorld = TransformToParentPoint(tr, comLocal)
    Explosion(comWorld, whirlwindMissiles_selfDestruct_explosionSize)
end

-- whirlwindMissiles_selfDestruct_server_tick 描述：服务端 tick（扫描所有导弹并在超时后自毁）
local function whirlwindMissiles_selfDestruct_server_tick (dt)
    local missiles = whirlwindMissiles_selfDestruct_findMissileBodies()
    if #missiles == 0 then
        return
    end

    for i = 1, #missiles do
        whirlwindMissiles_selfDestruct_try(missiles[i], dt)
    end
end

------------------------------------------------
-- whirlwindMissiles_selfDestruct 模块 结束
------------------------------------------------

------------------------------------------------
-- whirlwindMissiles_float 模块 开始
------------------------------------------------

-- 抵消重力用的 g（Teardown 默认约 10）
local whirlwindMissiles_float_G = 10.0

-- 记录 launcherShape 初始所属 body，用于判断“仍然连接”
local whirlwindMissiles_float_launcherBody0ByShape = {}



-- whirlwindMissiles_float_findLaunchers 描述：扫描场上所有 launcherShape
local function whirlwindMissiles_float_findLaunchers ()
    return FindShapes("launcher", false) or {}
end

-- whirlwindMissiles_float_applyUpwardImpulse 描述：对导弹质心施加反重力冲量（抵消重力）
local function whirlwindMissiles_float_applyUpwardImpulse (missileBody, g, dt)
    if missileBody == 0 then return end
    if dt <= 0 then return end

    local comLocal = GetBodyCenterOfMass(missileBody)
    local t = GetBodyTransform(missileBody)
    local comWorld = TransformToParentPoint(t, comLocal)

    local up = Vec(0, 1, 0)
    local mass = GetBodyMass(missileBody)
    local impulse = VecScale(up, g * mass * dt)
    ApplyBodyImpulse(missileBody, comWorld, impulse)
end

-- whirlwindMissiles_float_server_tick 描述：服务端 tick（让导弹悬浮：持续抵消重力）
local function whirlwindMissiles_float_server_tick (dt)
    -- 需求：当 launcherShape 碎裂时，不再提供浮力。
    -- 这里遍历 launcherShape：只有 launcher 未碎裂且仍连接到导弹 body 时才施加浮力。
    local launchers = whirlwindMissiles_float_findLaunchers()
    if #launchers == 0 then
        return
    end

    local liftedByBody = {}

    for i = 1, #launchers do
        local launcherShape = launchers[i]
        if launcherShape ~= 0 and (not IsShapeBroken(launcherShape)) then
            local missileBody = GetShapeBody(launcherShape)
            if missileBody ~= 0 and HasTag(missileBody, "missile") then
                local body0 = whirlwindMissiles_float_launcherBody0ByShape[launcherShape]
                if not body0 or body0 == 0 then
                    body0 = missileBody
                    whirlwindMissiles_float_launcherBody0ByShape[launcherShape] = body0
                end

                if missileBody == body0 and (not liftedByBody[missileBody]) then
                    liftedByBody[missileBody] = true
                    whirlwindMissiles_float_applyUpwardImpulse(missileBody, whirlwindMissiles_float_G, dt)
                end
            end
        end
    end
end

------------------------------------------------
-- whirlwindMissiles_float 模块 结束
------------------------------------------------

------------------------------------------------
-- whirlwindMissiles_playPushSound 模块 开始
------------------------------------------------

-- 循环音效路径
local whirlwindMissiles_playPushSound_LOOP_PATH = "MOD/audio/launcher_loop.ogg"
local whirlwindMissiles_playPushSound_loop = 0

local whirlwindMissiles_playPushSound_MIN_VOLUME = 0.2
local whirlwindMissiles_playPushSound_MAX_VOLUME = 3.0
local whirlwindMissiles_playPushSound_SPEED_FOR_MAX_VOL = 50.0

-- 记录 launcherShape 初始所属 body，用于判断“仍然连接”
local whirlwindMissiles_playPushSound_launcherBody0ByShape = {}



-- whirlwindMissiles_playPushSound_findLaunchersAndEnsureLoopLoaded 描述：确保循环音效已加载，并返回所有 launcherShape
local function whirlwindMissiles_playPushSound_findLaunchersAndEnsureLoopLoaded ()
    if whirlwindMissiles_playPushSound_loop == 0 and whirlwindMissiles_playPushSound_LOOP_PATH ~= "" then
        whirlwindMissiles_playPushSound_loop = LoadLoop(whirlwindMissiles_playPushSound_LOOP_PATH)
    end
    return FindShapes("launcher", false) or {}
end

-- whirlwindMissiles_playPushSound_playForOneLauncher 描述：为单个 launcherShape 播放推进循环音效（仍连接才播放）
local function whirlwindMissiles_playPushSound_playForOneLauncher (launcherShape)
    if whirlwindMissiles_playPushSound_loop == 0 then
        return
    end
    if launcherShape == 0 or IsShapeBroken(launcherShape) then
        return
    end

    local missileBody = GetShapeBody(launcherShape)
    if missileBody == 0 or (not HasTag(missileBody, "missile")) then
        return
    end

    local body0 = whirlwindMissiles_playPushSound_launcherBody0ByShape[launcherShape]
    if not body0 or body0 == 0 then
        body0 = missileBody
        whirlwindMissiles_playPushSound_launcherBody0ByShape[launcherShape] = body0
    end
    if missileBody ~= body0 then
        return
    end

    local vel = GetBodyVelocity(missileBody)
    local speed = VecLength(vel)

    local norm = 0.0
    if whirlwindMissiles_playPushSound_SPEED_FOR_MAX_VOL > 0.0 then
        norm = speed / whirlwindMissiles_playPushSound_SPEED_FOR_MAX_VOL
    end
    if norm < 0.0 then norm = 0.0 end
    if norm > 1.0 then norm = 1.0 end

    local volume = whirlwindMissiles_playPushSound_MIN_VOLUME
        + (whirlwindMissiles_playPushSound_MAX_VOLUME - whirlwindMissiles_playPushSound_MIN_VOLUME) * norm

    local tShape = GetShapeWorldTransform(launcherShape)
    PlayLoop(whirlwindMissiles_playPushSound_loop, tShape.pos, volume)
end

-- whirlwindMissiles_playPushSound_client_tick 描述：客户端 tick（扫描所有导弹并播放推进循环音效）
local function whirlwindMissiles_playPushSound_client_tick (dt)
    local launchers = whirlwindMissiles_playPushSound_findLaunchersAndEnsureLoopLoaded()
    if #launchers == 0 then
        return
    end

    for i = 1, #launchers do
        whirlwindMissiles_playPushSound_playForOneLauncher(launchers[i])
    end
end

------------------------------------------------
-- whirlwindMissiles_playPushSound 模块 结束
------------------------------------------------

------------------------------------------------
-- whirlwindMissiles_setBasicSpeed 模块 开始
------------------------------------------------

-- 初速度（可调）
local whirlwindMissiles_setBasicSpeed_INITIAL_SPEED = 10.0

-- 防止重复设置初速度
local whirlwindMissiles_setBasicSpeed_doneByBody = {}



-- whirlwindMissiles_setBasicSpeed_findMissileBodies 描述：扫描场上所有导弹 body（tag: missile）
local function whirlwindMissiles_setBasicSpeed_findMissileBodies ()
    return FindBodies("missile", false) or {}
end

-- whirlwindMissiles_setBasicSpeed_applyOnce 描述：给单个导弹 body 施加一次性初速度
local function whirlwindMissiles_setBasicSpeed_applyOnce (missileBody)
    if missileBody == 0 then return end

    local t = GetBodyTransform(missileBody)
    local forward = TransformToParentVec(t, Vec(0, 0, -1))
    forward = VecNormalize(forward)

    local targetVel = VecScale(forward, whirlwindMissiles_setBasicSpeed_INITIAL_SPEED)

    local curVel = GetBodyVelocity(missileBody)
    local deltaVel = VecSub(targetVel, curVel)

    local mass = GetBodyMass(missileBody)
    local impulse = VecScale(deltaVel, mass)

    local comLocal = GetBodyCenterOfMass(missileBody)
    local comWorld = TransformToParentPoint(t, comLocal)
    ApplyBodyImpulse(missileBody, comWorld, impulse)
end

-- whirlwindMissiles_setBasicSpeed_server_init 描述：服务端 init（为场上所有导弹设置一次初速度）
local function whirlwindMissiles_setBasicSpeed_server_init ()
    local missiles = whirlwindMissiles_setBasicSpeed_findMissileBodies()
    if #missiles == 0 then
        return
    end

    for i = 1, #missiles do
        local missileBody = missiles[i]
        if missileBody ~= 0 and (not whirlwindMissiles_setBasicSpeed_doneByBody[missileBody]) then
            whirlwindMissiles_setBasicSpeed_doneByBody[missileBody] = true
            whirlwindMissiles_setBasicSpeed_applyOnce(missileBody)
        end
    end
end

------------------------------------------------
-- whirlwindMissiles_setBasicSpeed 模块 结束
------------------------------------------------

------------------------------------------------
-- whirlwindMissiles_damping 模块 开始
------------------------------------------------

-- 阻尼系数 p（可调）
local whirlwindMissiles_damping_p = 0.02

-- f = p * v^2，其中 v 为速度标量
-- 冲量 impulse = f * dt（方向为速度反方向）



-- whirlwindMissiles_damping_findMissileBodies 描述：扫描场上所有导弹 body（tag: missile）
local function whirlwindMissiles_damping_findMissileBodies ()
    return FindBodies("missile", false) or {}
end

-- whirlwindMissiles_damping_applyDragImpulse 描述：对单个导弹施加阻尼冲量（速度反方向）
local function whirlwindMissiles_damping_applyDragImpulse (missileBody, p, dt)
    if missileBody == 0 then return end
    if dt <= 0 then return end

    local vel = GetBodyVelocity(missileBody)
    local speed = VecLength(vel)
    if speed < 0.01 then
        return
    end

    local dirOpposite = VecScale(VecNormalize(vel), -1)
    local f = p * speed * speed

    local t = GetBodyTransform(missileBody)
    local comLocal = GetBodyCenterOfMass(missileBody)
    local comWorld = TransformToParentPoint(t, comLocal)

    local impulse = VecScale(dirOpposite, f * dt)
    ApplyBodyImpulse(missileBody, comWorld, impulse)
end

-- whirlwindMissiles_damping_server_tick 描述：服务端 tick（扫描所有导弹并持续施加阻尼）
local function whirlwindMissiles_damping_server_tick (dt)
    local missiles = whirlwindMissiles_damping_findMissileBodies()
    if #missiles == 0 then
        return
    end

    for i = 1, #missiles do
        local missileBody = missiles[i]
        if missileBody ~= 0 then
            whirlwindMissiles_damping_applyDragImpulse(missileBody, whirlwindMissiles_damping_p, dt)
        end
    end
end

------------------------------------------------
-- whirlwindMissiles_damping 模块 结束
------------------------------------------------

------------------------------------------------
-- 初始化
------------------------------------------------

function server.init ()
    whirlwindMissiles_setBasicSpeed_server_init()
end

function client.init ()
    whirlwindMissiles_playPushSound_findLaunchersAndEnsureLoopLoaded()
end

------------------------------------------------
-- 生命周期入口
------------------------------------------------

function server.tick (dt)
    dt = dt or 0
    whirlwindMissiles_promote_server_tick(dt)
    whirlwindMissiles_float_server_tick(dt)
    whirlwindMissiles_damping_server_tick(dt)
    whirlwindMissiles_selfDestruct_server_tick(dt)
    whirlwindMissiles_hit_server_tick(dt)
end

function client.tick (dt)
    whirlwindMissiles_playPushSound_client_tick(dt or 0)
end

function client.draw (dt)
    whirlwindMissiles_draw_client_draw(dt or 0)
end

------------------------------------------------
-- 兼容单机：如果没有联机框架，也能按 Teardown 默认 init/tick/draw 跑起来
------------------------------------------------

function init ()
    if type(server) == "table" and type(server.init) == "function" then
        server.init()
    end
    if type(client) == "table" and type(client.init) == "function" then
        client.init()
    end
end

function tick (dt)
    if type(server) == "table" and type(server.tick) == "function" then
        server.tick(dt)
    end
    if type(client) == "table" and type(client.tick) == "function" then
        client.tick(dt)
    end
end

function draw (dt)
    if type(client) == "table" and type(client.draw) == "function" then
        client.draw(dt)
    end
end