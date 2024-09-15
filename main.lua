local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Player = game:GetService("Players").LocalPlayer

horseList = {"Akhal-Teke", "Andalusian", "Appaloosa", "Arabian", "Clydesdale", "Dutch Warmblood", "Fjord", "Friesian", "Icelandic", "Marwari", "Mustang", "Paint Horse", "Percheron", "Quarter Horse", "Shire", "Thoroughbred"}
islandList = {"Mainland", "Blizzard Island", "Forest Island", "Royal Island", "Desert Island", "Mountain Island", "Jungle Island", "Lunar Island", "Volcano Island", "Training island", "RP Island", "Wild Island", "Trading Hub", "Breeding Hub"}

local tool = nil
local remote = 1
local remoteFound = false
horseEspTable = {}
collectableEspTable = {}
rockEspTable = {}

function getList(all)
    local Islands = Workspace.Islands
    local currentIsland = nil

    for _, v in pairs(Islands:GetDescendants()) do
        if v.Name == Player.Name then
            currentIsland = v.Parent
            break
        end
    end

    return currentIsland:GetDescendants()
end

function callRemoteFunctions(...)
    for i, v in pairs(game:GetService("ReplicatedStorage").Communication.Functions:GetChildren()) do
        v:FireServer(...)
    end
end

function callRemoteEvents(...)
    for i, v in pairs(game:GetService("ReplicatedStorage").Communication.Events:GetChildren()) do
        v:FireServer(...)
    end
end

local function findTargetMeshPart(target)
    for _, descendant in ipairs(target:GetChildren()) do
        if descendant:IsA("MeshPart") then
            return descendant
        end
    end
    return nil
end

local function isCollectableDetected(insert)
    if not insert:IsA("Model") then return false end
    local itemName = insert:GetAttribute("itemName")
    local health = insert:GetAttribute("health")
    local shopItem = insert:GetAttribute("isShopItem")
    if itemName and not health and not shopItem then
        return insert
    end

    for _, child in ipairs(insert:GetChildren()) do
        local childItemName = child:GetAttribute("itemName")
        local childHealth = child:GetAttribute("health")
        local childShopItem = child:GetAttribute("isShopItem")
        if childItemName and not childHealth and not childShopItem then
            return child
        end
    end

    return false
end

local function isRockDetected(insert)
    if not insert:IsA("Model") then return false end
    local itemName = insert:GetAttribute("itemName")
    local health = insert:GetAttribute("health")
    local shopItem = insert:GetAttribute("isShopItem")
    local scale = insert:GetAttribute("__originalScale")
    if itemName and health and scale and not shopItem then
        return insert
    end

    for _, child in ipairs(insert:GetChildren()) do
        local childItemName = child:GetAttribute("itemName")
        local childHealth = child:GetAttribute("health")
        local childShopItem = child:GetAttribute("isShopItem")
        local childScale = child:GetAttribute("__originalScale")
        if childItemName and childScale and childHealth and not childShopItem then
            return child
        end
    end

    return false
end

local function isHorseDetected(insert)
    if not insert:IsA("Model") then return false end
    if not insert:FindFirstChild("OverheadPart") then return false end
    local species = insert:GetAttribute("species")
    local owner = insert:GetAttribute("owner")
    local parent = insert.Parent
    if species == "Horse" and not owner and parent.Name == "Animals" then
        return true
    end
    return false
end

function esp(item, name, color)
    local text = Instance.new("BillboardGui")
	text.Name = item.Name
	text.Adornee = item
	text.Size = UDim2.new(0, 200, 0, 50)
	text.StudsOffset = Vector3.new(0, 2, 0)
	text.AlwaysOnTop = true
	text.Parent = game.CoreGui
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Text = name
	label.TextColor3 = color
	label.BackgroundTransparency = 1
	label.TextStrokeTransparency = 0
	label.TextScaled = false
	label.Parent = text
    return text
end

local Window = Fluent:CreateWindow({
    Title = "Wild Horse Islands",
    SubTitle = "by Rattles",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.Home
})

--Fluent provides Lucide Icons https://lucide.dev/icons/ for the tabs, icons are optional
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "house" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    AutoFarm = Window:AddTab({ Title = "Auto Farm", Icon = "lasso" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "plane" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

do
    -- Main
    local NotifyHorse = Tabs.Main:AddToggle("Notify Horse Spawn", {
        Title = "Notify Horse Spawn",
        Description = "Notify when horses spawn",
        Default = false
    })

    local NotifyHorseList = Tabs.Main:AddDropdown("Horse List", {
        Title = "Notify List",
        Description = "List of horses to notify",
        Values = horseList,
        Multi = true,
        Default = {"Shire"}
    })

    Tabs.Main:AddButton({
        Title = "Disable Lava",
        Callback = function()
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("TouchTransmitter") then
                    if v.Parent.Name == "Part" then
                        v:Destroy()
                    end
                end
            end
            Fluent:Notify({
                Title = "Disabled Lava Death",
                Content = "You can safely touch lava now.",
                Duration = 5
            })
        end
    })

    -- Visuals
    local HorseEsp = Tabs.Visuals:AddToggle("Horse Esp", {
        Title = "Horse Esp",
        Default = false
    })

    local CollectablesEsp = Tabs.Visuals:AddToggle("Collectable Esp", {
        Title = "Collectable Esp",
        Default = false
    })

    local RockEsp = Tabs.Visuals:AddToggle("Rock Esp", {
        Title = "Rock Esp",
        Default = false
    })

    local HorseEspColor = Tabs.Visuals:AddColorpicker("Horse Colorpicker", {
        Title = "Horse Esp Color",
        Default = Color3.fromRGB(255, 255, 0)
    })

    local CollectableEspColor = Tabs.Visuals:AddColorpicker("Collectable Colorpicker", {
        Title = "Collectable Esp Color",
        Default = Color3.fromRGB(0, 255, 0)
    })

    local RockEspColor = Tabs.Visuals:AddColorpicker("Rock Colorpicker", {
        Title = "Rock Esp Color",
        Default = Color3.fromRGB(0, 255, 200)
    })

    -- Visuals Toggle Detection
    HorseEsp:OnChanged(function()
        if HorseEsp.Value then
            for i, v in pairs(getList(false)) do
                if isHorseDetected(v) then
                    local breedLabel = v.OverheadPart:FindFirstChild("Overhead") and v.OverheadPart.Overhead:FindFirstChild("BreedLabel")
                    local e = esp(v, breedLabel.Text,HorseEspColor.Value)
                    table.insert(horseEspTable, e)
                end
            end
        else
            for i = #horseEspTable, 1, -1 do
                local v = horseEspTable[i]
                if v then
                    v:Destroy()
                    table.remove(horseEspTable, i)
                end
            end
        end
    end)

    CollectablesEsp:OnChanged(function()
        if CollectablesEsp.Value then
            for i, v in pairs(getList(false)) do
                local item = isCollectableDetected(v)
                if item then
                    local itemName = item:GetAttribute("itemName")
                    local e = esp(item, itemName, CollectableEspColor.Value)
                    table.insert(collectableEspTable, e)
                end
            end
        else
            for i = #collectableEspTable, 1, -1 do
                local v = collectableEspTable[i]
                if v then
                    v:Destroy()
                    table.remove(collectableEspTable, i)
                end
            end
        end
    end)

    RockEsp:OnChanged(function()
        if RockEsp.Value then
            for i, v in pairs(getList(false)) do
                local item = isRockDetected(v)
                if item then
                    local itemName = item:GetAttribute("itemName")
                    local mesh = findTargetMeshPart(item)
                    local e = esp(item, itemName, if mesh then mesh.Color else RockEspColor.Value)
                    table.insert(rockEspTable, e)
                end
            end
        else
            for i = #rockEspTable, 1, -1 do
                local v = rockEspTable[i]
                if v then
                    v:Destroy()
                    table.remove(rockEspTable, i)
                end
            end
        end
    end)

    HorseEspColor:OnChanged(function()
        for _, v in pairs(horseEspTable) do
            v:FindFirstChild("TextLabel").TextColor3 = HorseEspColor.Value
        end
    end)

     CollectableEspColor:OnChanged(function()
        for _, v in pairs(collectableEspTable) do
            v:FindFirstChild("TextLabel").TextColor3 = CollectableEspColor.Value
        end
    end)

    RockEspColor:OnChanged(function()
        for _, v in pairs(rockEspTable) do
            v:FindFirstChild("TextLabel").TextColor3 = RockEspColor.Value
        end
    end)

    -- Auto Farm
    local ToggleAutoFarm = Tabs.AutoFarm:AddToggle("Auto Farm", {
        Title = "Auto Farm",
        Description = "Start Auto Farm",
        Default = false
    })

    local AutoFarmSelect = Tabs.AutoFarm:AddDropdown("Auto Farm Select", {
        Title = "Select",
        Description = "Select what to farm",
        Values = {"Horses", "Rocks","Collectables"},
        Multi = false,
        Default = 1
    })

    local OnlyCurrent = Tabs.AutoFarm:AddToggle("Only Current Island", {
        Title = "Only Current Island",
        Description = "Only farm from current island",
        Default = false
    })

    local RemoteId = Tabs.AutoFarm:AddInput("RemoteId", {
        Title = "RemoteID",
        Default = 1,
        Placeholder = 1,
        Numeric = true,
        Finished = true,
        Callback = function(Value)
            remote = Value
        end
    })

    local Delay = Tabs.AutoFarm:AddInput("Delay", {
        Title = "Delay",
        Default = 1,
        Placeholder = 1,
        Numeric = true,
        Finished = true,
    })

    local function scanForTarget()
        local target = nil
        local targetMesh = nil
    
        if AutoFarmSelect.Value == "Horses" then
            for i, v in pairs(getList(not OnlyCurrent.Value)) do
                if isHorseDetected(v) then
                    target = v
                    targetMesh = findTargetMeshPart(v)
                    break
                end
            end
        elseif AutoFarmSelect.Value == "Rocks" then
            for i, v in pairs(getList(true)) do
                if isRockDetected(v) then
                    targetMesh = findTargetMeshPart(v)
                    if targetMesh then
                        target = v
                        break
                    end
                end
            end
        elseif AutoFarmSelect.Value == "Collectables" then
            for i, v in pairs(getList(true)) do
                if isCollectableDetected(v) then
                    target = v
                    targetMesh = findTargetMeshPart(v)
                    break
                end
            end
        end
        return target, targetMesh
    end

    -- Auto Farm Toggle Detection
    ToggleAutoFarm:OnChanged(function()
        local target = nil
        local targetMesh = nil
        local heartbeatConnection = nil

        local function resetTarget()
            target = nil
            targetMesh = nil
            if heartbeatConnection then
                heartbeatConnection:Disconnect()
                heartbeatConnection = nil
            end
        end

        local scanLoop = coroutine.create(function()
            while ToggleAutoFarm.Value do

                if not target or not targetMesh then
                    target, targetMesh = scanForTarget()
                end

                if target and targetMesh then
                    if not heartbeatConnection then
                        heartbeatConnection = RunService.Heartbeat:Connect(function()
                            if target and targetMesh and ToggleAutoFarm.Value then
                                local offset = Vector3.new(0, 5, 0)
                                Player.Character.HumanoidRootPart.CFrame = targetMesh.CFrame + offset
                            else
                                resetTarget()
                            end
                        end)
                    end

                    -- coroutine.wrap(function()
                    --     while target and targetMesh and ToggleAutoFarm.Value do
                    --         task.wait(0.5)
                    --         -- if remote >= 73 and not remoteFound then
                    --         --     remote = 1
                    --         -- end

                    --         print("Trying Remote: " .. remote)
                    --         local remoteEvent = game:GetService("ReplicatedStorage").Communication.Functions:GetChildren()[tonumber(remote)]
                    --         local args = {
                    --             [1] = "",
                    --             [2] = "Engage",
                    --             [3] = target
                    --         }
                    --         -- local args = {
                    --         --     [1] = "Collect",
                    --         --     [2] = target
                    --         -- }

                    --         remoteEvent:FireServer(unpack(args))
                    --         -- remote += 1
                    --         -- callRemoteFunctions(unpack(args))
                    --         targetMesh.Destroying:Wait()
                    --     end
                    -- end)()

                    task.wait(0.5)
                    if AutoFarmSelect.Value == "Rocks" then
                        local remoteEvent = game:GetService("ReplicatedStorage").Communication.Functions:GetChildren()[tonumber(remote)]
                        local args = {
                            [1] = "",
                            [2] = "Engage",
                            [3] = target
                        }
                        remoteEvent:FireServer(unpack(args))
                    end

                    targetMesh.Destroying:Wait()
                    resetTarget()
                else
                    wait(1)
                end
            end

            resetTarget()
        end)

        if ToggleAutoFarm.Value then
            coroutine.resume(scanLoop)
        else
            resetTarget()
        end
    end)

    -- Teleport
    local TeleportLocation = Tabs.Teleport:AddDropdown("Teleport Location", {
        Title = "Teleport Location",
        Description = "Select an island to teleport to",
        Values = islandList,
        Multi = false,
        Default = 1
    })

    Tabs.Teleport:AddButton({
        Title = "Teleport",
        Callback = function()
            callRemoteFunctions("", "Travel", TeleportLocation.Value)
        end
    })

    -- Spawn Detection
    Workspace.Islands.DescendantAdded:Connect(function(insert)
        task.wait(0.2)

        -- Detect Horses
        if isHorseDetected(insert) then
            local breedLabel = insert.OverheadPart:FindFirstChild("Overhead") and insert.OverheadPart.Overhead:FindFirstChild("BreedLabel")

            -- Nofify
            if NotifyHorse.Value then
                if table.find(NotifyHorseList.Values, breedLabel.Text) then
                    Fluent:Notify({
                        Title = "Horse Spawned",
                        Content = breedLabel.Text,
                        Duration = 5
                    })
                end
            end

            -- ESP
            if HorseEsp.Value then
                local e = esp(insert, breedLabel.Text, HorseEspColor.Value)
                table.insert(horseEspTable, e)
            end

        end

        -- Detect Collectables
        local item = isCollectableDetected(insert)
        if item then
            local itemName = item:GetAttribute("itemName")

            -- ESP
            if CollectablesEsp.Value then
                local e = esp(item, itemName, CollectableEspColor.Value)
                table.insert(collectableEspTable, e)
            end
        end

        -- Detect Ores
        local rock = isRockDetected(insert)
        if rock then
            local itemName = insert:GetAttribute("itemName")
            local mesh = findTargetMeshPart(insert)

            -- ESP
            if RockEsp.Value then
                local e = esp(item, itemName, if mesh then mesh.Color else RockEspColor.Value)
                table.insert(rockEspTable, e)
            end
        end

    end)

    -- Detect Remote
    for _, v in ipairs(game:GetService("ReplicatedStorage").Communication.Events:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            v.OnClientEvent:Connect(function(...)
                local args = {...}
                if args[2] == "equipped" then
                    if args[3] == nil then
                        tool = nil
                    else
                        tool = args[5]
                    end
                end
            end)
        end
    end

end

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/wild-horse-islands-rattles")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Wild Horse Islands",
    Content = "The script has been loaded.",
    Duration = 5
})
