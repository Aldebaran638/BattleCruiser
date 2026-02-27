local missileBody = 0
local missileHead = 0
local launcherShape = 0   -- 发射座/玻璃块所在的 shape
local launcherBody0 = 0   -- 记录最初时 launcher 所在的 body
local detonated = false
local THRUST = 15.0
local G = 10.0  -- 重力加速度

-- launcher 音乐相关
-- TODO: 把下面这个路径改成你实际的音乐文件路径
local LAUNCHER_LOOP_PATH = "MOD/audio/launcher_loop.ogg"
local launcherLoop = 0
local LAUNCHER_MIN_VOLUME = 0.2
local LAUNCHER_MAX_VOLUME = 3.0
local LAUNCHER_SPEED_FOR_MAX_VOL = 50.0   -- 当导弹速度达到该值时音量打满

-- 导引相关参数
local HOMING_RANGE = 50.0              -- 扫描玩家的最大距离
local HOMING_TURN_SPEED = 2.0          -- 期望的转向角速度（rad/s）
local HOMING_FORCE = 2.0               -- 施加在质心、用于修正飞行方向的力系数（你可以调大/调小导引强度）
local HOMING_MAX_ANGLE = 45.0          -- 导弹累计转向超过这个角度（度）后，不再继续修正
local HOMING_DETONATE_RADIUS = 5.0     -- 弹头与玩家距离小于该值时直接引爆

local homingLocked = false             -- 当前是否处于锁定状态
local homingLost = false               -- 是否已经脱锁（脱锁后不再重新锁定）
local homingTargetPos = nil            -- 当前追踪的目标位置（锁定后每帧更新）
local homingInitialForward = nil       -- 锁定瞬间导弹的前向（用来限制最大转向角）

-- 初速度配置（可调）
local MISSILE_INITIAL_SPEED = 80.0

-- 初始化，找到导弹
function init()
    missileBody = FindBody("missile", false)
    -- 这里的 "missileHead" 指的是 shape 的 tag，不是 name
    missileHead = FindShape("missileHead", false)
    -- 这里的 "launcher" 也是 shape 的 tag
    launcherShape = FindShape("launcher", false)
    if launcherShape ~= 0 then
        launcherBody0 = GetShapeBody(launcherShape)
    end

    -- 预加载 launcher 循环音乐
    if LAUNCHER_LOOP_PATH ~= "" then
        launcherLoop = LoadLoop(LAUNCHER_LOOP_PATH)
    end
    -- 给导弹设置基础速度
    SetBasicSpeed()
end

-- 给导弹施加沿局部前向的“力”（用冲量近似）
function ApplyForwardForce(body, thrust, dt)
    if body == 0 then return end

    -- 质心：局部坐标 -> 世界坐标
    local comLocal = GetBodyCenterOfMass(body)
    local t = GetBodyTransform(body)
    local comWorld = TransformToParentPoint(t, comLocal)

    -- 局部前向 -Z 轴 -> 世界方向
    local forward = TransformToParentVec(t, Vec(0,0,-1))
    forward = VecNormalize(forward)

    local mass = GetBodyMass(body)
    local impulse = VecScale(forward, thrust * mass * dt)
    ApplyBodyImpulse(body, comWorld, impulse)
end

-- 给导弹施加向上的“力”（用冲量近似），大小约为 g*m
function ApplyUpwardForce(body, g, dt)
    if body == 0 then return end

    local comLocal = GetBodyCenterOfMass(body)
    local t = GetBodyTransform(body)
    local comWorld = TransformToParentPoint(t, comLocal)

    local up = Vec(0,1,0)
    local mass = GetBodyMass(body)
    local impulse = VecScale(up, g * mass * dt)
    ApplyBodyImpulse(body, comWorld, impulse)
end

-- 只在 body 存在时起作用的导引函数
-- 行为：
--  1. 周围一定范围内扫描玩家，如果未锁定且发现玩家，则锁定一次
--  2. 锁定后，每帧更新玩家位置进行追踪；一旦玩家超出范围即视为“脱锁”，不再继续追踪
--  3. 每帧根据当前朝向与目标方向的偏差，
--     a) 通过约束角速度使 body 旋转，趋向让 -Z 轴对准目标
--     b) 在质心施加只包含局部 X/Y 分量的力（局部 Z 分量强制为 0）
function UpdateHoming(body, dt)
    -- body 不存在或已失效，直接退出
    if body == 0 or not IsHandleValid(body) then
        return
    end

    -- 已经脱锁则不再导引
    if homingLost then
        return
    end

    local tBody = GetBodyTransform(body)
    local bodyPos = tBody.pos

    -- 每帧都获取玩家当前位置
    local playerT = GetPlayerTransform()
    local playerPos = playerT.pos
    local toPlayer = VecSub(playerPos, bodyPos)
    local distToPlayer = VecLength(toPlayer)

    -- 如果还没有锁定过玩家，尝试在一定范围内扫描一次
    if not homingLocked then
        if distToPlayer <= HOMING_RANGE then
            homingLocked = true
            homingTargetPos = VecCopy(playerPos)
            -- 记录锁定瞬间的导弹前向，用于后续计算转过的角度
            local f0 = TransformToParentVec(tBody, Vec(0, 0, -1))
            homingInitialForward = VecNormalize(f0)
        else
            -- 未在范围内找到玩家，本帧不做任何导引
            return
        end
    else
        -- 已经锁定：若玩家超出范围，则脱锁并停止后续导引
        if distToPlayer > HOMING_RANGE then
            homingLocked = false
            homingLost = true
            return
        end
    end

    -- 已经锁定且仍在范围内：更新当前目标位置
    homingTargetPos = VecCopy(playerPos)

    -- 近距离起爆检测（以弹头为中心）
    if (not detonated) and missileHead ~= 0 then
        local headT = GetShapeWorldTransform(missileHead)
        local dHead = VecLength(VecSub(playerPos, headT.pos))
        if dHead <= HOMING_DETONATE_RADIUS then
            detonated = true
            Explosion(headT.pos, 1.0)
            return
        end
    end

    -- 已经锁定过，但没有有效目标位置时，直接退出（理论上不应发生）
    if not homingLocked or homingTargetPos == nil then
        return
    end

    -- 目标方向（从当前质心到当前追踪的玩家位置）
    local toTarget = VecNormalize(VecSub(homingTargetPos, bodyPos))

    -- 当前前向（body -Z 轴在世界坐标中的方向）
    local forward = TransformToParentVec(tBody, Vec(0, 0, -1))
    forward = VecNormalize(forward)

    -- 如果已经累计转向超过最大角度，则不再继续修正
    if homingInitialForward ~= nil then
        local dot = VecDot(homingInitialForward, forward)
        if dot > 1.0 then dot = 1.0 end
        if dot < -1.0 then dot = -1.0 end
        local angle = math.deg(math.acos(dot))
        if angle >= HOMING_MAX_ANGLE then
            return
        end
    end

    -- 需要绕的旋转轴：forward × toTarget
    local axis = VecCross(forward, toTarget)
    local axisLen = VecLength(axis)
    if axisLen < 0.0001 then
        -- 已大致对准，无需导引
        return
    end
    axis = VecScale(axis, 1.0 / axisLen)

    -- 将旋转轴转换到局部坐标，去掉局部 Z 分量后再变回世界坐标，
    -- 保证“作用方向”只在 body 的局部 X/Y 平面内
    local axisLocal = TransformToLocalVec(tBody, axis)
    axisLocal[3] = 0.0

    local axisWorld = TransformToParentVec(tBody, axisLocal)
    local axisWorldLen = VecLength(axisWorld)
    if axisWorldLen < 0.0001 then
        return
    end
    axisWorld = VecScale(axisWorld, 1.0 / axisWorldLen)

    -- a) 使用角速度约束让 body 旋转，趋向目标方向
    ConstrainAngularVelocity(body, 0, axisWorld, HOMING_TURN_SPEED)

    -- b) 在质心施加仅含局部 X/Y 分量的力
    local comLocal = GetBodyCenterOfMass(body)
    local comWorld = TransformToParentPoint(tBody, comLocal)
    local mass = GetBodyMass(body)

    -- 把 axisLocal 作为局部受力方向（仅 X/Y），再转换到世界坐标
    local forceDirWorld = TransformToParentVec(tBody, axisLocal)
    local fLen = VecLength(forceDirWorld)
    if fLen < 0.0001 then
        return
    end
    forceDirWorld = VecScale(forceDirWorld, 1.0 / fLen)

    local impulse = VecScale(forceDirWorld, HOMING_FORCE * mass * dt)
    ApplyBodyImpulse(body, comWorld, impulse)
end

function exploExplosion()
    if (not detonated) and missileHead ~= 0 and IsShapeBroken(missileHead) then
        detonated = true
        local t = GetShapeWorldTransform(missileHead)
        Explosion(t.pos, 3.0)   -- 半径自己调
    end
end

-- 在 launcher 尾部绘制发光/激光感的粒子尾迹
function DrawLauncherSmoke()
    -- launcher 不存在或已碎裂就不画尾迹
    if launcherShape == 0 or IsShapeBroken(launcherShape) then
        return
    end

    -- 确保 launcher 仍然隶属于原始导弹 body（和推力判定保持一致）
    local currentBody = GetShapeBody(launcherShape)
    if currentBody ~= missileBody or currentBody ~= launcherBody0 then
        return
    end

    -- 以 launcher 形状的位置作为尾迹发射点
    local tShape = GetShapeWorldTransform(launcherShape)
    local emitPos = tShape.pos

    -- 计算“往后”的方向：沿导弹前向的反方向喷出
    local backVel = Vec(0, 0, 0)
    if missileBody ~= 0 then
        local tBody = GetBodyTransform(missileBody)
        local forward = TransformToParentVec(tBody, Vec(0, 0, -1))
        forward = VecNormalize(forward)
        backVel = VecScale(forward, -5.0)  -- 尾焰大致朝导弹反向喷
    end

    -- 配置发光激光风格的粒子参数（每帧重置一次）
    ParticleReset()
    ParticleType("plain")
    -- 蓝青色高亮，略微变化
    ParticleColor(0.2, 0.8, 1.0, 0.0, 0.5, 1.0)
    -- 小而集中的光点，略微拉长
    ParticleRadius(0.04, 0.1, "smooth", 0.0, 0.8)
    ParticleAlpha(1.0, 0.0, "smooth", 0.0, 1.0)
    ParticleEmissive(6.0, 0.0)
    -- 基本不受重力影响，轻微阻尼，沿速度方向拉丝
    ParticleGravity(0.0)
    ParticleDrag(0.1)
    ParticleStretch(1.5)

    -- 在尾部附近随机生成几束光粒
    for i = 1, 4 do
        local spread = Vec((math.random() - 0.5) * 0.06,
                           (math.random() - 0.5) * 0.06,
                           (math.random() - 0.5) * 0.06)
        local p = VecAdd(emitPos, spread)

        local jitter = Vec((math.random() - 0.5) * 0.4,
                           (math.random() - 0.5) * 0.4,
                           (math.random() - 0.5) * 0.4)
        local v = VecAdd(backVel, jitter)

        local life = 0.25 + math.random() * 0.15
        SpawnParticle(p, v, life)
    end
end

function draw(dt)
    DrawLauncherSmoke()
end

-- 根据导弹速度更新 launcher 的音乐音量
function UpdateLauncherSound()
    -- 没有加载音乐或没有导弹/launcher 就不处理
    if launcherLoop == 0 or missileBody == 0 or launcherShape == 0 then
        return
    end

    -- launcher 必须存在且未碎裂，并且仍然属于原始导弹 body
    if IsShapeBroken(launcherShape) then
        return
    end
    local currentBody = GetShapeBody(launcherShape)
    if currentBody ~= missileBody or currentBody ~= launcherBody0 then
        return
    end

    -- 用导弹 body 的线速度长度作为“速度”
    local vel = GetBodyVelocity(missileBody)
    local speed = VecLength(vel)

    -- 将速度映射到 [LAUNCHER_MIN_VOLUME, LAUNCHER_MAX_VOLUME]
    local norm = 0.0
    if LAUNCHER_SPEED_FOR_MAX_VOL > 0.0 then
        norm = speed / LAUNCHER_SPEED_FOR_MAX_VOL
    end
    if norm < 0.0 then norm = 0.0 end
    if norm > 1.0 then norm = 1.0 end

    local volume = LAUNCHER_MIN_VOLUME + (LAUNCHER_MAX_VOLUME - LAUNCHER_MIN_VOLUME) * norm

    -- 用 launcher 位置作为声音位置
    local tShape = GetShapeWorldTransform(launcherShape)
    PlayLoop(launcherLoop, tShape.pos, volume)
end



function SetBasicSpeed()
    if missileBody == 0 then return end

    -- 导弹当前朝向（局部 -Z）作为初速度方向
    local t = GetBodyTransform(missileBody)
    local forward = TransformToParentVec(t, Vec(0, 0, -1))
    forward = VecNormalize(forward)

    -- 目标初速度
    local targetVel = VecScale(forward, MISSILE_INITIAL_SPEED)

    -- 用冲量把当前速度改到目标速度（一次性）
    local curVel = GetBodyVelocity(missileBody)
    local deltaVel = VecSub(targetVel, curVel)

    local mass = GetBodyMass(missileBody)
    local impulse = VecScale(deltaVel, mass)

    local comLocal = GetBodyCenterOfMass(missileBody)
    local comWorld = TransformToParentPoint(t, comLocal)
    ApplyBodyImpulse(missileBody, comWorld, impulse)

end

-- tick 主循环
function tick(dt)
    if missileBody == 0 then return end
    -- 只有当 launcher 这个玻璃块：
    -- 1）存在且尚未碎裂（IsShapeBroken 为 false）
    -- 2）仍然隶属于原来的导弹 body（没有在破坏中被转移到新 body）
    -- 时才给导弹施加向前推力

    local canThrust = true
    if launcherShape ~= 0 then
        if IsShapeBroken(launcherShape) then
            canThrust = false
        else
            local currentBody = GetShapeBody(launcherShape)
            if currentBody ~= missileBody or currentBody ~= launcherBody0 then
                canThrust = false
            end
        end
    end
    if canThrust then
        -- launcher 还在时：既提供前向推力，也提供向上的“反重力”
        ApplyForwardForce(missileBody, THRUST, dt)
        ApplyUpwardForce(missileBody, G, dt)
    end
    exploExplosion()
    -- UpdateHoming(missileBody, dt)
    UpdateLauncherSound()
end