local Dump = {}

-- // Assert
Dump.Throw = function(condition, msg)
    return condition or error(msg)
end

-- // Compatibility Checks
getnilinstances = Dump.Throw(getnilinstances, 'Incompatible executor: missing getnilinstances')
getscriptbytecode = Dump.Throw(getscriptbytecode, 'Incompatible executor: missing getscriptbytecode')
decompile = Dump.Throw(decompile, 'Incompatible executor: missing decompile')
writefile = Dump.Throw(writefile, 'Incompatible executor: missing writefile')
makefolder = Dump.Throw(makefolder, 'Incompatible executor: missing makefolder')
isfolder = Dump.Throw(isfolder, 'Incompatible executor: missing isfolder')

-- // Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")

-- // LocalPlayer & Required
repeat task.wait() until Players.LocalPlayer 
    and StarterPlayer:FindFirstChild("StarterPlayerScripts") 
    and StarterPlayer:FindFirstChild("StarterCharacterScripts")

-- // Setup
local LocalPlayer = Players.LocalPlayer

local Start = os.time()
local Complete = false
local Success = 0
local Fail = 0

local Path: string = `{game.Name} ({game.PlaceId})`
if not isfolder(Path) then
    makefolder(Path)
end

-- // Locations
local Sources = {
    StarterPlayerScripts = {
        Enabled = true,
        Path = StarterPlayer:FindFirstChild("StarterPlayerScripts")
    },
    StarterCharacterScripts = {
        Enabled = true,
        Path = StarterPlayer:FindFirstChild("StarterCharacterScripts")
    },
    ReplicatedStorage = {
        Enabled = true,
        Path = ReplicatedStorage
    },
    ReplicatedFirst = {
        Enabled = true,
        Path = ReplicatedFirst
    },
    StarterGui = {
        Enabled = true,
        Path = StarterGui
    },
    Nil_Instances = {
        Enabled = true,
        Path = getnilinstances()
    }
}

-- // Functions
function Dump:Decompile(script)
    local success, result = pcall(function()
        local bytecode = getscriptbytecode(script)
        if bytecode and #bytecode > 0 then
            return decompile(script)
        end
        return nil
    end)

    return {
        Success = success,
        Output = result or "Unknown Bytecode"
    }
end

function Dump:Script(script, Base, RootInstance)
    local Result = self:Decompile(script)

    if Result.Success and Result.Output ~= "Unknown Bytecode" then
        Success += 1

        local RelativePath = ""
        local Current = script.Parent
        while Current and Current ~= RootInstance do
            RelativePath = Current.Name .. "/" .. RelativePath
            Current = Current.Parent
        end

        local FullFolder = Path .. "/" .. Base .. "/" .. RelativePath
        if not isfolder(FullFolder) then
            makefolder(FullFolder)
        end

        local FileName = script.Name .. ".lua"
        writefile(FullFolder .. "/" .. FileName, Result.Output)
    else
        Fail += 1
    end
end

function Dump:Service(Base, Path, RootInstance)
    for _, script in pairs(Path) do
        if script:IsA("LocalScript") or script:IsA("ModuleScript") then
            self:Script(script, Base, RootInstance)
        end
    end
end

-- // Begin Dumping
task.spawn(function()
    for category, data in pairs(Sources) do
        if data.Enabled then
            makefolder(Path .. "/" .. category)

            if typeof(data.Path) == "Instance" then
                Dump:Service(category, data.Path:GetDescendants(), data.Path)
            elseif typeof(data.Path) == "table" then
                Dump:Service(category, data.Path)
            end
        end
    end

    Complete = true
end)

-- // Wait 4 Completion
repeat task.wait() until Complete

-- // Final Logs
local Elapsed = os.time() - Start

warn(string.format("[Dump] Done in %ds | Folder: %s | Success: %d | Failed: %d", Elapsed, Path, Success, Fail))
