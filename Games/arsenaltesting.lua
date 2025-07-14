-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "YouHub",
    Icon = "rbxassetid://129260712070622",
    IconThemed = true,
    Author = "Arsenal v1.0.1",
    Folder = "YouHubArsenal",
    Size = UDim2.fromOffset(600, 500),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 200,
    ScrollBarEnabled = true,
    KeySystem = { -- <- ↓ remove this all, if you dont neet the key system
        Key = { "YouhubArsenalv1.0.1" },
        Note = "Join Our Discord To Get The Key in key channel.",
        Thumbnail = {
            Image = "rbxassetid://97296381694913",
            Title = "Youhub Key",
        },
        URL = "https://discord.gg/p65VYjZ9k3",
        SaveKey = true,
    },
})

local Tabs = {}
Tabs.MainSection = Window:Section({ Title = "Main", Opened = true })
Tabs.CombatSection = Window:Section({ Title = "Combat", Opened = false })
Tabs.MovementSection = Window:Section({ Title = "Movement", Opened = false })
Tabs.SettingsSection = Window:Section({ Title = "Settings", Opened = false })

Tabs.Main = Tabs.MainSection:Tab({ Title = "Info", Icon = "info" })
Tabs.Combat = Tabs.CombatSection:Tab({ Title = "Combat", Icon = "target" })
Tabs.Movement = Tabs.MovementSection:Tab({ Title = "Movement", Icon = "move" })
Tabs.Settings = Tabs.SettingsSection:Tab({ Title = "Settings", Icon = "settings" })

-- Main Tab Content
Tabs.Main:Section({ Title = "Welcome to YouHub | Arsenal!", TextXAlignment = "Center", TextSize = 20 })
Tabs.Main:Paragraph({
    Title = "Welcome!",
    Desc = [[
Thank you for using YouHub for Arsenal! This script enhances your gameplay with powerful automation and quality-of-life features. Explore the tabs for Combat, Movement, and more.
    ]],
    Locked = false
})

Tabs.Main:Section({ Title = "Key Features", TextXAlignment = "Left", TextSize = 17 })
Tabs.Main:Paragraph({
    Title = "Main Features",
    Desc = [[
• Custom ESP (boxes around enemies, color customizable)
• Custom Tracer (lines to enemies, color customizable)
• Aimbot (locks onto closest enemy head in FOV, not mobile friendly)
• FOV Circle (customizable size and color)
• Head Hitbox Expander (with size slider, mobile friendly)
• No Recoil (removes weapon recoil)
• All features controlled via WindUI
• Modern, mobile-friendly WindUI design
    ]],
    Locked = false
})

Tabs.Main:Section({ Title = "Links & Community", TextXAlignment = "Left", TextSize = 17 })
Tabs.Main:Button({
    Title = "Join our Discord",
    Desc = "Copies our Discord invite link to your clipboard.",
    Locked = false,
    Callback = function()
        setclipboard("https://discord.gg/p65VYjZ9k3")
        print("Discord invite link copied to clipboard!")
    end
})

Tabs.Main:Button({
    Title = "CYV SHOP",
    Desc = "Copies CYV SHOP Discord invite link to your clipboard.",
    Locked = false,
    Callback = function()
        setclipboard("https://discord.gg/XRRc5hnBu3")
        print("CYV SHOP Discord invite link copied to clipboard!")
    end
})

Tabs.Main:Paragraph({
    Title = "CYV SHOP - Premium Game Services",
    Desc = [[
The cheapest shop for PS99 (Pet Simulator 99), GAG (Grow A Garden), Steal a Pet, BGSI (Bubble Gum Simulator), and many more popular Roblox games. We offer:

• Fast and reliable service
• Competitive prices
• Professional staff
• Secure transactions
• 24/7 customer support
• Wide variety of game services

Join our Discord for the best deals and fastest service in the market!
    ]],
    Locked = false
})



-- Custom ESP, Tracer, Aimbot, and FOV Circle System
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Drawing objects
local espBoxes = {}
local tracers = {}
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Color = Color3.fromRGB(255,255,255)
fovCircle.Thickness = 2
fovCircle.Filled = false
fovCircle.Transparency = 1
fovCircle.NumSides = 60

-- State
local customESPEnabled = false
local customTracerEnabled = false
local customAimbotEnabled = false
local customFOVCircleEnabled = false
local customFOVCircleSize = 90
local aimbotTarget = nil
local aimbotKey = Enum.UserInputType.MouseButton2
local aimbotRunning = false

-- Hitbox Extender (Head only, with size slider)
local hitboxExtenderEnabled = false
local hitboxConn = nil
local originalSizes = {}
local hitboxOverlays = {}
local hitboxSize = 13

-- FOV Circle Color
local fovCircleColor = Color3.fromRGB(255,255,255)

-- Tracer Color
local tracerColor = Color3.fromRGB(255,255,255)

-- ESP Box Color
local espBoxColor = Color3.fromRGB(255,255,255)

-- Utility
local function clearDrawings(tbl)
    for _,v in pairs(tbl) do
        if v and v.Remove then pcall(function() v:Remove() end) end
    end
    table.clear(tbl)
end

local function getEnemies()
    local enemies = {}
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Team ~= LocalPlayer.Team then
            local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                table.insert(enemies, plr)
            end
        end
    end
    return enemies
end

local function worldToScreen(pos)
    local vec, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(vec.X, vec.Y), onScreen, vec.Z
end

-- ESP/Tracer Render Loop (update every frame, always show current position, do not teleport)
RunService.RenderStepped:Connect(function()
    clearDrawings(espBoxes)
    clearDrawings(tracers)
    if not (customESPEnabled or customTracerEnabled) then return end
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Team ~= LocalPlayer.Team and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local hrp = plr.Character.HumanoidRootPart
                local screenPos, onScreen, z = worldToScreen(hrp.Position)
                if onScreen and z > 0 then
                    -- ESP Box
                    if customESPEnabled then
                        local size = Vector3.new(4, 7, 0) -- box size
                        local top = hrp.Position + Vector3.new(0, size.Y/2, 0)
                        local bottom = hrp.Position - Vector3.new(0, size.Y/2, 0)
                        local top2d, onScreenTop = worldToScreen(top)
                        local bottom2d, onScreenBottom = worldToScreen(bottom)
                        if onScreenTop and onScreenBottom then
                            local boxHeight = (top2d - bottom2d).Magnitude
                            local boxWidth = boxHeight/2
                            local box = Drawing.new("Square")
                            box.Size = Vector2.new(boxWidth, boxHeight)
                            box.Position = Vector2.new(screenPos.X - boxWidth/2, screenPos.Y - boxHeight/2)
                            box.Color = espBoxColor
                            box.Thickness = 2
                            box.Filled = false
                            box.Transparency = 1
                            box.Visible = true
                            table.insert(espBoxes, box)
                            -- Player Name and Health
                            local nameText = Drawing.new("Text")
                            nameText.Text = plr.Name .. " [" .. math.floor(humanoid.Health) .. "]"
                            nameText.Position = Vector2.new(screenPos.X, screenPos.Y - boxHeight/2 - 16)
                            nameText.Size = 16
                            nameText.Center = true
                            nameText.Outline = true
                            nameText.Color = espBoxColor
                            nameText.Visible = true
                            table.insert(espBoxes, nameText)
                        end
                    end
                    -- Tracer
                    if customTracerEnabled then
                        local tracer = Drawing.new("Line")
                        tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                        tracer.To = screenPos
                        tracer.Color = tracerColor
                        tracer.Thickness = 2
                        tracer.Transparency = 1
                        tracer.Visible = true
                        table.insert(tracers, tracer)
                    end
                end
            end
        end
    end
end)

-- FOV Circle Render
RunService.RenderStepped:Connect(function()
    if customFOVCircleEnabled then
        fovCircle.Visible = true
        fovCircle.Position = UserInputService:GetMouseLocation()
        fovCircle.Radius = customFOVCircleSize
        fovCircle.Color = fovCircleColor
    else
        fovCircle.Visible = false
    end
end)

-- Infinite Jump (bunny hop style, works in air)
Tabs.Movement:Toggle({
    Title = "Infinite Jump",
    Desc = "Allows you to jump infinitely (bunny hop style).",
    Icon = "arrow-up",
    Type = "Checkbox",
    Default = false,
    Callback = function(enabled)
        if enabled then
            if _G.infJumpConn then _G.infJumpConn:Disconnect() end
            _G.infJumpConn = UserInputService.JumpRequest:Connect(function()
                local char = LocalPlayer.Character
                local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid then
                    humanoid.UseJumpPower = true
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    humanoid.Jump = true
                end
            end)
        else
            if _G.infJumpConn then _G.infJumpConn:Disconnect() _G.infJumpConn = nil end
        end
    end
})

-- Aimbot: lock to selected part in FOV circle while holding right mouse button
local aimbotConnection = nil
local function disconnectAimbot()
    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end
end
local function clearHitboxOverlays()
    for _, overlay in pairs(hitboxOverlays) do
        if overlay and overlay.Adornee then
            overlay:Destroy()
        end
    end
    hitboxOverlays = {}
end
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == aimbotKey and customAimbotEnabled then
        aimbotRunning = true
        disconnectAimbot()
        aimbotConnection = RunService.RenderStepped:Connect(function()
            if not (customAimbotEnabled and aimbotRunning) then return end
            local closest, closestDist = nil, math.huge
            local mousePos = UserInputService:GetMouseLocation()
            for _,plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Team ~= LocalPlayer.Team and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        local part = plr.Character:FindFirstChild("Head")
                        if part then
                            local screenPos, onScreen, z = worldToScreen(part.Position)
                            if onScreen and z > 0 then
                                local dist = (screenPos - mousePos).Magnitude
                                if dist < customFOVCircleSize and dist < closestDist then
                                    closest = part
                                    closestDist = dist
                                end
                            end
                        end
                    end
                end
            end
            if closest then
                local targetScreen, _, _ = worldToScreen(closest.Position)
                local delta = targetScreen - mousePos
                mousemoverel(delta.X, delta.Y)
            end
        end)
    end
end)
UserInputService.InputEnded:Connect(function(input, processed)
    if input.UserInputType == aimbotKey then
        aimbotRunning = false
        disconnectAimbot()
    end
end)

-- Combat Tab (ESP, Tracer, Aimbot, FOV Circle)
Tabs.Combat:Section({ Title = "Combat Features", TextXAlignment = "Left", TextSize = 17 })

Tabs.Combat:Section({ Title = "Visuals" })
Tabs.Combat:Toggle({
    Title = "Enable ESP",
    Desc = "Toggles player ESP (boxes, names, etc.)",
    Icon = "eye",
    Type = "Checkbox",
    Default = false,
    Callback = function(val)
        customESPEnabled = val
    end
})
Tabs.Combat:Toggle({
    Title = "Enable Tracer",
    Desc = "Toggles player tracers (lines to players)",
    Icon = "arrow-right",
    Type = "Checkbox",
    Default = false,
    Callback = function(val)
        customTracerEnabled = val
    end
})
Tabs.Combat:Colorpicker({
    Title = "Tracer Color",
    Desc = "Change the color of the tracers.",
    Default = tracerColor,
    Transparency = 0,
    Locked = false,
    Callback = function(color)
        tracerColor = color
    end
})
Tabs.Combat:Colorpicker({
    Title = "ESP Box Color",
    Desc = "Change the color of the ESP boxes.",
    Default = espBoxColor,
    Transparency = 0,
    Locked = false,
    Callback = function(color)
        espBoxColor = color
    end
})

Tabs.Combat:Section({ Title = "Aimbot" })
Tabs.Combat:Paragraph({
    Title = "Aimbot Mobile Info",
    Desc = "Aimbot is not supported on mobile. Please use Hitbox Extender instead.",
    Locked = false
})
Tabs.Combat:Toggle({
    Title = "Enable Aimbot",
    Desc = "Toggles aimbot (locks onto closest player in FOV)",
    Icon = "crosshair",
    Type = "Checkbox",
    Default = false,
    Callback = function(val)
        customAimbotEnabled = val
    end
})
Tabs.Combat:Toggle({
    Title = "Show FOV Circle",
    Desc = "Toggles the aimbot FOV circle display",
    Icon = "circle",
    Type = "Checkbox",
    Default = true,
    Callback = function(val)
        customFOVCircleEnabled = val
    end
})
Tabs.Combat:Slider({
    Title = "FOV Circle Size",
    Step = 1,
    Value = { Min = 30, Max = 300, Default = 90 },
    Callback = function(val)
        customFOVCircleSize = val
    end
})
Tabs.Combat:Colorpicker({
    Title = "FOV Circle Color",
    Desc = "Change the color of the FOV circle.",
    Default = fovCircleColor,
    Transparency = 0,
    Locked = false,
    Callback = function(color)
        fovCircleColor = color
    end
})

Tabs.Combat:Section({ Title = "Weapon Mods" })
Tabs.Combat:Toggle({
    Title = "No Recoil",
    Desc = "Removes weapon recoil (sets all recoil values to 0).",
    Icon = "target",
    Type = "Checkbox",
    Default = false,
    Callback = function(enabled)
        if enabled then
            for _, v in pairs(game.ReplicatedStorage.Weapons:GetDescendants()) do
                if v.Name == "Recoil" or v.Name == "RecoilControl" then
                    v.Value = 0
                end
            end
        end
    end
})

Tabs.Combat:Section({ Title = "Hitbox Mods" })
Tabs.Combat:Paragraph({
    Title = "Mobile Info",
    Desc = "For mobile users, I recommend using only Hitbox Extender because aimbot is not mobile friendly but Hitbox Extender is.",
    Locked = false
})
Tabs.Combat:Slider({
    Title = "Head Hitbox Size",
    Step = 1,
    Value = { Min = 3, Max = 30, Default = 13 },
    Callback = function(val)
        hitboxSize = val
    end
})
Tabs.Combat:Toggle({
    Title = "Hitbox Extender",
    Desc = "Enlarges enemy head hitboxes and shows a light gray box.",
    Icon = "box",
    Type = "Checkbox",
    Default = false,
    Callback = function(enabled)
        hitboxExtenderEnabled = enabled
        if hitboxConn then hitboxConn:Disconnect() hitboxConn = nil end
        -- Remove overlays (no longer needed)
        -- clearHitboxOverlays() -- overlays are not used anymore
        if not enabled then
            -- Restore original sizes and properties
            for plrName, parts in pairs(originalSizes) do
                for partName, size in pairs(parts) do
                    local plr = Players:FindFirstChild(plrName)
                    if plr and plr.Character and plr.Character:FindFirstChild(partName) then
                        local part = plr.Character[partName]
                        if part and part:IsA("BasePart") then
                            part.Anchored = false
                            part.Size = size
                            part.Transparency = 0
                            part.Color = Color3.fromRGB(255,255,255)
                            part.CanCollide = true
                        end
                    end
                end
            end
            originalSizes = {}
            return
        end
        hitboxConn = RunService.RenderStepped:Connect(function()
            for _,v in ipairs(Players:GetPlayers()) do
                if v ~= LocalPlayer and v.Character then
                    local partName = "HeadHB"
                    local part = v.Character:FindFirstChild(partName)
                    if part and part:IsA("BasePart") then
                        -- Save original size
                        originalSizes[v.Name] = originalSizes[v.Name] or {}
                        if not originalSizes[v.Name][partName] then
                            originalSizes[v.Name][partName] = part.Size
                        end
                        part.CanCollide = false
                        part.Transparency = 0.6 -- slightly visible
                        part.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                        part.Anchored = false
                        part.Color = Color3.fromRGB(200,200,200) -- light gray
                        -- No overlays/adornments
                    end
                end
            end
        end)
    end
})

Tabs.Combat:Paragraph({
    Title = "Kill All Status",
    Desc = "Kill All is not working at the moment.",
    Color = "Red",
    Locked = false
})

-- Kill All: teleport behind each enemy, equip knife, simulate left mouse click, 1s delay between each
Tabs.Combat:Button({
    Title = "Kill All",
    Desc = "Teleports you behind all enemy players and attempts to kill them.",
    Callback = function()
        local player = game.Players.LocalPlayer
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local knife = nil
        for _,tool in ipairs(player.Backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:lower():find("knife") then
                knife = tool
                break
            end
        end
        if not knife and char:FindFirstChildOfClass("Tool") and char:FindFirstChildOfClass("Tool").Name:lower():find("knife") then
            knife = char:FindFirstChildOfClass("Tool")
        end
        if not knife then
            WindUI:Notify({
                Title = "Kill All Failed",
                Content = "No knife found in your inventory!",
                Duration = 4
            })
            return
        end
        -- Equip knife if not equipped
        if not char:FindFirstChild(knife.Name) then
            knife.Parent = char
            task.wait(0.1)
        end
        for _,enemy in ipairs(game.Players:GetPlayers()) do
            if enemy ~= player and enemy.Team ~= player.Team and enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
                local enemyHRP = enemy.Character.HumanoidRootPart
                local myHRP = char.HumanoidRootPart
                -- Only teleport if not close enough
                if (myHRP.Position - enemyHRP.Position).Magnitude > 5 then
                    myHRP.CFrame = enemyHRP.CFrame * CFrame.new(0, 0, -3)
                    task.wait(0.05)
                end
                -- Face the enemy
                myHRP.CFrame = CFrame.new(myHRP.Position, enemyHRP.Position)
                -- Attack
                if not char:FindFirstChild(knife.Name) then
                    knife.Parent = char
                    task.wait(0.05)
                end
                local attacked = false
                if knife:FindFirstChild("Remote") then
                    attacked = pcall(function()
                        knife.Remote:FireServer(enemy.Character:FindFirstChild("Head") or enemyHRP)
                    end)
                elseif knife:FindFirstChild("Hit") then
                    attacked = pcall(function()
                        knife.Hit:FireServer(enemy.Character:FindFirstChild("Head") or enemyHRP)
                    end)
                elseif knife.Activate then
                    attacked = pcall(function()
                        knife:Activate()
                    end)
                end
                -- If attack failed, try Activate as fallback
                if not attacked and knife.Activate then
                    pcall(function()
                        knife:Activate()
                    end)
                end
                task.wait(0.15)
            end
        end
    end
})

-- Movement Tab (Player Controls)
Tabs.Movement:Section({ Title = "Player Controls", TextXAlignment = "Left", TextSize = 17 })

-- Settings Tab (with config management)
Tabs.Settings:Section({ Title = "Settings", TextXAlignment = "Left", TextSize = 17 })
Tabs.Settings:Paragraph({
    Title = "Settings",
    Desc = "Settings and config will be here.",
    Locked = false
})
-- Anti-AFK (prevents being kicked for inactivity)
local antiAFKConn = nil
Tabs.Settings:Toggle({
    Title = "Anti-AFK",
    Desc = "Prevents you from being kicked for being AFK.",
    Icon = "shield",
    Type = "Checkbox",
    Default = false,
    Callback = function(enabled)
        if antiAFKConn then antiAFKConn:Disconnect() antiAFKConn = nil end
        if enabled then
            antiAFKConn = game:GetService("RunService").RenderStepped:Connect(function()
                if tick() % 60 < 0.1 then
                    game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                    game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                end
            end)
        end
    end
})

local HttpService = game:GetService("HttpService")
local folderPath = "WindUI"
makefolder(folderPath)

local function SaveFile(fileName, data)
    local filePath = folderPath .. "/" .. fileName .. ".json"
    local jsonData = HttpService:JSONEncode(data)
    writefile(filePath, jsonData)
end

local function LoadFile(fileName)
    local filePath = folderPath .. "/" .. fileName .. ".json"
    if isfile(filePath) then
        local jsonData = readfile(filePath)
        return HttpService:JSONDecode(jsonData)
    end
end

local function ListFiles()
    local files = {}
    for _, file in ipairs(listfiles(folderPath)) do
        local fileName = file:match("([^/]+)%.json$")
        if fileName then
            table.insert(files, fileName)
        end
    end
    return files
end

local ToggleTransparency = Tabs.Settings:Toggle({
    Title = "Toggle Window Transparency",
    Callback = function(e)
        Window:ToggleTransparency(e)
    end,
    Value = WindUI:GetTransparency()
})

Tabs.Settings:Section({ Title = "Save", TextXAlignment = "Left", TextSize = 17 })

local fileNameInput = ""
Tabs.Settings:Input({
    Title = "Write File Name",
    PlaceholderText = "Enter file name",
    Callback = function(text)
        fileNameInput = text
    end
})

Tabs.Settings:Button({
    Title = "Save File",
    Callback = function()
        if fileNameInput ~= "" then
            SaveFile(fileNameInput, { Transparent = WindUI:GetTransparency(), Theme = WindUI:GetCurrentTheme() })
        end
    end
})

Tabs.Settings:Section({ Title = "Load", TextXAlignment = "Left", TextSize = 17 })

local filesDropdown
local files = ListFiles()

filesDropdown = Tabs.Settings:Dropdown({
    Title = "Select File",
    Multi = false,
    AllowNone = true,
    Values = files,
    Callback = function(selectedFile)
        fileNameInput = selectedFile
    end
})

Tabs.Settings:Button({
    Title = "Load File",
    Callback = function()
        if fileNameInput ~= "" then
            local data = LoadFile(fileNameInput)
            if data then
                WindUI:Notify({
                    Title = "File Loaded",
                    Content = "Loaded data: " .. HttpService:JSONEncode(data),
                    Duration = 5,
                })
                if data.Transparent then 
                    Window:ToggleTransparency(data.Transparent)
                    ToggleTransparency:SetValue(data.Transparent)
                end
                if data.Theme then WindUI:SetTheme(data.Theme) end
            end
        end
    end
})

Tabs.Settings:Button({
    Title = "Overwrite File",
    Callback = function()
        if fileNameInput ~= "" then
            SaveFile(fileNameInput, { Transparent = WindUI:GetTransparency(), Theme = WindUI:GetCurrentTheme() })
        end
    end
})

Tabs.Settings:Button({
    Title = "Refresh List",
    Callback = function()
        filesDropdown:Refresh(ListFiles())
    end
})

-- Player Teleport (Movement Tab)
local function getPlayerNames()
    local names = {}
    for _,plr in ipairs(game.Players:GetPlayers()) do
        if plr ~= LocalPlayer then table.insert(names, plr.Name) end
    end
    return names
end
local selectedTeleportPlayer = nil
Tabs.Movement:Dropdown({
    Title = "Teleport to Player",
    Desc = "Select a player to teleport to.",
    Values = getPlayerNames(),
    Multi = false,
    AllowNone = true,
    Callback = function(name)
        selectedTeleportPlayer = name
    end
})
Tabs.Movement:Button({
    Title = "Teleport",
    Desc = "Teleport to the selected player.",
    Callback = function()
        if selectedTeleportPlayer then
            local target = game.Players:FindFirstChild(selectedTeleportPlayer)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,3)
            end
        end
    end
})

-- Infinite Ammo (Combat Tab)
local infiniteAmmoEnabled = false
Tabs.Combat:Toggle({
    Title = "Infinite Ammo",
    Desc = "Gives you infinite ammo for your current weapon.",
    Icon = "infinity",
    Type = "Checkbox",
    Default = false,
    Callback = function(enabled)
        infiniteAmmoEnabled = enabled
    end
})
-- Loop to set ammo if enabled
RunService.RenderStepped:Connect(function()
    if infiniteAmmoEnabled and LocalPlayer.Character then
        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            for _,v in pairs(tool:GetDescendants()) do
                if v.Name:lower():find("ammo") and v:IsA("IntValue") then
                    v.Value = 999
                end
            end
        end
    end
end)

Window:SelectTab(1)
WindUI:Notify({
    Title = "YouHub | Arsenal",
    Content = "Script loaded with full WindUI integration.",
    Duration = 6
})

-- Remove aimbot target part dropdown, always use Head
local aimbotTargetPart = "Head"
local function getAimbotTargetPart(char)
    return char:FindFirstChild("Head")
end
