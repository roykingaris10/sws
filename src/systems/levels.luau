--[[
    Player Leveling System
    Context: Manages player levels, experience, and rewards. 
    Uses DataStore to persist level stats across sessions and fires visual effects on level-up.
--]]

-- Services
local DataStoreService    = game:GetService("DataStoreService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local Players             = game:GetService("Players")
local levelData           = DataStoreService:GetDataStore("LevelStatsDSFTF1")

-- Remote event for client-side level-up visuals
local LevelUp = ReplicatedStorage.Remotes:WaitForChild("LevelUp")

-- Initialize level-related objects when a player joins
local function onPlayerJoin(player)
    -- Container for all leveling values
    local folder = Instance.new("Folder")
    folder.Name = "levelfolder"
    folder.Parent = player

    -- Core stats: Level, Current XP, XP needed
    local lvl = Instance.new("IntValue"); lvl.Name = "Level"; lvl.Parent = folder
    local current = Instance.new("IntValue"); current.Name = "Current"; current.Parent = lvl
    local maxExp = Instance.new("IntValue"); maxExp.Name = "Max"; maxExp.Parent = lvl

    -- Progress counters for reward scaling
    local progress   = Instance.new("IntValue"); progress.Name = "LevelProgress";   progress.Parent = folder
    local milestone  = Instance.new("IntValue"); milestone.Name = "LevelProgressM"; milestone.Parent = folder
    local rewardAmt  = Instance.new("IntValue"); rewardAmt.Name = "LevelProgressR"; rewardAmt.Parent = folder

    -- Attempt to load saved data
    local key  = "Player_" .. player.UserId
    local data = levelData:GetAsync(key)
    if data then
        -- Populate from DataStore
        lvl.Value         = data.Level
        current.Value     = data.Current
        maxExp.Value      = data.Max
        progress.Value    = data.LevelProgress
        milestone.Value   = data.LevelProgressM
        rewardAmt.Value   = data.LevelProgressR
    else
        -- Default starting values
        lvl.Value       = 1
        current.Value   = 0
        maxExp.Value    = 100
        progress.Value  = 0
        milestone.Value = 3
        rewardAmt.Value = 15
    end

    -- When progress hits the milestone, grant rewards and scale up
    progress.Changed:Connect(function()
        if progress.Value >= milestone.Value then
            -- Award coins and gems equal to rewardAmt
            player.leaderstats.Coins.Value = player.leaderstats.Coins.Value + rewardAmt.Value
            player.leaderstats.Gems.Value  = player.leaderstats.Gems.Value  + rewardAmt.Value

            -- Scale next milestone and reward
            milestone.Value = math.floor(milestone.Value * 1.5)
            rewardAmt.Value = math.floor(rewardAmt.Value * 1.5)
        end
    end)

    -- Handle XP gain and level-up
    current.Changed:Connect(function()
        if current.Value >= maxExp.Value then
            -- Notify client to play level-up effect
            LevelUp:FireClient(player)

            -- Spawn particle effect at the player's root
            spawn(function()
                local template = ReplicatedStorage:WaitForChild("LevelUppart")
                local attach   = template.attach:Clone()
                attach.Parent  = player.Character and player.Character:FindFirstChild("HumanoidRootPart") or workspace

                -- Emit particles
                for _, emitter in ipairs({attach.Circles, attach.Flare, attach.Rays, attach.Rays2}) do
                    emitter:Emit(8)
                end

                game.Debris:AddItem(attach, 3)
            end)

            -- Increase level, reset XP, bump XP threshold, increment progress
            lvl.Value      = lvl.Value + 1
            current.Value  = 0
            maxExp.Value   = math.floor(maxExp.Value * 1.5)
            progress.Value = progress.Value + 1
        end
    end)
end

-- Build a table of the player's level stats for saving
local function create_table(player)
    local stats = {}
    for _, stat in ipairs(player.levelfolder:GetDescendants()) do
        stats[stat.Name] = stat.Value
    end
    return stats
end

-- Save level stats when a player leaves
local function onPlayerExit(player)
    local stats = create_table(player)
    local success, err = pcall(function()
        levelData:SetAsync("Player_" .. player.UserId, stats)
    end)
    if not success then
        warn("Could not save level data for", player.Name, err)
    end
end

-- Connect events
Players.PlayerAdded:Connect(onPlayerJoin)
Players.PlayerRemoving:Connect(onPlayerExit)
