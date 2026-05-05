local detector = peripheral.find("playerDetector")
if not detector then
  error("No playerDetector peripheral found!")
end

local webhook = "https://discord.com/api/webhooks/1501179026729992222/QF8I6F87ZpdxpMe2OHSVCzYYXLGOkODTvzd6hvFxGi7PPUMfIMoqOfuo6tLMWKXyRMoy"
local mentionUser = "<@609378018510635010>"

local playersInRange = {}

local function sendDiscordNotification(message)
  local payload = {
    content = message .. " " .. mentionUser
  }
  http.post(webhook, textutils.serializeJSON(payload), {["Content-Type"] = "application/json"})
end

while true do
  local currentPlayers = detector.getPlayersInRange(60) or {}
  local currentSet = {}
  for _, name in ipairs(currentPlayers) do
    currentSet[name] = true
    if not playersInRange[name] then
      sendDiscordNotification("This player, '" .. name .. "' has entered Generator Room Area!")
    end
  end

  for name, _ in pairs(playersInRange) do
    if not currentSet[name] then
      sendDiscordNotification("This player, '" .. name .. "' has left the Generator Room Area!")
    end
  end

  playersInRange = currentSet
  sleep(2) -- Poll every 2 seconds
end