getgenv().Settings = {
    DisableRendering = true,
    AutoCollect = true,
    FarmMode = "VIP", -- VIP / Completion
    FarmRadius = 60
}

local Settings = getgenv().Settings

repeat task.wait(10) until game:IsLoaded()

local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

local tdrender = not Settings.DisableRendering
RunService:Set3dRenderingEnabled(tdrender)

local _ = require(RS:WaitForChild("Library", 10):WaitForChild("Client", 10))
repeat task.wait() until _.Loaded

local LocalPlayer = game:GetService("Players").LocalPlayer
local ZONES = debug.getupvalues(_.ZoneCmds.GetMaximumZone)[2].Zones

function GetPets()
    local pets = {}
    for id,_ in pairs(_.PetCmds.GetEquipped()) do
        table.insert(pets, id)
    end
    return pets
end

loadstring(game:HttpGet("https://raw.githubusercontent.com/Speemies/engine/main/engine2.lua"))()

LocalPlayer.PlayerScripts.Scripts.Core["Idle Tracking"].Enabled = false
for _,v in pairs(getconnections(LocalPlayer.Idled)) do
    if v["Disable"] then
        v["Disable"](v)
    elseif v["Disconnect"] then
        v["Disconnect"](v)
    end
end

if Settings.DisableRendering then
    local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
    local btn = Instance.new("TextButton", ScreenGui)

    btn.BackgroundColor3 = Color3.fromRGB(18, 21, 28)
    btn.BorderSizePixel = 0
    btn.Text = "3D Render"
    btn.TextColor3 = Color3.new(255, 255, 255)
    btn.TextScaled = true
    btn.Size = UDim2.new(0, 150, 0, 50)
    btn.Position = UDim2.new(0.3, 0, 0.3, 0)
    btn.MouseButton1Click:Connect(function()
        tdrender = not tdrender
        RunService:Set3dRenderingEnabled(tdrender)
    end)
end

if Settings.FarmMode:lower() == "vip" and _.Gamepasses.Owns(257811346) then
    local zone = ZONES["Spawn"].ZoneFolder.INTERACT:FindFirstChild("VIP", true)
    local char = LocalPlayer.Character
    coroutine.wrap(function()
        while task.wait(1) do
            if (char.HumanoidRootPart.Position - zone.Position).magnitude > 10 then
                char.HumanoidRootPart.CFrame = zone.CFrame
            end
        end
    end)()
end

if Settings.AutoCollect then
    coroutine.wrap(function()
        while task.wait(.1) do
            local orbs = {}
            for _,v in pairs(workspace["__THINGS"].Orbs:GetChildren()) do
                table.insert(orbs, { v.Name })
            end
            pcall(_.Network.Fire, "Orbs_ClaimMultiple", orbs)

            local Claim = getsenv(LocalPlayer.PlayerScripts.Scripts.Game["Lootbags Frontend"]).Claim
            for i,v in pairs(debug.getupvalue(Claim, 1)) do
                if v.readyForCollection() then Claim(i) end
            end

            for i,v in pairs(LocalPlayer.PlayerGui._MISC.FreeGifts.Frame.ItemsFrame.Gifts:GetDescendants()) do
                if v.ClassName == "TextLabel" and v.Text == "Redeem!" then
                    _.Network.Invoke("Redeem Free Gift", tonumber(string.match(v.Parent.Name, "%d+")))
                end
            end
        end
    end)()
end

local rangeCircle = Instance.new("Part")
rangeCircle.Shape = Enum.PartType.Cylinder
rangeCircle.Material = Enum.Material.Plastic
rangeCircle.Orientation = Vector3.new(0, 0, 90)
rangeCircle.Anchored = true
rangeCircle.CanCollide = false
rangeCircle.Transparency = 0.6
rangeCircle.BrickColor = BrickColor.new("Bright blue")
rangeCircle.Parent = workspace

local pets = GetPets()
coroutine.wrap(function()
    while task.wait() do
        local plr_pos = LocalPlayer.Character.HumanoidRootPart.Position
        local radius = Settings.FarmRadius or 50

        rangeCircle.Size = Vector3.new(0.1, radius * 2, radius * 2)
        rangeCircle.Position = plr_pos - Vector3.new(0, 2, 0)

        for i,v in pairs(workspace["__THINGS"].Breakables:GetChildren()) do
            if v:IsA("Model") then
                local hitbox = v:FindFirstChild("Hitbox", true)
                if not hitbox then continue end

                if (plr_pos - hitbox.Position).magnitude < radius then
                    if #pets == 0 then pets = GetPets() end
                    local pet = pets[1]
                    table.remove(pets, 1)

                    task.spawn(_.Network.Fire, "Breakables_JoinPet", v.Name, pet)
                    task.spawn(_.Network.Fire, "Breakables_PlayerDealDamage", v.Name)
                    task.wait(.1)
                end
            end
        end
    end
end)()

if Settings.FarmMode:lower() == "completion" then
    while task.wait(1) do
        LocalPlayer.Character.HumanoidRootPart.CFrame = _.ZoneCmds.GetMaximumZone().ZoneFolder.INTERACT.BREAKABLE_SPAWNS:FindFirstChildOfClass("Part").CFrame

        local bought = _.Network.Invoke("Zones_RequestPurchase", _.ZoneCmds.GetNextZone())
        if not bought then task.wait(30) end
    end
end
