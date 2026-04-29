function ConnectRedstoneGet(OutputOutlet, OutputID)
    return function ()
        return OutputOutlet.getInput(OutputID)
    end
end
function ConnectRedstoneSet(OutputOutlet, OutputID)
    return function (state)
        OutputOutlet.setOutput(OutputID, state)
    end
end


local BaseTopControl = peripheral.wrap("Create_SequencedGearshift_3")
local BaseBottomControl = peripheral.wrap("Create_SequencedGearshift_2")
local RotationGear = peripheral.wrap("Create_SequencedGearshift_1")
local SidewayTopControl = peripheral.wrap("Create_SequencedGearshift_0")

local M1RedstoneIntegrator = peripheral.wrap("redstoneIntegrator_2")
local M2RedstoneIntegrator = peripheral.wrap("redstoneIntegrator_1")
local M3RedstoneIntegrator = peripheral.wrap("redstoneIntegrator_0")

--Computer Redstone
local BaseMinerGearShift = ConnectRedstoneSet(redstone, "left")
local SidewayMinerGearShift = ConnectRedstoneSet(redstone, "right")
-- M1
local BaseTopStickyControl = ConnectRedstoneSet(M1RedstoneIntegrator, "front")
local BaseBottomStickyControl = ConnectRedstoneSet(M1RedstoneIntegrator, "back")
local BaseDrillStateChangeReceiver = ConnectRedstoneGet(M1RedstoneIntegrator, "left")
local RotationStickyControl = ConnectRedstoneSet(M1RedstoneIntegrator, "right")
local BaseDrillReachedTopReceiver = ConnectRedstoneGet(M1RedstoneIntegrator, "top")
-- M2
local SidewayDrillReachedTopReceiver = ConnectRedstoneGet(M2RedstoneIntegrator, "front")
local SidewayBottomControl = ConnectRedstoneSet(M2RedstoneIntegrator, "back")
local SidewayBottomReceiver = ConnectRedstoneGet(M2RedstoneIntegrator, "left")
local StorageFullReceiver = ConnectRedstoneGet(M2RedstoneIntegrator, "top")
-- M3
local SidewayTopStickyControl = ConnectRedstoneSet(M3RedstoneIntegrator, "front")
local SidewayBottomStickyControl = ConnectRedstoneSet(M3RedstoneIntegrator, "back")
local SidewayNBottomStickyControl = ConnectRedstoneSet(M3RedstoneIntegrator, "left")
local SidewarDrillTouchedBottomReceiver = ConnectRedstoneGet(M3RedstoneIntegrator, "right")
local DrillStateControl = ConnectRedstoneSet(M3RedstoneIntegrator, "top")

local IsDocked = settings.get("IsDocked", false)
local BaseMinerState = "Idle"
local BaseMovementState = settings.get("BaseMovementState", "Forward")
local SidewayMinerState = "Idle"
local SidewayMovementState = settings.get("SidewayMovementState", "Forward")
local IsStorageNeedEmptied = false

function SwitchRedstoneOutput(Function)
    Function(true)
    sleep(0.1)
    Function(false)
    sleep(0.2)
end
function AwaitForActionFinished(SequencedGearshiftPeripheral)
    if not SequencedGearshiftPeripheral then return end
    repeat
        sleep(0.1)
    until SequencedGearshiftPeripheral.isRunning() == false
end

function Undocked()
    if IsDocked == false then return end
    SwitchRedstoneOutput(SidewayNBottomStickyControl)
    SwitchRedstoneOutput(BaseTopStickyControl)
    SwitchRedstoneOutput(SidewayTopStickyControl)
    SwitchRedstoneOutput(DrillStateControl)
    SwitchRedstoneOutput(RotationStickyControl)
    IsDocked = false
    settings.set("IsDocked", IsDocked)
    settings.save()
end
function Docked()
    if IsDocked == true then return end
    SwitchRedstoneOutput(SidewayNBottomStickyControl)
    SwitchRedstoneOutput(BaseTopStickyControl)
    SwitchRedstoneOutput(SidewayTopStickyControl)
    SwitchRedstoneOutput(DrillStateControl)
    SwitchRedstoneOutput(RotationStickyControl)
    IsDocked = true
    settings.set("IsDocked", IsDocked)
    settings.save()
end

function StorageCheckNStop()
    if not IsStorageNeedEmptied then return end
    print("Inventory Is Too Full for Continuation.")
    print("Please Empty and Enter 'Y' to Continue.")
    while true do
        local consoleRead = read()
        if consoleRead:lower() == "y" then
            return
        else
            print("Invalid Input, Please Enter 'Y' to Continue.")
        end
    end
end

function Rotate(value)
    local baseAngles = {90, 180, 270, 360}
    local closestAngle = baseAngles[1]
    local sign = value < 0 and -1 or 1
    local smallestDiff = math.huge

    for _, angle in ipairs(baseAngles) do
        local diffPos = math.abs(value - angle)
        local diffNeg = math.abs(value + angle)

        if diffPos < smallestDiff then
            smallestDiff = diffPos
            closestAngle = angle
            sign = 1
        end
        if diffNeg < smallestDiff then
            smallestDiff = diffNeg
            closestAngle = angle
            sign = -1
        end
    end


    SwitchRedstoneOutput(SidewayNBottomStickyControl)
    SwitchRedstoneOutput(BaseTopStickyControl)
    SwitchRedstoneOutput(SidewayTopStickyControl)
    SwitchRedstoneOutput(DrillStateControl)
    
    RotationGear.rotate(closestAngle, sign)
    AwaitForActionFinished(RotationGear)
    
    SwitchRedstoneOutput(SidewayNBottomStickyControl)
    SwitchRedstoneOutput(BaseTopStickyControl)
    SwitchRedstoneOutput(SidewayTopStickyControl)
    SwitchRedstoneOutput(DrillStateControl)
end

function SidewayDrill(amount)
    amount = amount or 9
    sleep(1)
    local function move()
        if SidewayMovementState == "Forward" then
            SwitchRedstoneOutput(SidewayBottomStickyControl)
            SidewayBottomControl(true)
            repeat
                sleep(0.1)
            until SidewayBottomReceiver() == true
            SwitchRedstoneOutput(SidewayBottomStickyControl)

            SwitchRedstoneOutput(SidewayTopStickyControl)
            SidewayTopControl.move(2, -1)
            AwaitForActionFinished(SidewayTopControl)
            SwitchRedstoneOutput(SidewayTopStickyControl)
            
            SidewayBottomControl(false)
            repeat
                sleep(0.1)
            until SidewayBottomReceiver() == false
            sleep(0.3)
            SidewayTopControl.move(2, 1)
            AwaitForActionFinished(SidewayTopControl)
        elseif SidewayMovementState == "Backward" then
            SwitchRedstoneOutput(SidewayTopStickyControl)
            SidewayTopControl.move(2, 1)
            AwaitForActionFinished(SidewayTopControl)
            SwitchRedstoneOutput(SidewayTopStickyControl)

            SwitchRedstoneOutput(SidewayBottomStickyControl)
            SidewayBottomControl(false)
            repeat
                sleep(0.1)
            until SidewayBottomReceiver() == false
            sleep(0.3)
            SwitchRedstoneOutput(SidewayBottomStickyControl)
            
            SidewayBottomControl(true)
            repeat
                sleep(0.1)
            until SidewayBottomReceiver() == true
            SidewayTopControl.move(2, -1)
            AwaitForActionFinished(SidewayTopControl)
        end
    end
    local function changedDirection()
        if SidewayMovementState == "Forward" then
            SidewayBottomControl(true)
            repeat
                sleep(0.1)
            until SidewayBottomReceiver() == true
            SidewayTopControl.move(2, -1)
            AwaitForActionFinished(SidewayTopControl)
            SidewayMovementState = "Backward"
        else
            SidewayBottomControl(false)
            repeat
                sleep(0.1)
            until SidewayBottomReceiver() == false
            sleep(0.3)
            SidewayTopControl.move(2, 1)
            AwaitForActionFinished(SidewayTopControl)
            SidewayMovementState = "Forward"
        end
        settings.set("SidewayMovementState", SidewayMovementState)
        settings.save()
    end
    
    StorageCheckNStop()

    if SidewayMovementState == "Backward" then changedDirection() end
    move()
    move()

    amount= amount - 1

    for i = 1, amount do
        StorageCheckNStop()
        move()
        SidewayMinerGearShift(true)
        SidewayMinerState = "Drilling"
        repeat
            sleep(0.1)
        until SidewayMinerState == "DrillNeedStop"
        SidewayMinerGearShift(false)
        SidewayMinerState = "RetractingDrill"
        repeat
            sleep(0.1)
        until SidewayMinerState == "Idle"
        sleep(0.5)
    end

    changedDirection()

    for i = 1, amount+2 do
        move()
        sleep(0.5)
    end

    changedDirection()
end

function ChangedDirection()
    if BaseMovementState == "Forward" then
        BaseBottomControl.move(2, -1)
        AwaitForActionFinished(BaseBottomControl)
        BaseTopControl.move(2, 1)
        AwaitForActionFinished(BaseTopControl)
        BaseMovementState = "Backward"
    else
        BaseBottomControl.move(2, 1)
        AwaitForActionFinished(BaseBottomControl)
        BaseTopControl.move(2, -1)
        AwaitForActionFinished(BaseTopControl)
        BaseMovementState = "Forward"
    end
    settings.set("BaseMovementState", BaseMovementState)
    settings.save()
end

function MoveForward(amount)
    SwitchRedstoneOutput(SidewayNBottomStickyControl)
    SwitchRedstoneOutput(SidewayTopStickyControl)
    SwitchRedstoneOutput(RotationStickyControl)
    SwitchRedstoneOutput(DrillStateControl)
    
    amount = amount or 1
    for i = 1, amount do
        if BaseMovementState == "Forward" then
            SwitchRedstoneOutput(BaseBottomStickyControl)
            BaseBottomControl.move(2, 1)
            AwaitForActionFinished(BaseBottomControl)
            SwitchRedstoneOutput(BaseBottomStickyControl)

            SwitchRedstoneOutput(BaseTopStickyControl)
            BaseTopControl.move(2, -1)
            AwaitForActionFinished(BaseTopControl)
            SwitchRedstoneOutput(BaseTopStickyControl)
            
            BaseBottomControl.move(2, -1)
            AwaitForActionFinished(BaseBottomControl)
            BaseTopControl.move(2, 1)
            AwaitForActionFinished(BaseTopControl)
        elseif BaseMovementState == "Backward" then
            SwitchRedstoneOutput(BaseBottomStickyControl)
            BaseBottomControl.move(2, -1)
            AwaitForActionFinished(BaseBottomControl)
            SwitchRedstoneOutput(BaseBottomStickyControl)

            SwitchRedstoneOutput(BaseTopStickyControl)
            BaseTopControl.move(2, 1)
            AwaitForActionFinished(BaseTopControl)
            SwitchRedstoneOutput(BaseTopStickyControl)
            
            BaseBottomControl.move(2, 1)
            AwaitForActionFinished(BaseBottomControl)
            BaseTopControl.move(2, -1)
            AwaitForActionFinished(BaseTopControl)
        end
        sleep(0.5)
    end

    SwitchRedstoneOutput(SidewayNBottomStickyControl)
    SwitchRedstoneOutput(SidewayTopStickyControl)
    SwitchRedstoneOutput(RotationStickyControl)
    SwitchRedstoneOutput(DrillStateControl)
end

function StartDrill()
    BaseMinerGearShift(true)

    BaseMinerState = "Drilling"
    repeat
        sleep(0.1)
    until BaseMinerState == "DrillStopped"
    BaseMinerGearShift(false)
    BaseMinerState = "RetractingDrill"
    repeat
        sleep(0.1)
    until BaseMinerState == "Idle"
end

function EventThread()
    while true do
        if BaseDrillStateChangeReceiver() == true and BaseMinerState == "Drilling" then
            BaseMinerState = "DrillStopped"
        end
        if BaseDrillReachedTopReceiver() == true and BaseMinerState == "RetractingDrill" then
            BaseMinerState = "Idle"
        end
        if SidewarDrillTouchedBottomReceiver() == true and SidewayMinerState == "Drilling" then
            SidewayMinerState = "DrillNeedStop"
        end
        if SidewayDrillReachedTopReceiver() == true and SidewayMinerState == "RetractingDrill" then
            SidewayMinerState = "Idle"
        end
        IsStorageNeedEmptied = StorageFullReceiver()
        sleep()
    end
end

function RednetConnection(RednetSide)
    local successRednetConnection, errRednetConnection = pcall(function()
        print(type(RednetSide))
        rednet.open(RednetSide)
    end)
    if not successRednetConnection then print("Unable to open rednet, error : ", errRednetConnection) return end
    print("Rednet has Open!")
    print("Inbound Message Started.")
    while true do
        local MessageComputerID, MessageRequest = rednet.receive()
        local command, value = MessageRequest:match("^(%a+)%((.-)%)")
        print("Message From Computer#"..MessageComputerID.." With message '"..MessageRequest.."'")

        if command == "MoveForward" then
            if value == nil then print("Missing Argument") sleep(1) end
            Undocked()
            if BaseMovementState == "Backward" then ChangedDirection() end
            MoveForward(tonumber(value))
            rednet.send(MessageComputerID, "Finish")
        elseif command == "MoveBackward" then
            if value == nil then print("Missing Argument") sleep(1) end
            Undocked()
            if BaseMovementState == "Forward" then ChangedDirection() end
            MoveForward(tonumber(value))
            rednet.send(MessageComputerID, "Finish")
        elseif command == "Rotate" then
            if value == nil then print("Missing Argument") sleep(1) end
            Undocked()
            Rotate(tonumber(value))
            rednet.send(MessageComputerID, "Finish")
        elseif command == "StartDrill" then
            Undocked()
            StartDrill()
            rednet.send(MessageComputerID, "Finish")
        elseif command == "AutoDrill" then
            if value == nil then print("Missing Argument") sleep(1) end
            Undocked()
            if BaseMovementState == "Backward" then ChangedDirection() end
            for i = 1, tonumber(value) do
                StorageCheckNStop()
                StartDrill()
                MoveForward(9)
                print("Finish Forward, Current Index : #"..i)
            end
            StartDrill()
            rednet.send(MessageComputerID, "Finish")
        elseif command == "ForwardDig" then
            if value == nil then print("Missing Argument") sleep(1) end
            Undocked()
            SidewayDrill(tonumber(value))
            rednet.send(MessageComputerID, "Finish")
        elseif command == "AutoForwardDig" then
            if value == nil then print("Missing Argument") sleep(1) end
            Undocked()
            if BaseMovementState == "Backward" then ChangedDirection() end
            for i = 1, tonumber(value) do
                StorageCheckNStop()
                StartDrill()
                SidewayDrill(9)
                MoveForward(9)
                print("Finish Forward, Current Index : #"..i)
            end
            rednet.send(MessageComputerID, "Finish")
        elseif command == "AutoForwardOnlyDig" then
            if value == nil then print("Missing Argument") sleep(1) end
            Undocked()
            if BaseMovementState == "Backward" then ChangedDirection() end
            for i = 1, tonumber(value) do
                StorageCheckNStop()
                SidewayDrill(9)
                MoveForward(9)
                print("Finish Forward, Current Index : #"..i)
            end
            rednet.send(MessageComputerID, "Finish")
        elseif command == "Docked" then
            if value == nil then print("Missing Argument") sleep(1) end
            Undocked()
            if IsDocked == false then
                Docked()
            end
            rednet.send(MessageComputerID, "Finish")
        elseif command == "Exit" then
            print("Inbound Connection Exiting")
            rednet.send(MessageComputerID, "Finish")
            break
        end
    end
end

function MainThread()
    term.clear()
    term.setCursorPos(1, 1)
    while true do
        StorageCheckNStop()
        print("Current Commands : \n-Exit()\n-MoveForward(<AmountToMove>)\n-MoveBackward(<AmountToMove>)\n-Rotate(<Rotation>)\n-StartDrill()\n-AutoDrill(<AmountToMove&Drill>)\n-ForwardDig(<AmountToDig>)\n-AutoForwardDig(<AmountToDig>)\n-AutoForwardOnlyDig(<AmountToDig>)\n-Docked()\n-WirelessConnection(<Rednet Side>)")
        print("Enter Command :")
        local consoleRead = read()
        local command, value = consoleRead:match("^(%a+)%((.-)%)")

        if command == "Exit" then
            print("Exiting")
            break
        elseif command == "MoveForward" then
            if value == nil then print("Missing Argument") sleep(1) end
            Undocked()
            if BaseMovementState == "Backward" then ChangedDirection() end
            MoveForward(tonumber(value))
        elseif command == "MoveBackward" then
            if value == nil then print("Missing Argument") sleep(1) end
            Undocked()
            if BaseMovementState == "Forward" then ChangedDirection() end
            MoveForward(tonumber(value))
        elseif command == "Rotate" then
            if value == nil then print("Missing Argument") sleep(1) end
            Undocked()
            Rotate(tonumber(value))
        elseif command == "StartDrill" then
            Undocked()
            StartDrill()
        elseif command == "AutoDrill" then
            if value == nil then print("Missing Argument") sleep(1) end
            Undocked()
            if BaseMovementState == "Backward" then ChangedDirection() end
            for i = 1, tonumber(value) do
                StorageCheckNStop()
                StartDrill()
                MoveForward(9)
                print("Finish Forward, Current Index : #"..i)
            end
            StartDrill()
        elseif command == "ForwardDig" then
            if value == nil then print("Missing Argument") sleep(1) end
            Undocked()
            SidewayDrill(tonumber(value))
        elseif command == "AutoForwardDig" then
            if value == nil then print("Missing Argument") sleep(1) end
            Undocked()
            if BaseMovementState == "Backward" then ChangedDirection() end
            for i = 1, tonumber(value) do
                StorageCheckNStop()
                StartDrill()
                SidewayDrill(9)
                MoveForward(9)
                print("Finish Forward, Current Index : #"..i)
            end
        elseif command == "AutoForwardOnlyDig" then
            if value == nil then print("Missing Argument") sleep(1) end
            Undocked()
            if BaseMovementState == "Backward" then ChangedDirection() end
            for i = 1, tonumber(value) do
                StorageCheckNStop()
                SidewayDrill(9)
                MoveForward(9)
                print("Finish Forward, Current Index : #"..i)
            end
        elseif command == "Docked" then
            if value == nil then print("Missing Argument") sleep(1) end
            Undocked()
            if IsDocked == false then
                Docked()
            end
        elseif command == "WirelessConnection" then
            if value == nil then print("Missing Argument") sleep(1) end
            RednetConnection(value)
        end

        sleep(0.5)
        term.clear()
        term.setCursorPos(1, 1)
    end
end

parallel.waitForAll(EventThread, MainThread)