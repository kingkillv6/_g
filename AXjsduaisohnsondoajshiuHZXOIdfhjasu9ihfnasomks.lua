if not game:IsLoaded() then 
    game.Loaded:Wait()
end

if not syn or not protectgui then
    getgenv().protectgui = function() end
end

local SilentAimSettings = {
    Enabled = false,
    ClassName = "FuckOff",
    ToggleKey = "RightAlt",
    TeamCheck = false,
    VisibleCheck = false, 
    TargetPart = "HumanoidRootPart",
    SilentAimMethod = "Raycast",
    FOVRadius = 130,
    FOVVisible = false,
    ShowSilentAimTarget = false, 
    MouseHitPrediction = false,
    MouseHitPredictionAmount = 0.165,
    HitChance = 100
}


getgenv().SilentAimSettings = Settings
local MainFileName = "FuckOff"
local SelectedFile, FileToSave = "", ""

local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local GetChildren = game.GetChildren
local GetPlayers = Players.GetPlayers
local WorldToScreen = Camera.WorldToScreenPoint
local WorldToViewportPoint = Camera.WorldToViewportPoint
local GetPartsObscuringTarget = Camera.GetPartsObscuringTarget
local FindFirstChild = game.FindFirstChild
local RenderStepped = RunService.RenderStepped
local GuiInset = GuiService.GetGuiInset
local GetMouseLocation = UserInputService.GetMouseLocation

local resume = coroutine.resume 
local create = coroutine.create
local orbitEnabled = false
local checkTeams = true
local checkIfDead = true
local orbitMode = "Circular"
local orbitSpeed = 5
local orbitDistance = 5
local axisX, axisY, axisZ = 1, 0, 1
local currentAngle = 0
local targetPlayer = nil
local maxRange = 5

local function isAlive(player)
    return player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0
end

local function isTeammate(player)
    return checkTeams and player.Team == LocalPlayer.Team
end

local function getNearestValidPlayer()
    local closest, minDistance = nil, math.huge
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and isAlive(p) and not isTeammate(p) then
            local theirRoot = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if theirRoot then
                local dist = (theirRoot.Position - root.Position).Magnitude
                if dist < minDistance and dist <= maxRange then
                    closest = p
                    minDistance = dist
                end
            end
        end
    end

    return closest
end


RunService.Heartbeat:Connect(function(dt)
    if orbitEnabled and LocalPlayer.Character and isAlive(LocalPlayer) then
        if not targetPlayer or not isAlive(targetPlayer) or isTeammate(targetPlayer) then
            targetPlayer = getNearestValidPlayer()
        end
        if targetPlayer then
            local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root and targetRoot then
                currentAngle = currentAngle + orbitSpeed * dt
                local x = math.cos(currentAngle) * orbitDistance * axisX
                local y = math.sin(currentAngle) * orbitDistance * axisY
                local z = math.sin(currentAngle) * orbitDistance * axisZ

                local offset = Vector3.new(x, y, z)
                local newPos = targetRoot.Position + offset
                root.CFrame = CFrame.new(newPos, targetRoot.Position)
            end
        end
    end
end)
local ValidTargetParts = {"Head", "HumanoidRootPart"}
local PredictionAmount = 0.165

local mouse_box = Drawing.new("Square")
mouse_box.Visible = true 
mouse_box.ZIndex = 999 
mouse_box.Color = Color3.fromRGB(54, 57, 241)
mouse_box.Thickness = 20 
mouse_box.Size = Vector2.new(20, 20)
mouse_box.Filled = true 

local fov_circle = Drawing.new("Circle")
fov_circle.Thickness = 1
fov_circle.NumSides = 100
fov_circle.Radius = 180
fov_circle.Filled = false
fov_circle.Visible = false
fov_circle.ZIndex = 999
fov_circle.Transparency = 1
fov_circle.Color = Color3.fromRGB(54, 57, 241)

local ExpectedArguments = {
    FindPartOnRayWithIgnoreList = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Ray", "table", "boolean", "boolean"
        }
    },
    FindPartOnRayWithWhitelist = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Ray", "table", "boolean"
        }
    },
    FindPartOnRay = {
        ArgCountRequired = 2,
        Args = {
            "Instance", "Ray", "Instance", "boolean", "boolean"
        }
    },
    Raycast = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Vector3", "Vector3", "RaycastParams"
        }
    }
}

function CalculateChance(Percentage)
    Percentage = math.floor(Percentage)
    local chance = math.floor(Random.new().NextNumber(Random.new(), 0, 1) * 100) / 100
    return chance <= Percentage / 100
end


do 
    if not isfolder(MainFileName) then 
        makefolder(MainFileName);
    end
    
    if not isfolder(string.format("%s/%s", MainFileName, tostring(game.PlaceId))) then 
        makefolder(string.format("%s/%s", MainFileName, tostring(game.PlaceId)))
    end
end

local Files = listfiles(string.format("%s/%s", "FuckOff", tostring(game.PlaceId)))


local function GetFiles()
	local out = {}
	for i = 1, #Files do
		local file = Files[i]
		if file:sub(-4) == '.lua' then
			local pos = file:find('.lua', 1, true)
			local start = pos
			local char = file:sub(pos, pos)
			while char ~= '/' and char ~= '\\' and char ~= '' do
				pos = pos - 1
				char = file:sub(pos, pos)
			end
			if char == '/' or char == '\\' then
				table.insert(out, file:sub(pos + 1, start - 1))
			end
		end
	end
	
	return out
end

local function UpdateFile(FileName)
    assert(FileName or FileName == "string", "oopsies");
    writefile(string.format("%s/%s/%s.lua", MainFileName, tostring(game.PlaceId), FileName), HttpService:JSONEncode(SilentAimSettings))
end

local function LoadFile(FileName)
    assert(FileName or FileName == "string", "oopsies");
    
    local File = string.format("%s/%s/%s.lua", MainFileName, tostring(game.PlaceId), FileName)
    local ConfigData = HttpService:JSONDecode(readfile(File))
    for Index, Value in next, ConfigData do
        SilentAimSettings[Index] = Value
    end
end

local function getPositionOnScreen(Vector)
    local Vec3, OnScreen = WorldToScreen(Camera, Vector)
    return Vector2.new(Vec3.X, Vec3.Y), OnScreen
end

local function ValidateArguments(Args, RayMethod)
    local Matches = 0
    if #Args < RayMethod.ArgCountRequired then
        return false
    end
    for Pos, Argument in next, Args do
        if typeof(Argument) == RayMethod.Args[Pos] then
            Matches = Matches + 1
        end
    end
    return Matches >= RayMethod.ArgCountRequired
end

local function getDirection(Origin, Position)
    return (Position - Origin).Unit * 1000
end

local function getMousePosition()
    return GetMouseLocation(UserInputService)
end

local function IsPlayerVisible(Player)
    local PlayerCharacter = Player.Character
    local LocalPlayerCharacter = LocalPlayer.Character
    
    if not (PlayerCharacter or LocalPlayerCharacter) then return end 
    
    local PlayerRoot = FindFirstChild(PlayerCharacter, Options.TargetPart.Value) or FindFirstChild(PlayerCharacter, "HumanoidRootPart")
    
    if not PlayerRoot then return end 
    
    local CastPoints, IgnoreList = {PlayerRoot.Position, LocalPlayerCharacter, PlayerCharacter}, {LocalPlayerCharacter, PlayerCharacter}
    local ObscuringObjects = #GetPartsObscuringTarget(Camera, CastPoints, IgnoreList)
    
    return ((ObscuringObjects == 0 and true) or (ObscuringObjects > 0 and false))
end

local function getClosestPlayer()
    if not Options.TargetPart.Value then return end
    local Closest
    local DistanceToMouse
    for _, Player in next, GetPlayers(Players) do
        if Player == LocalPlayer then continue end
        if Toggles.TeamCheck.Value and Player.Team == LocalPlayer.Team then continue end

        local Character = Player.Character
        if not Character then continue end
        
        if Toggles.VisibleCheck.Value and not IsPlayerVisible(Player) then continue end

        local HumanoidRootPart = FindFirstChild(Character, "HumanoidRootPart")
        local Humanoid = FindFirstChild(Character, "Humanoid")
        if not HumanoidRootPart or not Humanoid or Humanoid and Humanoid.Health <= 0 then continue end

        local ScreenPosition, OnScreen = getPositionOnScreen(HumanoidRootPart.Position)
        if not OnScreen then continue end

        local Distance = (getMousePosition() - ScreenPosition).Magnitude
        if Distance <= (DistanceToMouse or Options.Radius.Value or 2000) then
            Closest = ((Options.TargetPart.Value == "Random" and Character[ValidTargetParts[math.random(1, #ValidTargetParts)]]) or Character[Options.TargetPart.Value])
            DistanceToMouse = Distance
        end
    end
    return Closest
end


local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = '[ Pick Hub ]',
    Center = true, 
    AutoShow = false,
    TabPadding = 8,
    MenuFadeTime = 0,
    Size = UDim2.new(0, 445, 0, 345)
})



local GeneralTab = Window:AddTab("General")
local MainBOX = GeneralTab:AddLeftTabbox("Main") do
    local Main = MainBOX:AddTab("Main")
    Main:AddToggle("aim_Enabled", {Text = "Enabled"}):AddKeyPicker("aim_Enabled_KeyPicker", {Default = "RightAlt", SyncToggleState = true, Mode = "Toggle", Text = "Enabled", NoUI = false});
    Options.aim_Enabled_KeyPicker:OnClick(function()
        SilentAimSettings.Enabled = not SilentAimSettings.Enabled
        
        Toggles.aim_Enabled.Value = SilentAimSettings.Enabled
        Toggles.aim_Enabled:SetValue(SilentAimSettings.Enabled)
        
        mouse_box.Visible = SilentAimSettings.Enabled
    end)
    
    Main:AddToggle("TeamCheck", {Text = "Team Check", Default = SilentAimSettings.TeamCheck}):OnChanged(function()
        SilentAimSettings.TeamCheck = Toggles.TeamCheck.Value
    end)
    Main:AddToggle("VisibleCheck", {Text = "Visible Check", Default = SilentAimSettings.VisibleCheck}):OnChanged(function()
        SilentAimSettings.VisibleCheck = Toggles.VisibleCheck.Value
    end)
    Main:AddDropdown("TargetPart", {AllowNull = true, Text = "Target Part", Default = SilentAimSettings.TargetPart, Values = {"Head", "HumanoidRootPart", "Random"}}):OnChanged(function()
        SilentAimSettings.TargetPart = Options.TargetPart.Value
    end)
    Main:AddDropdown("Method", {AllowNull = true, Text = "Silent Aim Method", Default = SilentAimSettings.SilentAimMethod, Values = {
        "Raycast","FindPartOnRay",
        "FindPartOnRayWithWhitelist",
        "FindPartOnRayWithIgnoreList",
        "Mouse.Hit/Target"
    }}):OnChanged(function() 
        SilentAimSettings.SilentAimMethod = Options.Method.Value 
    end)
    Main:AddSlider('HitChance', {
        Text = 'Hit chance',
        Default = 100,
        Min = 0,
        Max = 100,
        Rounding = 1,
        Compact = false,
    })
    Options.HitChance:OnChanged(function()
        SilentAimSettings.HitChance = Options.HitChance.Value
    end)
end



local MiscellaneousBOX = GeneralTab:AddRightTabbox("Miscellaneous")
local FieldOfViewBOX = GeneralTab:AddRightTabbox("Field Of View") do
    local Main = FieldOfViewBOX:AddTab("Visuals")
    Main:AddToggle("Visible", {Text = "Show FOV Circle"}):AddColorPicker("Color", {Default = Color3.fromRGB(54, 57, 241)}):OnChanged(function()
        fov_circle.Visible = Toggles.Visible.Value
        SilentAimSettings.FOVVisible = Toggles.Visible.Value
    end)
    Main:AddSlider("Radius", {Text = "FOV Circle Radius", Min = 0, Max = 2000, Default = 130, Rounding = 0}):OnChanged(function()
        fov_circle.Radius = Options.Radius.Value
        SilentAimSettings.FOVRadius = Options.Radius.Value
    end)
    Main:AddToggle("MousePosition", {Text = "Show Silent Aim Target"}):AddColorPicker("MouseVisualizeColor", {Default = Color3.fromRGB(54, 57, 241)}):OnChanged(function()
        mouse_box.Visible = Toggles.MousePosition.Value 
        SilentAimSettings.ShowSilentAimTarget = Toggles.MousePosition.Value 
    end)
    local PredictionTab = MiscellaneousBOX:AddTab("Prediction")
    PredictionTab:AddToggle("Prediction", {Text = "Mouse.Hit/Target Prediction"}):OnChanged(function()
        SilentAimSettings.MouseHitPrediction = Toggles.Prediction.Value
    end)
    PredictionTab:AddSlider("Amount", {Text = "Prediction Amount", Min = 0.165, Max = 1, Default = 0.165, Rounding = 3}):OnChanged(function()
        PredictionAmount = Options.Amount.Value
        SilentAimSettings.MouseHitPredictionAmount = Options.Amount.Value
    end)
end


--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--// ESP Settings Table
_G.ESPSettings = {
    BoxESP = false,
    BoxColor = Color3.fromRGB(0, 255, 0),

    NameESP = false,
    NameColor = Color3.fromRGB(255, 255, 255),

    StudESP = false,
    StudColor = Color3.fromRGB(200, 200, 200),

    Font = Enum.Font.Gotham,
    TextSize = 14,
    Smooth = false
}

local localPlayer = Players.LocalPlayer
local espFolder = Instance.new("Folder", game.CoreGui)
espFolder.Name = "UniversalESP"

local espObjects = {}

--// Cleanup function
local function cleanupESP(player)
    if espObjects[player] then
        for _, obj in pairs(espObjects[player]) do
            if obj and obj.Destroy then pcall(function() obj:Destroy() end) end
        end
        espObjects[player] = nil
    end
end

--// Create ESP for a Character
--// Create ESP for a Character
local function createESP(player, character)
    cleanupESP(player)

    local espParts = {}

    --// Box ESP
    if _G.ESPSettings.BoxESP then
        local highlight = Instance.new("Highlight")
        highlight.Adornee = character
        highlight.FillTransparency = 1
        
        -- Check if the player is in a team, else default to white
        if player.Team then
            highlight.OutlineColor = player.Team.TeamColor.Color  -- Use team color
        else
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)  -- Default to white
        end

        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = espFolder
        table.insert(espParts, highlight)
    end

    --// Name + Studs Billboard
    if _G.ESPSettings.NameESP or _G.ESPSettings.StudESP then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "ESP_Billboard"
            billboard.AlwaysOnTop = true
            billboard.Size = UDim2.new(0, 200, 0, 50) -- Fixed size in pixels
            billboard.StudsOffset = Vector3.new(0, 3.5, 0) -- Position above the player
            billboard.Adornee = root
            billboard.Parent = espFolder

            -- Name Text Label
            if _G.ESPSettings.NameESP then
                local nameLabel = Instance.new("TextLabel", billboard)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
                nameLabel.Position = UDim2.new(0, 0, 0, 0)
                nameLabel.Text = player.Name
                nameLabel.TextColor3 = _G.ESPSettings.NameColor
                nameLabel.TextSize = _G.ESPSettings.TextSize
                nameLabel.Font = _G.ESPSettings.Font
                nameLabel.TextScaled = false -- Disable automatic scaling
            end

            -- Stud Distance Text Label
            if _G.ESPSettings.StudESP then
                local distLabel = Instance.new("TextLabel", billboard)
                distLabel.BackgroundTransparency = 1
                distLabel.Size = UDim2.new(1, 0, 0.5, 0)
                distLabel.Position = UDim2.new(0, 0, 0.5, 0)
                distLabel.TextColor3 = _G.ESPSettings.StudColor
                distLabel.TextSize = _G.ESPSettings.TextSize
                distLabel.Font = _G.ESPSettings.Font
                distLabel.TextScaled = false -- Disable automatic scaling

                -- Update distance dynamically
                RunService.RenderStepped:Connect(function()
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local dist = (localPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                        distLabel.Text = string.format("%.0f studs", dist)
                    end
                end)
            end

            table.insert(espParts, billboard)
        end
    end
    espObjects[player] = espParts
    local hum = character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Died:Connect(function()
            cleanupESP(player)
        end)
    end
end



local function onPlayerAdded(player)
    player.CharacterAdded:Connect(function(character)
        createESP(player, character)
    end)
    player.CharacterRemoving:Connect(function(character)
        cleanupESP(player)  -- Clean up ESP when the player resets (removes character)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= localPlayer then
        onPlayerAdded(player)
        if player.Character then
            createESP(player, player.Character)
        end
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
    cleanupESP(player)
end)


local ESPTab = MiscellaneousBOX:AddTab("ESP")

ESPTab:AddToggle("BoxESP", {Text = "Box ESP"}):AddColorPicker("BoxColor", {Default = Color3.fromRGB(0, 255, 0)}):OnChanged(function()
    _G.ESPSettings.BoxESP = Toggles.BoxESP.Value
    _G.ESPSettings.BoxColor = Options.BoxColor.Value
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            createESP(player, player.Character)
        end
    end
end)


ESPTab:AddToggle("NameESP", {Text = "Username ESP"}):AddColorPicker("NameColor", {Default = Color3.fromRGB(255, 255, 255)}):OnChanged(function()
    _G.ESPSettings.NameESP = Toggles.NameESP.Value
    _G.ESPSettings.NameColor = Options.NameColor.Value
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            createESP(player, player.Character)
        end
    end
end)


ESPTab:AddToggle("StudESP", {Text = "Stud Distance ESP"}):AddColorPicker("StudColor", {Default = Color3.fromRGB(200, 200, 200)}):OnChanged(function()
    _G.ESPSettings.StudESP = Toggles.StudESP.Value
    _G.ESPSettings.StudColor = Options.StudColor.Value
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            createESP(player, player.Character)
        end
    end
end)





resume(create(function()
    RenderStepped:Connect(function()
        if Toggles.MousePosition.Value and Toggles.aim_Enabled.Value then
            if getClosestPlayer() then 
                local Root = getClosestPlayer().Parent.PrimaryPart or getClosestPlayer()
                local RootToViewportPoint, IsOnScreen = WorldToViewportPoint(Camera, Root.Position);
                mouse_box.Visible = IsOnScreen
                mouse_box.Position = Vector2.new(RootToViewportPoint.X, RootToViewportPoint.Y)
            else 
                mouse_box.Visible = false 
                mouse_box.Position = Vector2.new()
            end
        end
        
        if Toggles.Visible.Value then 
            fov_circle.Visible = Toggles.Visible.Value
            fov_circle.Color = Options.Color.Value
            fov_circle.Position = getMousePosition()
        end
    end)
end))

-- hooks
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local Method = getnamecallmethod()
    local Arguments = {...}
    local self = Arguments[1]
    local chance = CalculateChance(SilentAimSettings.HitChance)
    if Toggles.aim_Enabled.Value and self == workspace and not checkcaller() and chance == true then
        if Method == "FindPartOnRayWithIgnoreList" and Options.Method.Value == Method then
            if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithIgnoreList) then
                local A_Ray = Arguments[2]

                local HitPart = getClosestPlayer()
                if HitPart then
                    local Origin = A_Ray.Origin
                    local Direction = getDirection(Origin, HitPart.Position)
                    Arguments[2] = Ray.new(Origin, Direction)

                    return oldNamecall(unpack(Arguments))
                end
            end
        elseif Method == "FindPartOnRayWithWhitelist" and Options.Method.Value == Method then
            if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithWhitelist) then
                local A_Ray = Arguments[2]

                local HitPart = getClosestPlayer()
                if HitPart then
                    local Origin = A_Ray.Origin
                    local Direction = getDirection(Origin, HitPart.Position)
                    Arguments[2] = Ray.new(Origin, Direction)

                    return oldNamecall(unpack(Arguments))
                end
            end
        elseif (Method == "FindPartOnRay" or Method == "findPartOnRay") and Options.Method.Value:lower() == Method:lower() then
            if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRay) then
                local A_Ray = Arguments[2]

                local HitPart = getClosestPlayer()
                if HitPart then
                    local Origin = A_Ray.Origin
                    local Direction = getDirection(Origin, HitPart.Position)
                    Arguments[2] = Ray.new(Origin, Direction)

                    return oldNamecall(unpack(Arguments))
                end
            end
        elseif Method == "Raycast" and Options.Method.Value == Method then
            if ValidateArguments(Arguments, ExpectedArguments.Raycast) then
                local A_Origin = Arguments[2]

                local HitPart = getClosestPlayer()
                if HitPart then
                    Arguments[3] = getDirection(A_Origin, HitPart.Position)

                    return oldNamecall(unpack(Arguments))
                end
            end
        end
    end
    return oldNamecall(...)
end))


local oldIndex = nil 
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, Index)
    if self == Mouse and not checkcaller() and Toggles.aim_Enabled.Value and Options.Method.Value == "Mouse.Hit/Target" and getClosestPlayer() then
        local HitPart = getClosestPlayer()
         
        if Index == "Target" or Index == "target" then 
            return HitPart
        elseif Index == "Hit" or Index == "hit" then 
            return ((Toggles.Prediction.Value and (HitPart.CFrame + (HitPart.Velocity * PredictionAmount))) or (not Toggles.Prediction.Value and HitPart.CFrame))
        elseif Index == "X" or Index == "x" then 
            return self.X 
        elseif Index == "Y" or Index == "y" then 
            return self.Y 
        elseif Index == "UnitRay" then 
            return Ray.new(self.Origin, (self.Hit - self.Origin).Unit)
        end
    end

    return oldIndex(self, Index)
end))




local OrbCannon = Window:AddTab("Orb Cannon")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Local Player
local LocalPlayer = Players.LocalPlayer

-- Orbit Settings
local OrbitSettings = {
    Enabled = false,
    TeamCheck = true,
    DeadCheck = true,
    Mode = "Circular",
    Speed = 5,
    Radius = 5,
    YOffset = 0,
    Range = 100
}

-- Variables
local currentTarget = nil
local orbitAngle = 0

-- Functions to check player validity
local function isAlive(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function isTeammate(player)
    return player.Team == LocalPlayer.Team
end

local function isValidTarget(player)
    if not player or player == LocalPlayer then return false end
    if OrbitSettings.TeamCheck and isTeammate(player) then return false end
    if OrbitSettings.DeadCheck and not isAlive(player) then return false end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root or not myRoot then return false end

    return (myRoot.Position - root.Position).Magnitude <= OrbitSettings.Range
end

local function findTarget()
    local closest, closestDist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local dist = (LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
            if dist < closestDist then
                closest = player
                closestDist = dist
            end
        end
    end
    return closest
end

-- Orbit Logic
RunService.Heartbeat:Connect(function(dt)
    if OrbitSettings.Enabled then
        if not currentTarget or not isValidTarget(currentTarget) then
            currentTarget = findTarget()
        end
        if currentTarget and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            orbitAngle += OrbitSettings.Speed * dt
            local root = LocalPlayer.Character.HumanoidRootPart
            local targetRoot = currentTarget.Character.HumanoidRootPart

            local x = math.cos(orbitAngle) * OrbitSettings.Radius
            local z = math.sin(orbitAngle) * OrbitSettings.Radius
            if OrbitSettings.Mode == "Elliptical" then
                x = x * 1.5
                z = z * 0.7
            end
            local y = OrbitSettings.YOffset

            local offset = Vector3.new(x, y, z)
            local orbitPos = targetRoot.Position + offset
            root.CFrame = CFrame.new(orbitPos, targetRoot.Position)
        end
    end
end)
local MainBOX = OrbCannon:AddLeftTabbox("Main")
do
    local Main = MainBOX:AddTab("Simple Orb")
    Main:AddToggle("orb_enabled", {Text = "Enabled", Default = false})
    :OnChanged(function()
        OrbitSettings.Enabled = Toggles.orb_enabled.Value
    end)
    Main:AddToggle("orb_teamcheck", {Text = "Team Check", Default = true})
    :OnChanged(function()
        OrbitSettings.TeamCheck = Toggles.orb_teamcheck.Value
    end)
    Main:AddToggle("orb_deadcheck", {Text = "Dead Check", Default = true})
    :OnChanged(function()
        OrbitSettings.DeadCheck = Toggles.orb_deadcheck.Value
    end)
    Main:AddSlider("orb_speed", {
        Text = "Orbit Speed",
        Min = 1,
        Max = 20,
        Default = 5,
        Rounding = 1
    }):OnChanged(function(value)
        OrbitSettings.Speed = value
    end)
    Main:AddSlider("orb_radius", {
        Text = "Orbit Radius",
        Min = 1,
        Max = 20,
        Default = 5,
        Rounding = 1
    }):OnChanged(function(value)
        OrbitSettings.Radius = value
    end)

    Main:AddSlider("orb_yoffset", {
        Text = "Y Offset",
        Min = -10,
        Max = 10,
        Default = 0,
        Rounding = 1
    }):OnChanged(function(value)
        OrbitSettings.YOffset = value
    end)

    Main:AddSlider("orb_range", {
        Text = "Target Range",
        Min = 10,
        Max = 900,
        Default = 100,
        Rounding = 1
    }):OnChanged(function(value)
        OrbitSettings.Range = value
    end)
end

Library:OnUnload(function()
    Library.Unloaded = true
    Enabled = false
    TeamCheck = false
    VisibleCheck = false
    FOVVisible = false
    ShowSilentAimTarget = false
    MouseHitPrediction = false
end)

local UISettings = Window:AddTab('UI Settings')
local MenuGroup = UISettings:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'Delete', NoUI = true, Text = 'Menu keybind' })
Library.ToggleKeybind = Options.MenuKeybind
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('AimTest')
SaveManager:SetFolder('AimTest/Aimbot')
SaveManager:BuildConfigSection(UISettings)
ThemeManager:ApplyToTab(UISettings)
SaveManager:LoadAutoloadConfig()
