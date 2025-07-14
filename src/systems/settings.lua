--[[
    SettingsHandler Module
    ----------------------
    Manages the in-game Settings UI: toggling panels, handling option switches,
    and coordinating with the PetClientMovement module. Simple, event-driven 
    implementation using TweenService for smooth transitions.
]]

local SettingsHandler = {}

-- Services
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")

-- Wait for the local player to be available
repeat wait() until Players.LocalPlayer
local Player = Players.LocalPlayer

-- Tween configuration for UI animations
local TweenInf = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

-- Prevent double-clicks
local clickD = false

-- UI references
local PlayerGUI        = Player:WaitForChild("PlayerGui")
local MainUI           = PlayerGUI:WaitForChild("MainUI")
local SettingsFrame    = MainUI.SettingsFrame
local SettingsList     = SettingsFrame.List.Holder
local SettingsButton   = MainUI.SettingsButton
local PetUI            = MainUI.PetsFrame
local IndexUI          = MainUI:WaitForChild("IndexFrame")
local AutoDeleteFrame  = MainUI:WaitForChild("AutoDeleteFrame")

-- Core pet-movement logic (enable/disable)
local PetClientMovementModule = require(script.Parent.PetClientMovement)

-- Toggle switch positions and colors
local Disabled, dColor, dbgColor = UDim2.new(0.05, 0, 0.4, 0), Color3.fromRGB(255, 24, 3), Color3.fromRGB(175, 16, 2)
local Enabled, eColor, ebgColor  = UDim2.new(0.55, 0, 0.4, 0), Color3.fromRGB(85, 255, 127), Color3.fromRGB(47, 143, 0)

-- Animate a toggle UI element on or off
local function toggle(ui, isEnabled)
    -- Shift the circle indicator
    local targetPos = isEnabled and Enabled or Disabled
    ui:WaitForChild("Circle"):TweenPosition(targetPos, "Out", "Quint", 0.3, true)
    -- Update colors to reflect state
    local bg = isEnabled and ebgColor or dbgColor
    local fg = isEnabled and eColor  or dColor
    ui.Music.BG.ImageColor3 = fg
    ui.Music.ImageColor3    = bg
end

-- Map of setting names to handler functions
local SETTINGS_FUNCS = {
    YourPets = function(button)
        local flag = button.Which
        flag.Value = not flag.Value
        toggle(button.Button, flag.Value)
        PetClientMovementModule:UpdateYourPets(flag.Value)
    end;
    OthersPets = function(button)
        local flag = button.Which
        flag.Value = not flag.Value
        toggle(button.Button, flag.Value)
        PetClientMovementModule:UpdateOtherPets(flag.Value)
    end;
}

-- Close other open panels before opening settings
local function SetOtherFramesFalse()
    for _, frame in ipairs({PetUI, IndexUI, MainUI.TradePlayerList}) do
        spawn(function()
            local tween = TweenService:Create(frame, TweenInf, {Size = UDim2.new(0, 0, 0, 0)})
            tween:Play()
            tween.Completed:Connect(function()
                frame.Visible = false
            end)
        end)
    end
end

-- Open the settings panel with a tween
function SettingsHandler:OpenSettingsUI()
    if not SettingsFrame.Visible and not AutoDeleteFrame.Visible then
        SetOtherFramesFalse()
        SettingsFrame.Size    = UDim2.new(0, 0, 0, 0)
        SettingsFrame.Visible = true
        TweenService:Create(SettingsFrame, TweenInf, {
            Size = UDim2.new(0.325, 0, 0.65, 0)
        }):Play()
    end
end

-- Close the settings panel with a tween
function SettingsHandler:CloseSettingsUI()
    if SettingsFrame.Visible then
        local tween = TweenService:Create(SettingsFrame, TweenInf, {
            Size = UDim2.new(0, 0, 0, 0)
        })
        tween:Play()
        tween.Completed:Connect(function()
            SettingsFrame.Visible = false
        end)
    end
end

-- Initialize button connections
function SettingsHandler:Int()
    -- Bind each frame’s button to its handler
    for _, v in pairs(SettingsList:GetChildren()) do
        if v:IsA("Frame") and v:FindFirstChild("Button") then
            v.Button.Click.MouseButton1Click:Connect(function()
                if not clickD and SETTINGS_FUNCS[v.Name] then
                    clickD = true
                    SETTINGS_FUNCS[v.Name](v)
                    wait(0.25)
                    clickD = false
                end
            end)
        end
    end

    -- Main settings button
    SettingsButton.Click.MouseButton1Click:Connect(function()
        self:OpenSettingsUI()
    end)

    -- Exit button inside settings
    SettingsFrame.Exit.Click.MouseButton1Click:Connect(function()
        self:CloseSettingsUI()
    end)
end

return SettingsHandler
