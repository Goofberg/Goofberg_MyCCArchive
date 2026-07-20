-- Watches an 80x80x80 box centered on a static origin using player_detector
-- (Advanced Peripherals). Posts/edits a Discord embed in a specific
-- channel/server via the bot's REST API (no webhook, no websocket/gateway),
-- and DMs a specific user when anyone other than an ignored player enters range.

local cfg = require("config")

local detector = peripheral.find("player_detector")
if not detector then
    print("player_detector peripheral not found!")
    return
end

-- ===== Static origin, no GPS =====
local ox, oy, oz = cfg.ORIGIN_X, cfg.ORIGIN_Y, cfg.ORIGIN_Z
print(("Using static origin: %d %d %d"):format(ox, oy, oz))

local half = cfg.HALF_SIZE

-- ===== State =====
local currentInRange = {}
local lastMessageId = nil
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

local function botHeaders()
    return {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bot " .. cfg.BOT_TOKEN,
    }
end

-- ===== Discord: embed via bot REST API (post first time, edit after) =====
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
            }
        }
    }
end

local function postOrEditEmbed(playerList)
    local payload = buildEmbedPayload(playerList)
    local body = textutils.serializeJSON(payload)
    local headers = botHeaders()

    if lastMessageId then
        local url = "https://discord.com/api/v10/channels/" .. cfg.CHANNEL_ID .. "/messages/" .. lastMessageId
        local resp, err = http.patch(url, body, headers)
        if resp then
            resp.close()
        else
            print("Embed edit failed, will try posting fresh: " .. tostring(err))
            lastMessageId = nil
        end
    end

    if not lastMessageId then
        local url = "https://discord.com/api/v10/channels/" .. cfg.CHANNEL_ID .. "/messages"
        local resp, err = http.post(url, body, headers)
        if resp then
            local respBody = resp.readAll()
            resp.close()
            local ok, decoded = pcall(textutils.unserializeJSON, respBody)
            if ok and decoded and decoded.id then
                lastMessageId = decoded.id
                saveMessageId(lastMessageId)
            else
                print("Unexpected response posting embed: " .. tostring(respBody))
            end
        else
            print("Embed post failed: " .. tostring(err))
        end
    end
end

-- ===== Discord: DM a specific user via bot =====
local function sendDM(userId, content)
    local headers = botHeaders()

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
print(("Watching 80x80x80 box centered on static origin (%d,%d,%d)..."):format(ox, oy, oz))
while true do
    local newSet = getPlayersCurrentlyInBox()

    if not setsEqual(newSet, currentInRange) then
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
