local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
getgenv().config = {
    enable = true,
    delay  = 0,
    minCooldown = 0,
}

getgenv().is_firing = false
local Orginal = {}
local utility = {}

function utility.get_gun()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, tool in next, char:GetChildren() do
        if tool:IsA("Tool") and tool:FindFirstChild("Ammo") then
            return tool
        end
    end
    return nil
end

function utility.has_ammo(tool)
    if not tool then return false end
    local ammo = tool:FindFirstChild("Ammo")
    if not ammo then return true end
    if typeof(ammo.Value) == "number" then
        return ammo.Value > 0
    end
    return true
end

function utility.rapid(tool)
    if not tool or not tool:IsA("Tool") then return end
    if not utility.has_ammo(tool) then return end
    local ok, err = pcall(function()
        tool:Activate()
    end)
end

UserInputService.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if not config.enable then return end

    local gun = utility.get_gun()
    if not gun then return end
    if is_firing then return end

    is_firing = true
    task.spawn(function()
        while is_firing do
            local g = utility.get_gun()
            if not g then break end
            utility.rapid(g)
            task.wait(config.delay)
        end
        is_firing = false
    end)
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        is_firing = false
    end
end)

RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    if not tool:FindFirstChild("GunScript") then return end

    local ok, conns = pcall(getconnections, tool.Activated)
    if not ok or not conns then return end

    for _, connection in ipairs(conns) do
        local func = connection.Function
        if func then
            local info = debug.getinfo(func)
            if info then
                for i = 1, info.nups do
                    local c = debug.getupvalue(func, i)
                    if type(c) == "number" and c > 0 and c < 5 then
                        Orginal[func] = Orginal[func] or {}
                        if not Orginal[func][i] then
                            Orginal[func][i] = c
                        end
                        debug.setupvalue(func, i, config.minCooldown)
                    end
                end
            end
        end
    end
end)

local function restore_all()
    for func, tbl in pairs(Orginal) do
        if type(func) == "function" then
            for i, orig in pairs(tbl) do
                pcall(debug.setupvalue, func, i, orig)
            end
        end
    end
    Orginal = {}
end

LocalPlayer.CharacterAdded:Connect(function()
    is_firing = false
    restore_all()
end)
