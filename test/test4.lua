-- 非常简化的飞船控制：WASD + Shift/Ctrl 六向移动 + 自动朝向相机方向

local shipBody   -- 飞船刚体
local shipVeh    -- 飞船载具
local shipHealth = 100  -- 简单生命值：0~100

-- 音频资源
local engineLoop    -- 引擎循环音
local moveSound     -- 推进音效

local shipVelWorld = Vec(0, 0, 0)

-- 准星相关：沿飞船正前方向投射一定距离，在屏幕上画一个十字
local crosshairDistance = 200
local crosshairSize = 8

local function clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end

local function normalizeAngleDeg(a)
    return (a + 180) % 360 - 180
end

local function shortestAngleDiff(a, b)
    local d = (b - a + 180) % 360 - 180
    return d
end

local function getShipYaw(t)
    local forward = TransformToParentVec(t, Vec(0, 0, -1))
    forward = VecNormalize(forward)
    local yawRaw = math.deg(math.atan2(-forward[3], forward[1]))
    -- 调整 90 度，使得面向 -Z 时 yaw≈0，与相机坐标系对齐
    return normalizeAngleDeg(yawRaw - 90.0)
end

local function getShipPitch(t)
    local forward = TransformToParentVec(t, Vec(0, 0, -1))
    forward = VecNormalize(forward)
    local horiz = math.sqrt(forward[1] * forward[1] + forward[3] * forward[3])
    local pitch = math.deg(math.atan2(forward[2], horiz))
    return pitch
end

local function initShip()
    -- 在 xml 里：<vehicle name="ship" tags="boat ship" ...>
    shipVeh  = FindVehicle("ship")
    -- 在 xml 里：<body name="body" dynamic="true" tags="ship">
    shipBody = FindBody("ship")

    -- 载入音频（相对当前 MOD 根目录）
    -- 注意：Teardown 官方建议使用 ogg 格式，如果是其它格式请自行确认是否可用
    engineLoop = LoadLoop("MOD/audio/engine.ogg")
    moveSound  = LoadLoop("MOD/audio/move.ogg")
end

function init()
    initShip()
end

-- 处理玩家输入，返回“局部加速度”（不是速度）
local function getInputLocalAcceleration(thrustAccel, isDriving)
    local localAcc = Vec(0, 0, 0)

    if not isDriving then
        return localAcc
    end

    -- 前后（本地 Z 轴）
    if InputDown("w") then
        localAcc = VecAdd(localAcc, Vec(0, 0, -thrustAccel))
    end
    if InputDown("s") then
        localAcc = VecAdd(localAcc, Vec(0, 0,  thrustAccel))
    end

    return localAcc
end

-- 后视相机轨道半径
local camRadiusBack    = 18              -- 普通（后视）相机默认半径
local camRadius        = camRadiusBack   -- 当前使用的半径（仅后视相机使用）
local camRadiusMin     = 4               -- 最小半径
local camRadiusMax     = 40              -- 最大半径
local camZoomSpeed     = 5               -- 滚轮缩放速度
local camLerpSpeed     = 6               -- 相机平滑插值速度

-- 轨道角度（世界空间）
local camYaw           = 0               -- 当前相机绕飞船的水平角度（度）
local camPitch         = -20             -- 当前相机绕飞船的俯仰角（度）

-- 背后视角的基准角度（前置相机不再使用偏移角）
local camYawBack       = 0
local camPitchBack     = -20

-- 目标角度（用于平滑插值）
local camTargetYaw     = camYawBack
local camTargetPitch   = camPitchBack

local camAtFront = false                -- 是否处于正前方视角

local camRotateSensitivity = 0.12       -- 鼠标旋转灵敏度（改变轨道角度，仅自由观察时使用）

local aimYaw   = 0
local aimPitch = 0
local mouseSensitivity = 0.15
local maxPitch = 80
local maxYawOffset = 120     -- 相机/瞄准方向相对飞船左右最大偏角（度），避免绕到背后导致翻转

-- 右键状态：短按切换相机，长按（普通相机）自由观察
local rmbDown = false
local rmbHoldTime = 0
local freeLookActive = false       -- 仅普通相机可用：只转相机，不改飞船朝向
local longPressThreshold = 0.25    -- 判定长按的阈值（秒）

local function VecLerp(a, b, t)
    return Vec(
        a[1] + (b[1] - a[1]) * t,
        a[2] + (b[2] - a[2]) * t,
        a[3] + (b[3] - a[3]) * t
    )
end

local function updateShipRotationFromMouse(dt, isDriving, t)
    if not isDriving or not shipBody then
        return t
    end

    -- P 控制：根据当前朝向和目标朝向（相机/瞄准）之间的偏差设置角速度（水平 + 俯仰）
    local currentYaw = getShipYaw(t)
    local currentPitch = getShipPitch(t)

    local yawError = shortestAngleDiff(currentYaw, aimYaw)
    local pitchError = clamp(aimPitch - currentPitch, -maxPitch, maxPitch)

    local kP_yaw = 2.0
    local kP_pitch = 2.0
    local maxYawSpeed = 90.0   -- 最大水平角速度（度/秒）
    local maxPitchSpeed = 60.0 -- 最大俯仰角速度（度/秒）

    local yawSpeedDeg = clamp(yawError * kP_yaw, -maxYawSpeed, maxYawSpeed)
    local pitchSpeedDeg = clamp(pitchError * kP_pitch, -maxPitchSpeed, maxPitchSpeed)

    local yawSpeedRad = yawSpeedDeg * math.pi / 180.0
    local pitchSpeedRad = pitchSpeedDeg * math.pi / 180.0

    -- 在机体局部坐标中：X 为俯仰，Y 为偏航
    local localAngVel = Vec(pitchSpeedRad, yawSpeedRad, 0)
    local worldAngVel = TransformToParentVec(t, localAngVel)
    SetBodyAngularVelocity(shipBody, worldAngVel)

    return t
end

local function updateShipCamera(isDriving, mx, my, wheel)
    if isDriving and shipBody then
        local shipT = GetBodyTransform(shipBody)

        local camPos
        local camRot

        if camAtFront then
            -------------------------------------------------
            -- 前置相机：固定在飞船局部 (0, 0, -6)，不再用球面半径/偏移角
            -------------------------------------------------
            local localOffset = Vec(0, 0, -6)
            camPos = TransformToParentPoint(shipT, localOffset)

            -- 朝向仍然“朝外看”：沿从飞船指向相机的方向向外看
            local outDir = VecSub(camPos, shipT.pos)
            local outTarget = VecAdd(camPos, outDir)
            camRot = QuatLookAt(camPos, outTarget)
        else
            -------------------------------------------------
            -- 普通相机：保持原来的球面绕飞船公转 + 自由观察逻辑
            -------------------------------------------------
            -- 滚轮缩放：调整后视相机球面半径
            if wheel ~= 0 then
                camRadiusBack = clamp(camRadiusBack - wheel * camZoomSpeed, camRadiusMin, camRadiusMax)
            end
            camRadius = camRadiusBack

            -- 计算相机的目标角度
            if freeLookActive then
                -- 普通相机 + 按住右键：自由观察，只改变相机角度，不动飞船朝向
                camYaw   = camYaw   - mx * camRotateSensitivity
                camYaw   = normalizeAngleDeg(camYaw)
                camPitch = clamp(camPitch - my * camRotateSensitivity, -80, 80)
                camTargetYaw   = camYaw
                camTargetPitch = camPitch
            else
                -- 普通相机：相机跟随“瞄准方向”，在背后略微偏上
                camTargetYaw   = normalizeAngleDeg(aimYaw + camYawBack)
                -- 把相机俯仰限制在安全范围，避免视线几乎竖直导致 LookAt 翻滚
                camTargetPitch = clamp(aimPitch + camPitchBack, -80, 80)
            end

            -- 平滑插值到目标角度（包括从自由观察返回默认位置）
            -- yaw 使用“最短角度差”插值，避免跨越 -180/180 度时突然整圈翻转
            local k = math.min(1.0, camLerpSpeed * GetTimeStep())
            local yawDelta = shortestAngleDiff(camYaw, camTargetYaw)
            camYaw   = normalizeAngleDeg(camYaw + yawDelta * k)
            camPitch = camPitch + (camTargetPitch - camPitch) * k
            camPitch = clamp(camPitch, -80, 80)

            -- 计算相机世界位置：绕飞船公转
            local baseOffset = Vec(0, 0, camRadius)
            local orbitRot = QuatEuler(camPitch, camYaw, 0)
            local offsetWorld = QuatRotateVec(orbitRot, baseOffset)
            camPos = VecAdd(shipT.pos, offsetWorld)

            -- 相机看向飞船中心
            camRot = QuatLookAt(camPos, shipT.pos)
        end

        AttachCameraTo(0)
        SetCameraTransform(Transform(camPos, camRot))
    else
        AttachCameraTo(0)
    end
end

-- 音频：引擎循环 & 推进音效
local function updateShipAudio(isDriving, t)
    if not isDriving then return end

    if engineLoop then
        local engineVol = 1.0
        PlayLoop(engineLoop, t.pos, engineVol)
    end

    if moveSound then
        local speed = VecLength(shipVelWorld)
        -- 音量完全由速度决定：speed=0 → 静音，speed 越大声音越大
        local vol = clamp(speed / 30.0, 0.0, 5.0)
        PlayLoop(moveSound, t.pos, vol)
    end
end

-- 处理右键：短按切换前/后视；长按进入自由观察
local function handleRightMouseInput(dt)
    if InputPressed("rmb") then
        rmbDown = true
        rmbHoldTime = 0
    end

    if rmbDown then
        rmbHoldTime = rmbHoldTime + dt
        if (not camAtFront) and (rmbHoldTime >= longPressThreshold) and (not freeLookActive) then
            freeLookActive = true
        end
    end

    if InputReleased("rmb") then
        if rmbHoldTime < longPressThreshold then
            camAtFront = not camAtFront

            if not camAtFront then
                camTargetYaw   = normalizeAngleDeg(aimYaw + camYawBack)
                camTargetPitch = aimPitch + camPitchBack
                camYaw   = camTargetYaw
                camPitch = camTargetPitch
            end
        end

        freeLookActive = false
        rmbDown = false
    end
end

-- 更新瞄准方向（由鼠标控制）
local function updateAimFromMouseInput(isDriving, mx, my, t)
    if not isDriving or freeLookActive then
        return
    end

    aimYaw   = aimYaw   - mx * mouseSensitivity
    aimYaw   = normalizeAngleDeg(aimYaw)
    aimPitch = clamp(aimPitch - my * mouseSensitivity, -80, 80)

    local currentYaw = getShipYaw(t)
    local yawDiff = shortestAngleDiff(currentYaw, aimYaw)
    yawDiff = clamp(yawDiff, -maxYawOffset, maxYawOffset)
    aimYaw = normalizeAngleDeg(currentYaw + yawDiff)
end

local function updateShipMovement(dt, isDriving, t)
    if not shipBody then return end

    -- 以“力/冲量”的方式驱动刚体，让物理引擎自己积分速度
    local thrustAccel = 60.0   -- 期望的推力加速度（越大越猛）
    local mass = GetBodyMass(shipBody)

    -- 永久向上的抗重力力：抵消重力，让飞船基本悬浮
    local g = 10.0
    local hoverAccel = g
    local up = Vec(0, 1, 0)
    local hoverImpulse = VecScale(up, mass * hoverAccel * dt)
    ApplyBodyImpulse(shipBody, t.pos, hoverImpulse)

    -- 推进：根据输入在机体前后方向施加冲量
    local localAcc = getInputLocalAcceleration(thrustAccel, isDriving)
    if localAcc[1] ~= 0 or localAcc[2] ~= 0 or localAcc[3] ~= 0 then
        local accWorld = TransformToParentVec(t, localAcc)
        -- 冲量 ≈ m * a * dt
        local impulse = VecScale(accWorld, mass * dt)
        ApplyBodyImpulse(shipBody, t.pos, impulse)
    end

    -- 简单的线性阻力：与当前速度方向相反，避免速度无限增大
    local vel = GetBodyVelocity(shipBody)
    local speed = VecLength(vel)
    if speed > 0.001 then
        local dragCoeff = 1
        local dragImpulse = VecScale(vel, -mass * dragCoeff * dt)
        ApplyBodyImpulse(shipBody, t.pos, dragImpulse)
    end

    -- 保存当前实际速度给音频等使用
    shipVelWorld = GetBodyVelocity(shipBody)

end

-- Roll 稳定（PD 控制版）
local shipRefUp = nil

local function stabilizeShipRoll(dt, t)
    if not shipBody then return end

    -- 第一次记录参考“上方向”
    if not shipRefUp then
        local worldUp = Vec(0,1,0)
        local currentUp = VecNormalize(TransformToParentVec(t, Vec(0,1,0)))

        -- 确保参考方向永远朝世界上方，避免翻转
        if VecDot(currentUp, worldUp) < 0 then
            shipRefUp = VecScale(currentUp, -1)
        else
            shipRefUp = currentUp
        end
        return
    end

    -- 当前方向
    local upNow = VecNormalize(TransformToParentVec(t, Vec(0,1,0)))
    local forwardNow = VecNormalize(TransformToParentVec(t, Vec(0,0,-1)))

    -- 误差轴
    local errorAxis = VecCross(upNow, shipRefUp)

    -- 只取绕 forward 的分量（即 roll）
    local rollError = VecDot(errorAxis, forwardNow)

    -- 小误差直接忽略，避免微抖
    if math.abs(rollError) < 0.0005 then
        return
    end

    -------------------------------------------------
    -- PD 参数（你可以在这里调手感）
    -------------------------------------------------
    local kP = 42.0          -- 恢复强度（越大越猛）
    local kD = 5.0           -- 阻尼强度（防震荡）
    local stabilizationSpeed = 1.0  -- 全局倍率

    -- 当前角速度
    local angVel = GetBodyAngularVelocity(shipBody)
    local currentRollSpeed = VecDot(angVel, forwardNow)

    -- P 项：偏差越大 → 角速度越大
    local desiredRollSpeed = rollError * kP * stabilizationSpeed

    -- D 项：刹车
    local damping = -currentRollSpeed * kD

    -- 合成修正量
    local rollCorrection = desiredRollSpeed + damping

    -- 转成世界角速度向量
    local correctionVec = VecScale(forwardNow, rollCorrection)

    -- 叠加到当前角速度
    local newAngVel = VecAdd(angVel, VecScale(correctionVec, dt))

    SetBodyAngularVelocity(shipBody, newAngVel)
end

-- 在屏幕中心前方绘制飞船准星 HUD
local function drawShipHud()
    if not shipBody then return end

    local alive = shipHealth > 0
    local isDriving = (GetPlayerVehicle() == shipVeh) and alive
    if not isDriving then return end

    local t = GetBodyTransform(shipBody)

    -------------------------------------------------
    -- 飞船朝向准星（十字）：瞄准飞船本体正对方向
    -------------------------------------------------
    -- 取飞船本地 -Z 方向（正前方），在这个方向上投射一定距离
    local forwardLocal = Vec(0, 0, -1)
    -- 为了避免直接打到自己，从机体前方一点的位置开始发射射线
    local rayOrigin = TransformToParentPoint(t, VecScale(forwardLocal, 2))
    local forwardWorldDir = TransformToParentVec(t, forwardLocal)
    forwardWorldDir = VecNormalize(forwardWorldDir)

    -- 射线检测：如果一定距离内有障碍物，就用命中点；否则用固定距离点
    local hit, hitDist = QueryRaycast(rayOrigin, forwardWorldDir, crosshairDistance)
    local forwardWorldPoint
    if hit then
        forwardWorldPoint = VecAdd(rayOrigin, VecScale(forwardWorldDir, hitDist))
    else
        forwardWorldPoint = TransformToParentPoint(t, VecScale(forwardLocal, crosshairDistance))
    end

    -- 只在“摄像机前方”时才画十字，避免在身后也出现
    local camT = GetCameraTransform()
    local camForward = TransformToParentVec(camT, Vec(0, 0, -1))
    camForward = VecNormalize(camForward)
    local dirToPoint = VecNormalize(VecSub(forwardWorldPoint, camT.pos))
    local dot = VecDot(camForward, dirToPoint)

    if dot > 0 then
        -- 将世界坐标转换到屏幕坐标
        local sx, sy = UiWorldToPixel(forwardWorldPoint)
        if sx and sy then
            UiPush()
                UiAlign("center middle")
                UiTranslate(sx, sy)
                UiColor(1, 1, 1, 1)
                local s = crosshairSize
                local th = 1
                -- 水平线
                UiRect(s * 2, th)
                -- 垂直线
                UiRect(th, s * 2)
            UiPop()
        end
    end
end

-- 在给定位置周围生成一小团发光粒子，用来伪造“激光在发光”的效果
local function spawnLaserGlow(pos)
    -- 控制粒子偏移的半径：越大越“粗”/越散
    local radius = 0.4

    -- 一次调用生成多颗粒子，形成持续的光晕感
    for i = 1, 20 do
        ParticleReset()              -- 重置粒子参数，避免继承上一次设置
        ParticleType("plain")       -- 使用普通类型粒子
        ParticleCollide(0)           -- 不参与物理碰撞，仅作视觉特效
        ParticleRadius(0.03, 0.04)   -- 粒子半径：从 0.03 线性变化到 0.04（很细的点）
        ParticleEmissive(20, 30)       -- 自发光很强，看起来非常亮
        ParticleColor(0.5, 0, 1)     -- 粒子颜色：紫色（R,G,B）
        ParticleGravity(0)           -- 不受重力影响，悬浮在原地
        ParticleAlpha(0.5, 0.5)        -- 透明度从 0.2 逐渐衰减到 0，慢慢消失

        -- 在线附近随机一点位置，让粒子分布在激光周围形成“粗光束”
        local offset = Vec(
            (math.random() - 0.5) * 2 * radius,
            (math.random() - 0.5) * 2 * radius,
            (math.random() - 0.5) * 2 * radius
        )

        -- 在 pos+offset 位置生成粒子，初速度为 0，生命周期 0.15 秒
        SpawnParticle(VecAdd(pos, offset), Vec(0, 0, 0), 0.15)
    end
end

local function drawLaser()
    if not shipBody then return end

    -- 激光发射参数（只需要改 maxDist，段数会自动跟随）
    local muzzleLocal   = Vec(0, 0, -2)   -- 飞船本地发射点
    local dirLocal      = Vec(0, 0, -1)    -- 飞船本地前方
    local maxDist       = 100               -- 激光最远距离（可自由调）
    local segLength     = 1.0              -- 每一小段的长度（越小越细腻）
    local segments      = math.max(1, math.floor(maxDist / segLength + 0.5))
    local jitter        = 0.2              -- 随机闪烁幅度

    -- 简单 rndVec 函数
    local function rndVec(scale)
        return Vec(
            (math.random() - 0.5) * 4 * scale,
            (math.random() - 0.5) * 4 * scale,
            (math.random() - 0.5) * 4 * scale
        )
    end


    -- 转换为世界坐标
    local shipT = GetBodyTransform(shipBody)
    local muzzleWorld = TransformToParentPoint(shipT, muzzleLocal)
    local dirWorld    = TransformToParentVec(shipT, dirLocal)

    -- 射线检测：如有命中则用命中点作为激光终点，避免穿墙
    local hit, hitDist = QueryRaycast(muzzleWorld, VecNormalize(dirWorld), maxDist)
    local hitWorld
    if hit then
        hitWorld = VecAdd(muzzleWorld, VecScale(VecNormalize(dirWorld), hitDist))
    else
        hitWorld = VecAdd(muzzleWorld, VecScale(dirWorld, maxDist))
    end

    -- 只有按下左键才显示激光
    if InputDown("lmb") then
        local last = muzzleWorld
        for i = 1, segments do
            local t = i / segments
            local p = VecLerp(muzzleWorld, hitWorld, t)
            p = VecAdd(p, rndVec(jitter * t))  -- 可选随机偏移，制造闪烁效果
            DrawLine(last, p, 1, 1, 1)      -- DrawLine(from, to, thickness, r, g, b)
            spawnLaserGlow(p)
            last = p
        end
    end
end

function draw()
    drawLaser()
    drawShipHud()
end

local function updateShipTick(dt)
    if not shipBody then return end

    local alive = shipHealth > 0
    local t = GetBodyTransform(shipBody)

    local isDriving = (GetPlayerVehicle() == shipVeh) and alive

    -- 音频
    updateShipAudio(isDriving, t)

    -- 右键状态
    handleRightMouseInput(dt)

    -- 鼠标输入（用于旋转和相机）
    local mx = InputValue("mousedx") or 0
    local my = InputValue("mousedy") or 0
    local wheel = InputValue("mousewheel") or 0

    -- 更新瞄准方向（轨道相机目标）
    updateAimFromMouseInput(isDriving, mx, my, t)

    -- 根据相机/瞄准方向差异设置角速度，让飞船平滑转向目标
    t = updateShipRotationFromMouse(dt, isDriving, t)
    -- 飞船自动回正
    stabilizeShipRoll(dt, t)

    -- 根据输入更新飞船移动
    updateShipMovement(dt, isDriving, t)

    -- 更新相机（跟随飞船）
    updateShipCamera(isDriving, mx, my, wheel)
end

function tick(dt)
    updateShipTick(dt)
end


