      -- [[ 1. CONFIGURATION ]]
local WhitelistedUsers = {
    -- Pwede mo i-set gamit ang "m" (minutes), "h" (hours), "d" (days)
    ["rip_senku50"]   = "1m",   -- 1 Minute Trial
    ["gianroil3"] = "1m",  -- 24 Hours
    ["John_Zedrick"]  = -1,     -- Lifetime Access
}

local MainScript = "https://raw.githubusercontent.com/dezqpal/Primo/refs/heads/main/V2Obfuscated.lua"
local WebhookURL = "https://discord.com/api/webhooks/1474909344918405120/rm53gdqtdcffBlwit1Bad1IV4L9b3b9yCNLjkIRKAWDuLv8E413lMUygjrAvWOMskQj9"

-- [[ 2. INTERNAL TIMER CONVERTER ]]
local function GetExpiryTimestamp(value)
    if type(value) == "number" and value == -1 then return -1 end
    local amount = tonumber(value:match("%d+"))
    local unit = value:match("%a")
    local seconds = 0
    if unit == "m" then seconds = amount * 60
    elseif unit == "h" then seconds = amount * 3600
    elseif unit == "d" then seconds = amount * 86400 end
    return os.time() + seconds
end

-- [[ 3. SERVICES ]]
local Player = game:GetService("Players").LocalPlayer
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

-- [[ 4. FORMATTER ]]
local function FormatNumber(value)
    value = tonumber(value) or 0
    local suffixes = {"", "K", "M", "B", "T", "QA", "QI"}
    local index = 1
    while value >= 1000 and index < #suffixes do
        value = value / 1000
        index = index + 1
    end
    return string.format("%.2f%s", value, suffixes[index]):gsub("%.00", "")
end

-- [[ 5. ENHANCED WEBHOOK ]]
local function SendEnhancedWebhook(status, expiryTimestamp)
    local leaderstats = Player:FindFirstChild("leaderstats")
    local strength = leaderstats and leaderstats:FindFirstChild("Strength") and leaderstats.Strength.Value or 0
    local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths") and leaderstats.Rebirths.Value or 0
    local agility = Player:FindFirstChild("Agility") and Player.Agility.Value or (leaderstats and leaderstats:FindFirstChild("Agility") and leaderstats.Agility.Value or 0)
    local durability = Player:FindFirstChild("Durability") and Player.Durability.Value or (leaderstats and leaderstats:FindFirstChild("Durability") and leaderstats.Durability.Value or 0)

    local executor = (identifyexecutor or getexecutorname or function() return "Unknown" end)()
    local gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name

    -- LIVE COUNTDOWN FORMAT (<t:TIMESTAMP:R>)
    local countdown = "LIFETIME"
    if expiryTimestamp and expiryTimestamp ~= -1 then
        countdown = "<t:" .. tostring(expiryTimestamp) .. ":R>"
    end

    local data = {
        ["embeds"] = {{
            ["title"] = "📩 PRIMO-HUB WEBHOOK",
            ["color"] = (status == "ACCESS GRANTED" and 3066993 or 15158332),
            ["fields"] = {
                {["name"] = "👤 Display Name", ["value"] = Player.DisplayName, ["inline"] = true},
                {["name"] = "🔹 Username", ["value"] = Player.Name, ["inline"] = true},
                {["name"] = "🆔 Player ID", ["value"] = tostring(Player.UserId), ["inline"] = false},
                {["name"] = "⏳ Whitelist Expiry", ["value"] = countdown, ["inline"] = true},
                {["name"] = "💪 Strength", ["value"] = FormatNumber(strength), ["inline"] = true},
                {["name"] = "♻️ Rebirths", ["value"] = FormatNumber(rebirths), ["inline"] = true},
                {["name"] = "🛡️ Durability", ["value"] = FormatNumber(durability), ["inline"] = true},
                {["name"] = "⚡ Agility", ["value"] = FormatNumber(agility), ["inline"] = true},
                {["name"] = "🎮 Game Name", ["value"] = "💪 " .. gameName, ["inline"] = false},
                {["name"] = "⚙️ Executor", ["value"] = "🛠️ " .. executor, ["inline"] = true}
            },
            ["footer"] = {["text"] = "Status: " .. status .. " | " .. os.date("%Y-%m-%d %H:%M:%S")},
            ["thumbnail"] = {["url"] = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. Player.UserId .. "&width=420&height=420&format=png"}
        }}
    }
    
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if req then
        pcall(function()
            req({
                Url = WebhookURL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(data)
            })
        end)
    end
end

-- [[ 6. AUTH LOGIC ]]
local function Authenticate()
    local name = Player.Name
    local configValue = WhitelistedUsers[name]

    if not configValue then
        SendEnhancedWebhook("ACCESS DENIED", nil)
        Player:Kick("Wala ka sa whitelist.")
        return
    end

    local expiry = GetExpiryTimestamp(configValue)

    -- Check if already expired before joining
    if expiry ~= -1 and os.time() >= expiry then
        SendEnhancedWebhook("EXPIRED / KICKED", expiry)
        task.wait(0.5) -- Wait para makasend ang webhook bago ang kick
        Player:Kick("Expired na ang access mo!")
        return
    end

    -- Access Granted
    SendEnhancedWebhook("ACCESS GRANTED", expiry)
    loadstring(game:HttpGet(MainScript))()

    -- Live Monitoring for Auto-Kick
    if expiry ~= -1 then
        task.spawn(function()
            while task.wait(5) do
                if os.time() >= expiry then
                    -- Send webhook muna bago i-kick!
                    SendEnhancedWebhook("TIME EXPIRED (AUTO-KICK)", expiry)
                    task.wait(1)
                    Player:Kick("Subscription Time Up! UBOS TIME MO KUMAG!.")
                    break
                end
            end
        end)
    end
end

Authenticate()
