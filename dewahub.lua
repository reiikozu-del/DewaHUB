-- language: Luau, file: core_rainbow_ui.lua, target: GitHub Raw
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

-- State
local noclip, infJump, wsVal = false, false, 16
local cfSpeedActive = false
local cfSpeedVal = 1
local instantPromptActive = false
local savedCFrame1 = nil
local savedCFrame2 = nil
local espActive = false
local flyActive = false
local flySpeed = 50
local antiAfkActive = false
local fullbrightActive = false
local tapTpActive = false
local isSpectating = false
local originalCameraSubject = nil

-- UI Factory Helper
local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

-- Teleport Fix (PivotTo + StreamingAround)
local function safeTeleport(targetCFrame)
    local char = player.Character
    if not char then return end
    pcall(function()
        if game.Workspace.StreamingEnabled then
            player:RequestStreamAroundAsync(targetCFrame.Position)
        end
    end)
    task.wait(0.05)
    char:PivotTo(targetCFrame)
end

-- ScreenGui
local screen = make("ScreenGui", {Name = "PowaHubRainbow", ResetOnSpawn = false}, gui)

-- Floating Buttons (Garis Tepi & Font Tipis)
local floatBack1 = make("TextButton", {
    Size = UDim2.new(0, 48, 0, 48), Position = UDim2.new(0, 15, 0, 80),
    BackgroundColor3 = Color3.fromRGB(14, 165, 233), TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.FredokaOne, TextSize = 13, Text = "BK 1", Visible = false, ZIndex = 10
}, screen)
make("UICorner", {CornerRadius = UDim.new(0, 10)}, floatBack1)
make("UIStroke", {Color = Color3.fromRGB(15, 23, 42), Thickness = 1.5}, floatBack1)

local floatBack2 = make("TextButton", {
    Size = UDim2.new(0, 48, 0, 48), Position = UDim2.new(0, 15, 0, 135),
    BackgroundColor3 = Color3.fromRGB(168, 85, 247), TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.FredokaOne, TextSize = 13, Text = "BK 2", Visible = false, ZIndex = 10
}, screen)
make("UICorner", {CornerRadius = UDim.new(0, 10)}, floatBack2)
make("UIStroke", {Color = Color3.fromRGB(15, 23, 42), Thickness = 1.5}, floatBack2)

-- Open Button
local openBtn = make("TextButton", {
    Size = UDim2.new(0, 48, 0, 48), Position = UDim2.new(0, 15, 0, 20),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255), TextColor3 = Color3.fromRGB(14, 165, 233),
    Font = Enum.Font.FredokaOne, TextSize = 14, Text = "HUB", Visible = false, ZIndex = 10
}, screen)
make("UICorner", {CornerRadius = UDim.new(0, 10)}, openBtn)
make("UIStroke", {Color = Color3.fromRGB(14, 165, 233), Thickness = 1.5}, openBtn)

-- Main Frame dengan Latar Belakang Gambar Pelangi
local main = make("ImageLabel", {
    Size = UDim2.new(0, 480, 0, 300), Position = UDim2.new(0.5, -240, 0.5, -150),
    Image = "rbxassetid://6071575925", -- Asset ID Gambar Pelangi & Langit
    ScaleType = Enum.ScaleType.Crop,
    BorderSizePixel = 0, Active = true
}, screen)
make("UICorner", {CornerRadius = UDim.new(0, 14)}, main)
make("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Thickness = 2}, main)

-- Top Bar
local topBar = make("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1}, main)
local titleLabel = make("TextLabel", {
    Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 16, 0, 0),
    BackgroundTransparency = 1, Font = Enum.Font.FredokaOne, Text = "POWA // HUB",
    TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left
}, topBar)
make("UIStroke", {Color = Color3.fromRGB(15, 23, 42), Thickness = 1.5}, titleLabel)

local minBtn = make("TextButton", {
    Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -38, 0, 5),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.GothamBold, Text = "-",
    TextColor3 = Color3.fromRGB(15, 23, 42), TextSize = 16
}, topBar)
make("UICorner", {CornerRadius = UDim.new(0, 6)}, minBtn)

-- Sidebar & Content (Semi Transparan agar Gambar Terlihat Ciamik)
local sidebar = make("ScrollingFrame", {
    Size = UDim2.new(0, 120, 1, -50), Position = UDim2.new(0, 10, 0, 42),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.3, BorderSizePixel = 0,
    CanvasSize = UDim2.new(0,0,0,0), ScrollBarThickness = 2
}, main)
make("UICorner", {CornerRadius = UDim.new(0, 8)}, sidebar)
make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)}, sidebar)

local contentArea = make("Frame", {
    Size = UDim2.new(1, -145, 1, -50), Position = UDim2.new(0, 138, 0, 42),
    BackgroundTransparency = 1, BorderSizePixel = 0
}, main)

-- Tabs & Panels
local tabs, contents = {"Profile", "Menu", "Misc", "Server Hop", "Setting"}, {}
for i, name in ipairs(tabs) do
    local tBtn = make("TextButton", {
        Size = UDim2.new(1, -6, 0, 34), BackgroundColor3 = i == 1 and Color3.fromRGB(14, 165, 233) or Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamMedium, Text = name, TextColor3 = i == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(15, 23, 42),
        TextSize = 12, LayoutOrder = i
    }, sidebar)
    make("UICorner", {CornerRadius = UDim.new(0, 6)}, tBtn)

    local panel = make("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
        Visible = (i == 1), CanvasSize = UDim2.new(0,0,0,0), ScrollBarThickness = 2
    }, contentArea)
    make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)}, panel)
    contents[name] = panel

    tBtn.MouseButton1Click:Connect(function()
        for _, child in ipairs(sidebar:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3, child.TextColor3 = Color3.fromRGB(255, 255, 255), Color3.fromRGB(15, 23, 42)
            end
        end
        for _, p in pairs(contents) do p.Visible = false end
        tBtn.BackgroundColor3, tBtn.TextColor3 = Color3.fromRGB(14, 165, 233), Color3.fromRGB(255, 255, 255)
        panel.Visible = true
    end)
end

-- Helper Components
local function makeToggle(parentPanel, text, callback)
    local btn = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.2,
        Font = Enum.Font.GothamMedium, Text = text .. " : OFF", TextColor3 = Color3.fromRGB(15, 23, 42), TextSize = 12
    }, parentPanel)
    make("UICorner", {CornerRadius = UDim.new(0, 6)}, btn)
    make("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Thickness = 1}, btn)
    
    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = text .. (state and " : ON" or " : OFF")
        btn.TextColor3 = state and Color3.fromRGB(14, 165, 233) or Color3.fromRGB(15, 23, 42)
        btn.BackgroundColor3 = state and Color3.fromRGB(240, 249, 255) or Color3.fromRGB(255, 255, 255)
        callback(state)
    end)
end

local function makeButton(parentPanel, text, callback)
    local btn = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.2,
        Font = Enum.Font.GothamMedium, Text = text, TextColor3 = Color3.fromRGB(15, 23, 42), TextSize = 12
    }, parentPanel)
    make("UICorner", {CornerRadius = UDim.new(0, 6)}, btn)
    make("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Thickness = 1}, btn)
    btn.MouseButton1Click:Connect(callback)
end

-- Profile Panel
local pPanel = contents["Profile"]

local wsC = make("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1}, pPanel)
make("TextLabel", {Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, Text = "WalkSpeed", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, wsC)
local wsBox = make("TextBox", {Size = UDim2.new(0.35, 0, 0.8, 0), Position = UDim2.new(0.65, 0, 0.1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.GothamMedium, Text = "16", TextColor3 = Color3.fromRGB(15, 23, 42), TextSize = 12}, wsC)
make("UICorner", {CornerRadius = UDim.new(0, 6)}, wsBox)

wsBox.FocusLost:Connect(function(e)
    if e then wsVal = tonumber(wsBox.Text) or 16 end
end)

local cfC = make("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1}, pPanel)
make("TextLabel", {Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, Text = "CFrame Speed", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, cfC)
local cfBox = make("TextBox", {Size = UDim2.new(0.35, 0, 0.8, 0), Position = UDim2.new(0.65, 0, 0.1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.GothamMedium, Text = "1", TextColor3 = Color3.fromRGB(15, 23, 42), TextSize = 12}, cfC)
make("UICorner", {CornerRadius = UDim.new(0, 6)}, cfBox)

cfBox.FocusLost:Connect(function(e)
    if e then cfSpeedVal = tonumber(cfBox.Text) or 1 end
end)

makeToggle(pPanel, "CFrame Speed Bypass", function(s) cfSpeedActive = s end)
makeToggle(pPanel, "NoClip", function(s) noclip = s end)
makeToggle(pPanel, "Infinite Jump", function(s) infJump = s end)

-- Menu Panel (Dual Teleport)
local mPanel = contents["Menu"]

makeToggle(mPanel, "Instant Prompt", function(s) instantPromptActive = s end)

Workspace.DescendantAdded:Connect(function(obj)
    if instantPromptActive and obj:IsA("ProximityPrompt") then
        obj.HoldDuration = 0
    end
end)

makeToggle(mPanel, "Tap TP (Mobile)", function(s) tapTpActive = s end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if tapTpActive and not gameProcessed then
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mouse = player:GetMouse()
            if mouse and mouse.Hit then
                safeTeleport(CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0)))
            end
        end
    end
end)

makeButton(mPanel, "Save Position 1", function()
    local char = player.Character
    if char then
        savedCFrame1 = char:GetPivot()
        floatBack1.Visible = true 
    end
end)

makeButton(mPanel, "Teleport Back 1", function()
    if savedCFrame1 then safeTeleport(savedCFrame1) end
end)

makeButton(mPanel, "Save Position 2", function()
    local char = player.Character
    if char then
        savedCFrame2 = char:GetPivot()
        floatBack2.Visible = true 
    end
end)

makeButton(mPanel, "Teleport Back 2", function()
    if savedCFrame2 then safeTeleport(savedCFrame2) end
end)

floatBack1.MouseButton1Click:Connect(function()
    if savedCFrame1 then safeTeleport(savedCFrame1) end
end)

floatBack2.MouseButton1Click:Connect(function()
    if savedCFrame2 then safeTeleport(savedCFrame2) end
end)

local tpBox = make("TextBox", {
    Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamMedium, Text = "", PlaceholderText = "Nama Player...",
    TextColor3 = Color3.fromRGB(15, 23, 42), TextSize = 12
}, mPanel)
make("UICorner", {CornerRadius = UDim.new(0, 6)}, tpBox)

makeButton(mPanel, "Teleport Ke Player", function()
    local targetName = string.lower(tpBox.Text)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and (string.find(string.lower(p.Name), targetName) or string.find(string.lower(p.DisplayName), targetName)) then
            if p.Character then
                safeTeleport(p.Character:GetPivot())
                break
            end
        end
    end
end)

makeButton(mPanel, "Spectate Player", function()
    local targetName = string.lower(tpBox.Text)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and (string.find(string.lower(p.Name), targetName) or string.find(string.lower(p.DisplayName), targetName)) then
            if p.Character and p.Character:FindFirstChildOfClass("Humanoid") then
                if not isSpectating then
                    originalCameraSubject = camera.CameraSubject
                    camera.CameraSubject = p.Character:FindFirstChildOfClass("Humanoid")
                    isSpectating = true
                else
                    camera.CameraSubject = originalCameraSubject or (player.Character and player.Character:FindFirstChildOfClass("Humanoid"))
                    isSpectating = false
                end
                break
            end
        end
    end
end)

-- Misc Panel
local miscPanel = contents["Misc"]

makeToggle(miscPanel, "Player ESP", function(s)
    espActive = s
    local function applyEsp(p)
        if p ~= player then
            local function onChar(char)
                if espActive then
                    if not char:FindFirstChild("HubHighlight") then
                        local hl = Instance.new("Highlight")
                        hl.Name = "HubHighlight"
                        hl.Adornee = char
                        hl.FillColor = Color3.fromRGB(14, 165, 233)
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.Parent = char
                    end
                else
                    local hl = char:FindFirstChild("HubHighlight")
                    if hl then hl:Destroy() end
                end
            end
            p.CharacterAdded:Connect(onChar)
            if p.Character then onChar(p.Character) end
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do applyEsp(p) end
end)

makeToggle(miscPanel, "Fly Mode", function(s)
    flyActive = s
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    if flyActive then
        local bv = Instance.new("BodyVelocity")
        bv.Name = "HubFlyVel"
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.zero
        bv.Parent = hrp
        
        local bg = Instance.new("BodyGyro")
        bg.Name = "HubFlyGyro"
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.CFrame = hrp.CFrame
        bg.Parent = hrp
    else
        if hrp:FindFirstChild("HubFlyVel") then hrp.HubFlyVel:Destroy() end
        if hrp:FindFirstChild("HubFlyGyro") then hrp.HubFlyGyro:Destroy() end
    end
end)

makeToggle(miscPanel, "Fullbright", function(s)
    fullbrightActive = s
    if fullbrightActive then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.GlobalShadows = false
    else
        Lighting.Ambient = Color3.fromRGB(127, 127, 127)
        Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
    end
end)

local fovC = make("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1}, miscPanel)
make("TextLabel", {Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, Text = "Field of View", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, fovC)
local fovBox = make("TextBox", {Size = UDim2.new(0.35, 0, 0.8, 0), Position = UDim2.new(0.65, 0, 0.1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.GothamMedium, Text = "70", TextColor3 = Color3.fromRGB(15, 23, 42), TextSize = 12}, fovC)
make("UICorner", {CornerRadius = UDim.new(0, 6)}, fovBox)

fovBox.FocusLost:Connect(function(e)
    if e then
        local val = tonumber(fovBox.Text) or 70
        camera.FieldOfView = math.clamp(val, 30, 120)
    end
end)

-- Server Hop & Setting
makeButton(contents["Server Hop"], "Rejoin Same Server", function()
    TeleportService:Teleport(game.PlaceId, player)
end)

makeToggle(contents["Setting"], "Anti-AFK", function(s)
    antiAfkActive = s
end)

player.Idled:Connect(function()
    if antiAfkActive then
        local VirtualUser = game:GetService("VirtualUser")
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end
end)

-- Loops
RunService.Stepped:Connect(function()
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum and hum.WalkSpeed ~= wsVal then
            hum.WalkSpeed = wsVal
        end
        if noclip then
            for _, p in ipairs(char:GetDescendants()) do 
                if p:IsA("BasePart") then p.CanCollide = false end 
            end
        end
        if flyActive and hrp then
            local bv = hrp:FindFirstChild("HubFlyVel")
            local bg = hrp:FindFirstChild("HubFlyGyro")
            if bv and bg then
                bg.CFrame = camera.CFrame
                local moveDir = hum.MoveDirection
                bv.Velocity = moveDir.Magnitude > 0 and (moveDir * flySpeed) or Vector3.zero
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    local char = player.Character
    if cfSpeedActive and char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.MoveDirection.Magnitude > 0 then
            char:PivotTo(char:GetPivot() + (hum.MoveDirection * cfSpeedVal))
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if infJump then
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Dragging System
local dragging, dragStart, startPos
topBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPos = true, i.Position, main.Position
    end
end)

local btnDragging, btnDragStart, btnStartPos
openBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        btnDragging, btnDragStart, btnStartPos = true, i.Position, openBtn.Position
    end
end)

local b1Drag, b1Start, b1Pos
floatBack1.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        b1Drag, b1Start, b1Pos = true, i.Position, floatBack1.Position
    end
end)

local b2Drag, b2Start, b2Pos
floatBack2.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        b2Drag, b2Start, b2Pos = true, i.Position, floatBack2.Position
    end
end)

UserInputService.InputChanged:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
        if dragging then
            local delta = i.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        elseif btnDragging then
            local delta = i.Position - btnDragStart
            openBtn.Position = UDim2.new(btnStartPos.X.Scale, btnStartPos.X.Offset + delta.X, btnStartPos.Y.Scale, btnStartPos.Y.Offset + delta.Y)
        elseif b1Drag then
            local delta = i.Position - b1Start
            floatBack1.Position = UDim2.new(b1Pos.X.Scale, b1Pos.X.Offset + delta.X, b1Pos.Y.Scale, b1Pos.Y.Offset + delta.Y)
        elseif b2Drag then
            local delta = i.Position - b2Start
            floatBack2.Position = UDim2.new(b2Pos.X.Scale, b2Pos.X.Offset + delta.X, b2Pos.Y.Scale, b2Pos.Y.Offset + delta.Y)
        end
    end
end)

UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then 
        dragging, btnDragging, b1Drag, b2Drag = false, false, false, false
    end
end)

minBtn.MouseButton1Click:Connect(function() 
    main.Visible = false 
    openBtn.Visible = true 
end)

openBtn.MouseButton1Click:Connect(function() 
    main.Visible = true 
    openBtn.Visible = false 
end)
