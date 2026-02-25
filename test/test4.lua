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

local function shortestAngleDiff(a, b)
    local d = (b - a + 180) % 360 - 180
    return d
end

function init()
    -- 在 xml 里：<vehicle name="ship" tags="boat ship" ...>
    shipVeh  = FindVehicle("ship")
    -- 在 xml 里：<body name="body" dynamic="true" tags="ship">
    shipBody = FindBody("ship")

    -- 载入音频（相对当前 MOD 根目录）
    -- 注意：Teardown 官方建议使用 ogg 格式，如果是其它格式请自行确认是否可用
    engineLoop = LoadLoop("MOD/audio/engine.ogg")
    moveSound  = LoadLoop("MOD/audio/move.ogg")
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

    -- -- 左右（本地 X 轴）
    -- if InputDown("a") then
    --     localAcc = VecAdd(localAcc, Vec(-thrustAccel, 0, 0))
    -- end
    -- if InputDown("d") then
    --     localAcc = VecAdd(localAcc, Vec( thrustAccel, 0, 0))
    -- end

    -- -- 上下（本地 Y 轴）：Shift 上升，Ctrl 下降
    -- if InputDown("shift") then
    --     localAcc = VecAdd(localAcc, Vec(0,  thrustAccel, 0))
    -- end
    -- if InputDown("ctrl") then
    --     localAcc = VecAdd(localAcc, Vec(0, -thrustAccel, 0))
    -- end

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

-- 玩家“瞄准方向”（由鼠标直接控制），飞船会缓慢追随这个方向
local aimYaw   = 0
local aimPitch = 0

local shipYaw   = 0      -- 当前飞船朝向
local shipPitch = 0

local targetYaw   = 0    -- 鼠标想要的目标朝向
local targetPitch = 0

local mouseSensitivity = 0.15
local maxPitch = 80
local turnLerpSpeed = 5.0    -- 转向速度（越大越跟手，越小越“重”）
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

    -- 目标朝向：追随“瞄准方向”（由鼠标直接控制）
    targetYaw = aimYaw
    targetPitch = clamp(aimPitch, -maxPitch, maxPitch)

    -- 飞船朝向慢慢追向目标朝向
    local k = math.min(0.03, turnLerpSpeed * dt)
    local dy = shortestAngleDiff(shipYaw, targetYaw)
    shipYaw   = shipYaw   + dy * k
    shipPitch = shipPitch + (targetPitch - shipPitch) * k

    -- 用“当前飞船朝向”设旋转
    t.rot = QuatEuler(shipPitch, shipYaw, 0)
    SetBodyTransform(shipBody, t)

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
                camPitch = clamp(camPitch - my * camRotateSensitivity, -80, 80)
                camTargetYaw   = camYaw
                camTargetPitch = camPitch
            else
                -- 普通相机：相机跟随“瞄准方向”，在背后略微偏上
                camTargetYaw   = aimYaw + camYawBack
                -- 把相机俯仰限制在安全范围，避免视线几乎竖直导致 LookAt 翻滚
                camTargetPitch = clamp(aimPitch + camPitchBack, -80, 80)
            end

            -- 平滑插值到目标角度（包括从自由观察返回默认位置）
            local k = math.min(1.0, camLerpSpeed * GetTimeStep())
            camYaw   = camYaw   + (camTargetYaw   - camYaw)   * k
            camPitch = camPitch + (camTargetPitch - camPitch) * k

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
                camTargetYaw   = aimYaw + camYawBack
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
local function updateAimFromMouseInput(isDriving, mx, my)
    if not isDriving or freeLookActive then
        return
    end

    aimYaw   = aimYaw   - mx * mouseSensitivity
    aimPitch = clamp(aimPitch - my * mouseSensitivity, -80, 80)

    local yawDiff = shortestAngleDiff(shipYaw, aimYaw)
    yawDiff = clamp(yawDiff, -maxYawOffset, maxYawOffset)
    aimYaw = shipYaw + yawDiff
end

-- 输入 → 加速度 → 速度（带阻尼的六向漂移）
local function updateShipMovement(dt, isDriving, t)
    local thrustAccel = 20          -- 推力加速度（越大加速越猛）
    local drag = 0.5                -- 阻尼系数（越大越容易减速）

    local localAcc = getInputLocalAcceleration(thrustAccel, isDriving)
    local accWorld = TransformToParentVec(t, localAcc)

    shipVelWorld = VecAdd(shipVelWorld, VecScale(accWorld, dt))

    local damp = math.max(0, 1 - drag * dt)
    shipVelWorld = VecScale(shipVelWorld, damp)

    SetBodyVelocity(shipBody, shipVelWorld)
    SetBodyAngularVelocity(shipBody, Vec(0, 0, 0))
end

-- 绘制 HUD：在飞船正前方方向上画一个准星（与相机方向无关）
function draw()
    if not shipBody then return end

    local alive = shipHealth > 0
    local isDriving = (GetPlayerVehicle() == shipVeh) and alive
    if not isDriving then return end

    local t = GetBodyTransform(shipBody)

    -------------------------------------------------
    -- 1) 飞船朝向准星（十字）：瞄准飞船本体正对方向
    -------------------------------------------------
    do
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

end


function tick(dt)
    if not shipBody then return end

    local alive = shipHealth > 0
    local t = GetBodyTransform(shipBody)

    local isDriving = (GetPlayerVehicle() == shipVeh) and alive

    -- 音频
    updateShipAudio(isDriving, t)

    -- 右键状态
    handleRightMouseInput(dt)

    -- 鼠标输入（用于瞄准和相机）
    local mx = InputValue("mousedx") or 0
    local my = InputValue("mousedy") or 0
    local wheel = InputValue("mousewheel") or 0

    -- 更新瞄准方向与飞船朝向
    updateAimFromMouseInput(isDriving, mx, my)
    t = updateShipRotationFromMouse(dt, isDriving, t)

    -- 根据输入更新飞船移动
    updateShipMovement(dt, isDriving, t)

    -- 更新相机（跟随飞船）
    updateShipCamera(isDriving, mx, my, wheel)
end


