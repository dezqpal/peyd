-- [[ 1. CONFIGURATION ]]
local WhitelistedUsers = {
    ["ingella_199"] = "10h",
    ["Potato1212960"] = "2w", -- Inilagay ko dito ang username base sa webhook mo
    ["Aiden67e3"] = "1m",
    ["primobns21"] = -1,
}

local MainScript = "https://raw.githubusercontent.com/dezqpal/Primo/refs/heads/main/V2Obfuscated.lua"
local WebhookURL = "https://discord.com/api/webhooks/1474909344918405120/rm53gdqtdcffBlwit1Bad1IV4L9b3b9yCNLjkIRKAWDuLv8E413lMUygjrAvWOMskQj9"

-- [[ 2. INTERNAL TIMER CONVERTER ]]
local function GetExpiryTimestamp(value)
    if type(value) == "number" and value == -1 then return -1 end
    
    local totalSeconds = 0
    -- Multi-unit support (para gumana ang "1d 9h")
    for amount, unit in value:gmatch("(%d+)(%a+)") do
        amount = tonumber(amount)
        if unit == "m" then totalSeconds = totalSeconds + (amount * 60)
        elseif unit == "h" then totalSeconds = totalSeconds + (amount * 3600)
        elseif unit == "d" then totalSeconds = totalSeconds + (amount * 86400)
        elseif unit == "w" then totalSeconds = totalSeconds + (amount * 604800)
        elseif unit == "mo" then totalSeconds = totalSeconds + (amount * 2592000)
        elseif unit == "y" then totalSeconds = totalSeconds + (amount * 31536000) end
    end
    
    return os.time() + totalSeconds
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
local function SendWebhook(status, expiryTimestamp)
    local leaderstats = Player:FindFirstChild("leaderstats")
    local strength = leaderstats and leaderstats:FindFirstChild("Strength") and leaderstats.Strength.Value or 0
    local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths") and leaderstats.Rebirths.Value or 0
    local agility = Player:FindFirstChild("Agility") and Player.Agility.Value or (leaderstats and leaderstats:FindFirstChild("Agility") and leaderstats.Agility.Value or 0)
    local durability = Player:FindFirstChild("Durability") and Player.Durability.Value or (leaderstats and leaderstats:FindFirstChild("Durability") and leaderstats.Durability.Value or 0)

    local executor = (identifyexecutor or getexecutorname or function() return "Unknown" end)()
    local gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name

    local countdown = "LIFETIME"
    if expiryTimestamp and expiryTimestamp ~= -1 then
        countdown = "<t:" .. tostring(expiryTimestamp) .. ":R>"
    end

    local data = {
        ["embeds"] = {{
            ["title"] = "📩 PRIMO-HUB WEBHOOK",
            ["color"] = (status:find("GRANTED") and 3066993 or 15158332),
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

    pcall(function()
        local request = (syn and syn.request) or (http and http.request) or http_request or request
        if request then
            request({
                Url = WebhookURL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(data)
            })
        end
    end)
end

-- [[ 6. AUTH LOGIC ]]
local function Authenticate()
    local myName = Player.Name:lower()
    local configValue = nil

    for user, val in pairs(WhitelistedUsers) do
        if user:lower() == myName then
            configValue = val
            break
        end
    end

    if not configValue then
        SendWebhook("ACCESS DENIED (NOT IN LIST)", nil)
        Player:Kick("Wala ka sa whitelist, paps. Username mo: " .. Player.Name)
        return
    end

    local expiry = GetExpiryTimestamp(configValue)

    if expiry ~= -1 and os.time() >= expiry then
        SendWebhook("EXPIRED (JOIN ATTEMPT)", expiry)
        task.wait(1.5)
        Player:Kick("Expired na ang access mo! Mag-renew ka na.")
        return
    end

    task.spawn(function()
        SendWebhook("ACCESS GRANTED", expiry)
    end)

    local success, content = pcall(function() return game:HttpGet(MainScript) end)
    if success and content then
        local func = loadstring(content)
        if func then 
            task.spawn(func) 
        end
    end

    if expiry ~= -1 then
        task.spawn(function()
            while task.wait(15) do
                if os.time() >= expiry then
                    -- Mag-sesend muna sa Discord bago i-kick
                    SendWebhook("TIME EXPIRED (AUTO-KICKED)", expiry)
                    task.wait(2)
                    Player:Kick("Time's Up KUMAG!.")
                    break
                end
            end
        end)
    end
end

Authenticate()
