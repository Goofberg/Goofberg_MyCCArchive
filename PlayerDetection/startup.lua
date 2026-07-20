local cfg = require("config")

local detector = peripheral.find("player_detector")
if not detector then
    print("player_detector peripheral not found!")
    return
end

-- ===== Determine origin (this computer's own position) =====
print("Locating this computer's position via GPS...")
local ox, oy, oz = gps.locate(5)
if not ox then
    print("GPS locate failed — falling back to (0,0,0) as origin.")
    ox, oy, oz = 0, 0, 0
else
    print(("Origin set to %d %d %d"):format(ox, oy, oz))
end

local half = cfg.HALF_SIZE

-- ===== State =====
local currentInRange = {}   -- set of player names currently inside the box
local lastMessageId = nil   -- discord message id of the posted embed, for editing
local STATE_FILE = "player_watcher_state.txt"

local function saveMessageId(id)
    local f = fs.open(STATE_FILE, "w")
    f.write(tostring(id))
    f.close()
end

local function loadMessageId()
    if fs.exists(STATE_FILE) then
        local f = fs.open(STATE_FILE, "r")
        local id = f.readAll()
        f.close()
        if id and id ~= "" then return id end
    end
    return nil
end
lastMessageId = loadMessageId()

-- ===== Discord: embed via webhook (post first time, edit after) =====
local function buildEmbedPayload(playerList)
    local desc
    if #playerList == 0 then
        desc = "No players currently in range."
    else
        desc = "**Players in range:**\n" .. table.concat(playerList, "\n")
    end

    return {
        embeds = {
            {
                title = "Area Watch — 80x80x80",
                description = desc,
                color = (#playerList > 0) and 0xE67E22 or 0x2ECC71,
                footer = { text = ("Origin: %d, %d, %d"):format(ox, oy, oz) },
                timestamp = nil,
            }
        }
    }
end

local function postOrEditEmbed(playerList)
    local payload = buildEmbedPayload(playerList)
    local body = textutils.serializeJSON(payload)
    local headers = { ["Content-Type"] = "application/json" }

    if lastMessageId then
        -- Edit existing message
        local url = cfg.WEBHOOK_URL .. "/messages/" .. lastMessageId
        local resp, err = http.patch(url, body, headers)
        if resp then
            resp.close()
        else
            print("Embed edit failed, will try posting fresh: " .. tostring(err))
            lastMessageId = nil
        end
    end

    if not lastMessageId then
        -- Post new message; ?wait=true makes Discord return the message object (with id)
        local resp, err = http.post(cfg.WEBHOOK_URL .. "?wait=true", body, headers)
        if resp then
            local respBody = resp.readAll()
            resp.close()
            local ok, decoded = pcall(textutils.unserializeJSON, respBody)
            if ok and decoded and decoded.id then
                lastMessageId = decoded.id
                saveMessageId(lastMessageId)
            end
        else
            print("Embed post failed: " .. tostring(err))
        end
    end
end

-- ===== Discord: DM a specific user via bot =====
local function sendDM(userId, content)
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bot " .. cfg.BOT_TOKEN,
    }

    -- Step 1: create/fetch DM channel
    local createBody = textutils.serializeJSON({ recipient_id = userId })
    local resp, err = http.post("https://discord.com/api/v10/users/@me/channels", createBody, headers)
    if not resp then
        print("Failed to open DM channel: " .. tostring(err))
        return false
    end
    local respBody = resp.readAll()
    resp.close()
    local ok, decoded = pcall(textutils.unserializeJSON, respBody)
    if not ok or not decoded or not decoded.id then
        print("Unexpected response opening DM channel: " .. tostring(respBody))
        return false
    end
    local channelId = decoded.id

    -- Step 2: send message to that channel
    local msgBody = textutils.serializeJSON({ content = content })
    local msgResp, msgErr = http.post(
        "https://discord.com/api/v10/channels/" .. channelId .. "/messages",
        msgBody, headers
    )
    if msgResp then
        msgResp.close()
        return true
    else
        print("Failed to send DM: " .. tostring(msgErr))
        return false
    end
end

-- ===== Range check helpers =====
local function isInBox(pos)
    return pos.x >= ox - half and pos.x <= ox + half
       and pos.y >= oy - half and pos.y <= oy + half
       and pos.z >= oz - half and pos.z <= oz + half
end

local function getPlayersCurrentlyInBox()
    local result = {}
    local online = detector.getOnlinePlayers()
    for _, name in ipairs(online) do
        local ok, pos = pcall(function() return detector.getPlayerPos(name) end)
        if ok and pos then
            if isInBox(pos) then
                result[name] = true
            end
        end
    end
    return result
end

local function setToSortedList(set)
    local list = {}
    for name, _ in pairs(set) do table.insert(list, name) end
    table.sort(list)
    return list
end

local function setsEqual(a, b)
    for k in pairs(a) do if not b[k] then return false end end
    for k in pairs(b) do if not a[k] then return false end end
    return true
end

-- ===== Main loop =====
print("Watching 80x80x80 box centered on origin...")
while true do
    local newSet = getPlayersCurrentlyInBox()

    if not setsEqual(newSet, currentInRange) then
        -- Figure out who just entered
        for name, _ in pairs(newSet) do
            if not currentInRange[name] then
                print(name .. " entered range.")
                if name ~= cfg.IGNORE_NAME then
                    sendDM(cfg.DM_USER_ID, (":warning: **%s** entered the watched area."):format(name))
                end
            end
        end
        for name, _ in pairs(currentInRange) do
            if not newSet[name] then
                print(name .. " left range.")
            end
        end

        currentInRange = newSet
        postOrEditEmbed(setToSortedList(currentInRange))
    end

    sleep(cfg.CHECK_EVERY)
end
