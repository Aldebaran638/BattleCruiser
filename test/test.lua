

local shipBody   -- 飞船刚体
local shipVeh    -- 飞船载具
local shipHealth = 100  -- 简单生命值：0~100

-- 飞船当前世界速度（由加速度积分出来）
local shipVelWorld = Vec(0, 0, 0)

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

    -- 左右（本地 X 轴）
    if InputDown("a") then
        localAcc = VecAdd(localAcc, Vec(-thrustAccel, 0, 0))
    end
    if InputDown("d") then
        localAcc = VecAdd(localAcc, Vec( thrustAccel, 0, 0))
    end

    -- 上下（本地 Y 轴）：Shift 上升，Ctrl 下降
    if InputDown("shift") then
        localAcc = VecAdd(localAcc, Vec(0,  thrustAccel, 0))
    end
    if InputDown("ctrl") then
        localAcc = VecAdd(localAcc, Vec(0, -thrustAccel, 0))
    end

    return localAcc
end

-- 相机参数（简单跟随视角）
-------------------------------------------------
-- 相机围绕飞船公转：始终看向飞船中心
local camRadius        = 18              -- 轨道半径
local camRadiusMin     = 4               -- 最小半径
local camRadiusMax     = 40              -- 最大半径
local camZoomSpeed     = 5               -- 滚轮缩放速度
local camLerpSpeed     = 6               -- 相机平滑插值速度

-- 轨道角度（世界空间）
local camYaw           = 0               -- 当前相机绕飞船的水平角度（度）
local camPitch         = -20             -- 当前相机绕飞船的俯仰角（度）

-- 背后/正前方视角的基准角度
local camYawBack       = 0
local camPitchBack     = -20
local camYawFront      = 180
local camPitchFront    = -5

-- 目标角度（用于平滑插值）
local camTargetYaw     = camYawBack
local camTargetPitch   = camPitchBack

local camAtFront = false                -- 是否处于正前方视角
local camTiltDeg = -10

local camRotateSensitivity = 0.12       -- 鼠标旋转灵敏度（改变轨道角度）

local shipYaw   = 0      -- 当前飞船朝向
local shipPitch = 0

local targetYaw   = 0    -- 鼠标想要的目标朝向
local targetPitch = 0

local mouseSensitivity = 0.15
local maxPitch = 80
local turnLerpSpeed = 5.0    -- 转向速度（越大越跟手，越小越“重”）

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

    -- 目标朝向：追随相机朝向
    -- 相机在圆周上的 yaw，机头应指向与相机前方相同的水平朝向
    targetYaw = camYaw
    -- 俯仰：让机头缓慢追随相机的仰角
    targetPitch = clamp(camPitch, -maxPitch, maxPitch)

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

local function updateShipCamera(isDriving)
    if isDriving and shipBody then
        -- 滚轮缩放：调整轨道半径（正前方视角保持固定半径）
        local wheel = InputValue("mousewheel") or 0
        if wheel ~= 0 and not camAtFront then
            camRadius = clamp(camRadius - wheel * camZoomSpeed, camRadiusMin, camRadiusMax)
        end

        -- 鼠标控制相机轨道角度（背后视角下）
        if not camAtFront then
            local mx = InputValue("mousedx") or 0
            local my = InputValue("mousedy") or 0
            camTargetYaw   = camTargetYaw   - mx * camRotateSensitivity
            camTargetPitch = clamp(camTargetPitch - my * camRotateSensitivity, -80, 80)
        else
            -- 正前方视角：使用预设角度
            camTargetYaw   = camYawFront
            camTargetPitch = camPitchFront
        end

        -- 平滑插值到目标角度
        local k = math.min(1.0, camLerpSpeed * GetTimeStep())
        camYaw   = camYaw   + (camTargetYaw   - camYaw)   * k
        camPitch = camPitch + (camTargetPitch - camPitch) * k

        -- 计算相机世界位置：绕飞船公转
        local shipT = GetBodyTransform(shipBody)
        local baseOffset = Vec(0, 0, camRadius)
        local orbitRot = QuatEuler(camPitch, camYaw, 0)
        local offsetWorld = QuatRotateVec(orbitRot, baseOffset)
        local camPos = VecAdd(shipT.pos, offsetWorld)

        -- 相机始终看向飞船中心
        local camRot = QuatLookAt(camPos, shipT.pos)

        AttachCameraTo(0)
        SetCameraTransform(Transform(camPos, camRot))
    else
        AttachCameraTo(0)
    end
end


function tick(dt)
    if not shipBody then return end

    -- 例如掉血测试，如果你有就保留
    -- if InputPressed("k") then shipHealth = clamp(shipHealth - 20, 0, 100) end

    local alive = shipHealth > 0
    local t = GetBodyTransform(shipBody)

    local isDriving = (GetPlayerVehicle() == shipVeh) and alive

    -- 右键短按：在背后视角和正前方视角之间切换
    if InputPressed("rmb") then
        camAtFront = not camAtFront
    end

    local rotateShip = isDriving

    -- 先根据鼠标更新飞船朝向（并写回 Transform）
    t = updateShipRotationFromMouse(dt, rotateShip, t)

    -------------------------------------------------
    -- 输入 → 加速度 → 速度（带阻尼的六向漂移）
    -------------------------------------------------
    local thrustAccel = 20          -- 推力加速度（越大加速越猛）
    local drag = 0.5                -- 阻尼系数（越大越容易减速）

    -- 1) 输入得到“局部加速度”
    local localAcc = getInputLocalAcceleration(thrustAccel, isDriving)

    -- 2) 转成世界加速度（考虑当前朝向）
    local accWorld = TransformToParentVec(t, localAcc)

    -- 3) 积分得到世界速度
    shipVelWorld = VecAdd(shipVelWorld, VecScale(accWorld, dt))

    -- 4) 简单线性阻尼：逐渐衰减速度
    local damp = math.max(0, 1 - drag * dt)
    shipVelWorld = VecScale(shipVelWorld, damp)

    -- 5) 应用到刚体
    SetBodyVelocity(shipBody, shipVelWorld)

    -- 旋转仍然完全由我们控制，防止物理乱转
    SetBodyAngularVelocity(shipBody, Vec(0, 0, 0))

    -- 更新相机（跟随飞船）
    updateShipCamera(isDriving)
end