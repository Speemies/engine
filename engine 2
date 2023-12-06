local RS = game:GetService("ReplicatedStorage")
local _ = require(RS:WaitForChild("Library", 10):WaitForChild("Client", 10))
repeat task.wait() until _.Loaded

if not getgenv().patched then
    getgenv().patched = true

    local Blunder = require(RS:FindFirstChild("BlunderList", true))
    local OldGet = Blunder.getAndClear

    setreadonly(Blunder, false)
    Blunder.getAndClear = function(...)
        local Packet = ...
        for i,v in next, Packet.list do
            if v.message ~= "PING" then
                table.remove(Packet.list, i)
            end
        end
        return OldGet(Packet)
    end

    local Audio = require(RS:WaitForChild("Library", 10):WaitForChild("Audio", 10))
    hookfunction(Audio.Play, function(...)
        return {
            Play = function() end,
            Stop = function() end,
            IsPlaying = function() return false end
        }
    end)
end
