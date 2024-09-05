local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Player = game:GetService("Players").LocalPlayer

horseList = {"Akhal-Teke", "Andalusian", "Appaloosa", "Arabian", "Clydesdale", "Dutch Warmblood", "Fjord", "Friesian", "Icelandic", "Marwari", "Mustang", "Paint Horse", "Percheron", "Quarter Horse", "Shire", "Thoroughbred"}

horseEspTable = {}
collectablesEspTable = {}

function getList(all, type)
    local items = {}
    local Islands = Workspace.Islands
    local currentIsland = nil

    for _, descendant in pairs(Islands:GetDescendants()) do
        if descendant.Name == Player.Name then
            currentIsland = descendant.Parent.Name
            break
        end
    end

    if all or not currentIsland then
        for i,v in pairs(Islands:GetDescendants()) do
            if v.Parent.Name == type then
                table.insert(items, v)
            end
        end
    else
        for i,v in pairs(Islands[currentIsland]:GetDescendants()) do
            if v.Parent.Name == type then
                table.insert(items, v)
            end
        end
    end

    return items
end

-- for i, v in pairs(getList(false, "Collectables")) do
--     local item = nil
--     if v:GetAttributes() and v:GetAttribute("itemName") then
--         item = v
--     else
--         for _, s in pairs(v:GetChildren()) do
--             if s:GetAttributes() and s:GetAttribute("itemName") then
--                 item = s
--             end
--         end
--     end

--     print(item:GetAttribute("itemName"))
-- end

local function isCollectableDetected(insert)
    if not insert:IsA("Model") then return false end
    local itemName = insert:GetAttribute("itemName")
    if itemName then
        return insert
    end

    for _, child in ipairs(insert:GetChildren()) do
        local childItemName = child:GetAttribute("itemName")
        if childItemName then
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

    -- Visuals
    local HorseEsp = Tabs.Visuals:AddToggle("Horse Esp", {
        Title = "Horse Esp",
        Default = false
    })

    local CollectablesEsp = Tabs.Visuals:AddToggle("Collectable Esp", {
        Title = "Collectable Esp",
        Default = false
    })

    local HorseEspColor = Tabs.Visuals:AddColorpicker("Horse Colorpicker", {
        Title = "Horse Esp Color",
        Default = Color3.fromRGB(255, 255, 0)
    })

    local CollectablesEspColor = Tabs.Visuals:AddColorpicker("Collectable Colorpicker", {
        Title = "Horse Esp Color",
        Default = Color3.fromRGB(0, 255, 0)
    })

    -- Toggle Detection
    HorseEsp:OnChanged(function()
        if HorseEsp.Value then
            for i, v in pairs(getList(false, "Animals")) do
                local breedLabel = v.OverheadPart:FindFirstChild("Overhead") and v.OverheadPart.Overhead:FindFirstChild("BreedLabel")
                local e = esp(v, breedLabel.Text,HorseEspColor.Value)
                table.insert(horseEspTable, e)
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
            for i, v in pairs(getList(false, "Collectables")) do
                local item = isCollectableDetected(v)
                local itemName = item:GetAttribute("itemName")
                local e = esp(item, itemName, CollectablesEspColor.Value)
                table.insert(collectablesEspTable, e)
            end
        else
            for i = #collectablesEspTable, 1, -1 do
                local v = collectablesEspTable[i]
                if v then
                    v:Destroy()
                    table.remove(collectablesEspTable, i)
                end
            end
        end
    end)

    HorseEspColor:OnChanged(function()
        for _, v in pairs(horseEspTable) do
            v:FindFirstChild("TextLabel").TextColor3 = HorseEspColor.Value
        end
    end)

    -- Spawn Detection
    Workspace.Islands.DescendantAdded:Connect(function(insert)
        task.wait(0.1)

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
        if isCollectableDetected(insert) then
            local item = isCollectableDetected(insert)
            local itemName = item:GetAttribute("itemName")

            -- ESP
            if CollectablesEsp.Value then
                local e = esp(item, itemName, CollectablesEspColor.Value)
                table.insert(collectablesEspTable, e)
            end
        end

    end)
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
