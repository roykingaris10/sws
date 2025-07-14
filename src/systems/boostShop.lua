-- Services
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- DataStores
local BoostsDataStore = DataStoreService:GetDataStore("BoostsDataStore")

-- Remote folders & modules
local BoostsShopFolder = ReplicatedStorage:WaitForChild("BoostsShopFolder")
local ToA = require(ReplicatedStorage.GameClient.Modules:WaitForChild("TableOfAssets"))

-- Gamepass ID lookup
local gamepassId = ToA.gamepasses["SpeedBoost"].id

-- Remotes for each boost category
local SpeedRemote    = BoostsShopFolder:WaitForChild("SpeedRemote")
local CoinBRemote    = BoostsShopFolder:WaitForChild("CoinBRemote")
local GemBRemote     = BoostsShopFolder:WaitForChild("GemBRemote")
local JumpBRemote    = BoostsShopFolder:WaitForChild("JumpBRemote")
local WitchBRemote   = BoostsShopFolder:WaitForChild("WitchBRemote")
local GhostBRemote   = BoostsShopFolder:WaitForChild("GhostBRemote")

-- Client-feedback events
local SpeedBoughtT1, SpeedBoughtT2 = BoostsShopFolder.SpeedBoughtT1, BoostsShopFolder.SpeedBoughtT2
local CoinBoostT1,   CoinBoostT2   = BoostsShopFolder.CoinBoostT1,   BoostsShopFolder.CoinBoostT2
local GemBoostT1,    GemBoostT2    = BoostsShopFolder.GemBoostT1,    BoostsShopFolder.GemBoostT2
local JumpBoostT1,   JumpBoostT2   = BoostsShopFolder.JumpBoostT1,   BoostsShopFolder.JumpBoostT2
local WitchBoostT1,  WitchBoostT2  = BoostsShopFolder.WitchBoostT1,  BoostsShopFolder.WitchBoostT2
local GhostBoostT1,  GhostBoostT2  = BoostsShopFolder.GhostBoostT1,  BoostsShopFolder.GhostBoostT2

-- Particle attachments for visual feedback
local CoinParticle   = ReplicatedStorage.Particles:WaitForChild("CoinParticle")
local JumpParticle   = ReplicatedStorage.Particles:WaitForChild("JumpParticle")
local SpeedParticle  = ReplicatedStorage.Particles:WaitForChild("SpeedParticle")
local WitchParticle  = ReplicatedStorage.Particles:WaitForChild("WitchParticle")
local GhostParticle  = ReplicatedStorage.Particles:WaitForChild("GhostParticle")

local CoinAttachment  = CoinParticle.Attachment
local JumpAttachment  = JumpParticle.Attachment
local SpeedAttachment = SpeedParticle.Attachment
local WitchAttachment = WitchParticle.Attachment
local GhostAttachment = GhostParticle.Attachment

-- Default & tier settings
local defaultspeed   = 16
local tier1speed     = 30
local tier2speed     = 50
local defaultjump    = 50
local tier1jump      = 100
local tier2jump      = 150
local T1Price        = 50
local T2Price        = 120

-- Helper: checks and deducts currency, returns true if player can afford
local function chargeIfAffordable(player, amount)
    if player.leaderstats.Gems.Value >= amount then
        player.leaderstats.Gems.Value -= amount
        return true
    end
    return false
end

--------------------------------------------------------------------------------
-- Speed Boost Handler
--------------------------------------------------------------------------------
SpeedRemote.OnServerEvent:Connect(function(player, boostName)
    local char     = player.Character
    local humanoid = char and char:FindFirstChild("Humanoid")
    if not humanoid then return end

    -- Grab usage flags from the character’s BoostsFolder
    local folder       = char:WaitForChild("BoostsFolder")
    local usedT1       = folder.SpeedT1Used
    local usedT2       = folder.SpeedT2Used
    local nameValue    = folder.BoostName

    nameValue.Value = boostName
    if boostName == "Default" or usedT1.Value or usedT2.Value then return end

    -- Tier 1 speed
    if boostName == "SpeedT1" and chargeIfAffordable(player, T1Price) then
        usedT1.Value = true
        SpeedBoughtT1:FireClient(player)
        -- attach particle
        local attachment = SpeedAttachment:Clone()
        attachment.Parent = char.LowerTorso
        game.Debris:AddItem(attachment, 300)

        -- apply speed, boost gamepass owners further
        humanoid.WalkSpeed = (MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId) and 60) or tier1speed

        wait(300)  -- duration of boost
        humanoid.WalkSpeed = (MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId) and tier1speed) or defaultspeed
        usedT1.Value = false

    -- Tier 2 speed
    elseif boostName == "SpeedT2" and chargeIfAffordable(player, T2Price) then
        usedT2.Value = true
        SpeedBoughtT2:FireClient(player)
        local attachment = SpeedAttachment:Clone()
        attachment.Parent = char.LowerTorso
        game.Debris:AddItem(attachment, 600)

        humanoid.WalkSpeed = (MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId) and (tier2speed + 30)) or tier2speed

        wait(600)
        humanoid.WalkSpeed = (MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId) and 30) or defaultspeed
        usedT2.Value = false
    end
end)

--------------------------------------------------------------------------------
-- Coin Boost Handler
--------------------------------------------------------------------------------
CoinBRemote.OnServerEvent:Connect(function(player, boostName)
    local char = player.Character
    local folder = char:WaitForChild("BoostsFolder")
    local usedT1, usedT2 = folder.CoinT1Used, folder.CoinT2Used

    -- basic gating
    if boostName == "Default" or usedT1.Value or usedT2.Value then return end

    if boostName == "CoinBT1" and chargeIfAffordable(player, T1Price) then
        usedT1.Value = true
        CoinBoostT1:FireClient(player)
        local att = CoinAttachment:Clone()
        att.Parent = char.LowerTorso
        game.Debris:AddItem(att, 300)
        wait(300)
        usedT1.Value = false

    elseif boostName == "CoinBT2" and chargeIfAffordable(player, T2Price) then
        usedT2.Value = true
        CoinBoostT2:FireClient(player)
        local att = CoinAttachment:Clone()
        att.Parent = char.LowerTorso
        game.Debris:AddItem(att, 600)
        wait(600)
        usedT2.Value = false
    end
end)

--------------------------------------------------------------------------------
-- Gem Boost Handler
--------------------------------------------------------------------------------
GemBRemote.OnServerEvent:Connect(function(player, boostName)
    local folder = player.Character:WaitForChild("BoostsFolder")
    local usedT1, usedT2 = folder.GemT1Used, folder.GemT2Used

    if boostName == "Default" or usedT1.Value or usedT2.Value then return end

    if boostName == "GemBT1" and chargeIfAffordable(player, T1Price) then
        usedT1.Value = true
        GemBoostT1:FireClient(player)
        wait(10)
        usedT1.Value = false

    elseif boostName == "GemBT2" and chargeIfAffordable(player, T2Price) then
        usedT2.Value = true
        GemBoostT2:FireClient(player)
        wait(6)
        usedT2.Value = false
    end
end)

--------------------------------------------------------------------------------
-- Jump Boost Handler
--------------------------------------------------------------------------------
JumpBRemote.OnServerEvent:Connect(function(player, boostName)
    local char, humanoid = player.Character, player.Character and player.Character:FindFirstChild("Humanoid")
    if not humanoid then return end

    local folder = char:WaitForChild("BoostsFolder")
    local usedT1, usedT2 = folder.JumpT1Used, folder.JumpT2Used

    if boostName == "Default" or usedT1.Value or usedT2.Value then return end

    if boostName == "JumpT1" and chargeIfAffordable(player, T1Price) then
        usedT1.Value = true
        JumpBoostT1:FireClient(player)
        local att = JumpAttachment:Clone()
        att.Parent = char.LowerTorso
        game.Debris:AddItem(att, 300)
        humanoid.UseJumpPower = true
        humanoid.JumpPower = tier1jump
        wait(300)
        humanoid.UseJumpPower = false
        humanoid.JumpPower = defaultjump
        usedT1.Value = false

    elseif boostName == "JumpT2" and chargeIfAffordable(player, T2Price) then
        usedT2.Value = true
        JumpBoostT2:FireClient(player)
        local att = JumpAttachment:Clone()
        att.Parent = char.LowerTorso
        game.Debris:AddItem(att, 600)
        humanoid.UseJumpPower = true
        humanoid.JumpPower = tier2jump
        wait(600)
        humanoid.UseJumpPower = false
        humanoid.JumpPower = defaultjump
        usedT2.Value = false
    end
end)

--------------------------------------------------------------------------------
-- Witch & Ghost Boost Handlers (similar structure)
--------------------------------------------------------------------------------
-- Each sets a flag, shows particle, deducts, waits, then resets flag

WitchBRemote.OnServerEvent:Connect(function(player, boostName)
    local folder = player.Character:WaitForChild("BoostsFolder")
    local usedT1, usedT2 = folder.WitchT1Used, folder.WitchT2Used

    if boostName == "WitchT1" and not usedT1.Value and chargeIfAffordable(player, T1Price) then
        usedT1.Value = true
        WitchBoostT1:FireClient(player)
        local att = WitchAttachment:Clone()
        att.Parent = player.Character.LowerTorso
        game.Debris:AddItem(att, 300)
        task.wait(300)
        usedT1.Value = false

    elseif boostName == "WitchT2" and not usedT2.Value and chargeIfAffordable(player, T2Price) then
        usedT2.Value = true
        WitchBoostT2:FireClient(player)
        local att = WitchAttachment:Clone()
        att.Parent = player.Character.LowerTorso
        game.Debris:AddItem(att, 600)
        wait(600)
        usedT2.Value = false
    end
end)

GhostBRemote.OnServerEvent:Connect(function(player, boostName)
    local folder = player.Character:WaitForChild("BoostsFolder")
    local usedT1, usedT2 = folder.GhostT1Used, folder.GhostT2Used

    if boostName == "GhostT1" and not usedT1.Value and chargeIfAffordable(player, T1Price) then
        usedT1.Value = true
        GhostBoostT1:FireClient(player)
        local att = GhostAttachment:Clone()
        att.Parent = player.Character.UpperTorso
        game.Debris:AddItem(att, 300)
        wait(300)
        usedT1.Value = false

    elseif boostName == "GhostT2" and not usedT2.Value and chargeIfAffordable(player, T2Price) then
        usedT2.Value = true
        GhostBoostT2:FireClient(player)
        local att = GhostAttachment:Clone()
        att.Parent = player.Character.UpperTorso
        game.Debris:AddItem(att, 600)
        wait(600)
        usedT2.Value = false
    end
end)

--------------------------------------------------------------------------------
-- Player setup: create BoostsFolder and default flags on spawn
--------------------------------------------------------------------------------
local function onCharacterAdded(char)
    local player = Players:GetPlayerFromCharacter(char)
    if not player then return end

    local folder = Instance.new("Folder")
    folder.Name = "BoostsFolder"
    folder.Parent = char

    -- Create default tracking values
    local names = { "BoostName", "SpeedT1Used", "SpeedT2Used",
                    "CoinT1Used",  "CoinT2Used",   "JumpT1Used",
                    "JumpT2Used",  "WitchT1Used",  "WitchT2Used",
                    "GhostT1Used", "GhostT2Used" }

    for _, name in ipairs(names) do
        local value = Instance.new(name == "BoostName" and "StringValue" or "BoolValue")
        value.Name  = name
        value.Parent = folder
        value.Value = (name == "BoostName") and "Default" or false
    end
end

-- Connect player join/spawn events
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(onCharacterAdded)
end)

-- UI toggle for the shop panel
ReplicatedStorage.BoostsShopFolder.OpenBoosts.OnClientEvent:Connect(function()
    script.Parent.Holder.Visible = not script.Parent.Holder.Visible
end)
