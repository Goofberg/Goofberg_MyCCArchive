rednet.open("back")

print("Please enter a Receiver ComputerID :")
local ConnectionComputerID = read()
if tonumber(ConnectionComputerID) == nil then
    print("Invalid ComputerID Format, ComputerID must be a Number")
    return
end
ConnectionComputerID = tonumber(ConnectionComputerID)

term.clear()
term.setCursorPos(1, 1)
while true do
    print("Current Commands : \n-Exit()\n-MoveForward(<AmountToMove>)\n-MoveBackward(<AmountToMove>)\n-Rotate(<Rotation>)\n-StartDrill()\n-AutoDrill(<AmountToMove&Drill>)\n-ForwardDig(<AmountToDig>)\n-AutoForwardDig(<AmountToDig>)\n-AutoForwardOnlyDig(<AmountToDig>)\n-Docked()")
    print("Enter Command :")
    local consoleRead = read()
    local command, value = consoleRead:match("^(%a+)%((.-)%)")

    if command == "Exit" then
        print("Exiting")
        rednet.send(ConnectionComputerID, consoleRead)
        break
    elseif command == "MoveForward" then
        if value == nil then print("Missing Argument") sleep(1) end
        rednet.send(ConnectionComputerID, consoleRead)
        while true do
            local MessageComputerID, MessageRequest = rednet.receive()
            if MessageComputerID == ConnectionComputerID and MessageRequest == "Finish" then
               break 
            end
        end
    elseif command == "MoveBackward" then
        if value == nil then print("Missing Argument") sleep(1) end
        rednet.send(ConnectionComputerID, consoleRead)
        while true do
            local MessageComputerID, MessageRequest = rednet.receive()
            if MessageComputerID == ConnectionComputerID and MessageRequest == "Finish" then
               break 
            end
        end
    elseif command == "Rotate" then
        if value == nil then print("Missing Argument") sleep(1) end
        rednet.send(ConnectionComputerID, consoleRead)
        while true do
            local MessageComputerID, MessageRequest = rednet.receive()
            if MessageComputerID == ConnectionComputerID and MessageRequest == "Finish" then
               break 
            end
        end
    elseif command == "StartDrill" then
        rednet.send(ConnectionComputerID, consoleRead)
        while true do
            local MessageComputerID, MessageRequest = rednet.receive()
            if MessageComputerID == ConnectionComputerID and MessageRequest == "Finish" then
               break 
            end
        end
    elseif command == "AutoDrill" then
        if value == nil then print("Missing Argument") sleep(1) end
        rednet.send(ConnectionComputerID, consoleRead)
        while true do
            local MessageComputerID, MessageRequest = rednet.receive()
            if MessageComputerID == ConnectionComputerID and MessageRequest == "Finish" then
               break 
            end
        end
    elseif command == "ForwardDig" then
        if value == nil then print("Missing Argument") sleep(1) end
        rednet.send(ConnectionComputerID, consoleRead)
        while true do
            local MessageComputerID, MessageRequest = rednet.receive()
            if MessageComputerID == ConnectionComputerID and MessageRequest == "Finish" then
               break 
            end
        end
    elseif command == "AutoForwardDig" then
        if value == nil then print("Missing Argument") sleep(1) end
        rednet.send(ConnectionComputerID, consoleRead)
        while true do
            local MessageComputerID, MessageRequest = rednet.receive()
            if MessageComputerID == ConnectionComputerID and MessageRequest == "Finish" then
               break 
            end
        end
    elseif command == "AutoForwardOnlyDig" then
        if value == nil then print("Missing Argument") sleep(1) end
        rednet.send(ConnectionComputerID, consoleRead)
        while true do
            local MessageComputerID, MessageRequest = rednet.receive()
            if MessageComputerID == ConnectionComputerID and MessageRequest == "Finish" then
               break 
            end
        end
    elseif command == "Docked" then
        if value == nil then print("Missing Argument") sleep(1) end
        rednet.send(ConnectionComputerID, consoleRead)
        while true do
            local MessageComputerID, MessageRequest = rednet.receive()
            if MessageComputerID == ConnectionComputerID and MessageRequest == "Finish" then
               break 
            end
        end
    end

    sleep(0.5)
    term.clear()
    term.setCursorPos(1, 1)
end