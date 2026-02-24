function tick(dt)
    local vehicle = FindVehicle("myship")
    if vehicle == 0 then return end

    local seatPos = GetVehicleAvailableSeatPos(vehicle)

    -- 没有可用座位
    if seatPos[1] == 0 and seatPos[2] == 0 and seatPos[3] == 0 then
        return
    end

    -- 在屏幕上画一个点（调试）
    DebugCross(seatPos, 1, 0, 0)
end