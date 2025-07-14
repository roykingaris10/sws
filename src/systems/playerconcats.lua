--[[
    Twitter Code Redemption Script
    Context: This server-side script allows players to redeem special Twitter promo codes 
    for in-game rewards (Coins or Gems). Each code can only be used once per player, 
    tracked via Roblox DataStore to prevent duplicate redemptions.
--]]

-- Initialize DataStore service
local DataStoreService = game:GetService("DataStoreService")

-- Define valid Twitter redemption codes and their rewards
local TwitterCodes = {
    SLIMEANIME   = {"Coins", 4000},
    SLIMEPIECE   = {"Gems", 600},
    FRIENDCODE4  = {"Coins", 500000},
    FRIENDCODE5  = {"Gems", 100000},
    -- Example for future events:
    -- SLIMEGHOST = {"Coins", 1500},
    -- LOVESLIME  = {"Coins", 500},
}

-- Handle code redemption requests from client
game.ReplicatedStorage.RedeemCode.OnServerInvoke = function(player, code)
    -- Use a unique DataStore per code, so each player can only redeem once
    local storeName = "TwitterCodesDS1FTF_" .. code
    local codeStore = DataStoreService:GetDataStore(storeName)
    
    -- Check if this player has already redeemed this specific code
    local alreadyRedeemed = codeStore:GetAsync(player.UserId)
    
    -- Only proceed if code exists in our table and hasn't been used by this player
    if TwitterCodes[code] and not alreadyRedeemed then
        -- Lookup which leaderboard value to update and how much to add
        local statName = TwitterCodes[code][1]
        local reward   = TwitterCodes[code][2]
        
        -- Safely get the player's stat and increment it
        local stat = player.leaderstats and player.leaderstats:FindFirstChild(statName)
        if stat then
            stat.Value = stat.Value + reward
        end
        
        -- Record that this player has redeemed the code
        codeStore:SetAsync(player.UserId, true)
        
        return true  -- inform client of successful redemption
    end
    
    return false  -- either code is invalid or already used
end
