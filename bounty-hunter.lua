-- Script Tự Săn Bounty Blox Fruits - Bản Hoàn Chỉnh
getgenv().BountyConfig = {
    Setup = {
        ['PC-er'] = false,
        ['Team'] = 'Pirates',
        ['Auto Team'] = {
            ['Enabled'] = false,
            ['Lock'] = {
                ['Pirate'] = {0, 30000000},
                ['Marines'] = {0, 30000000}
            }
        },
        ['Panic % Health'] = {40, 45},
        ['Chatting'] = {'Go to use Rua Hub Now!', 'Free auto bounty for PC!', '1.5 Million Bounty Per hour!'},
        ['Lock Cam'] = false,
        ['Hop Region'] = 'Singapore',
        ['Random Y Tween'] = false,
        ['Click Delay'] = 0.18
    },
    Hunter = {
        ['Ignore'] = {
            ['Fruit'] = {
                'Portal-Portal',
                'Kitsune-Kitsune',
                'Meme-Meme'
            },
            ['Timer'] = 60,
            ['V4'] = true
        },
        ['Comeback On Sus Kill'] = true,
        ['Gun Mode'] = false,
        ['Predict Move'] = true,
        ['Hit And Run'] = true,
        ['Random Position'] = false
    },
    Booster = {
        ['Hide Gui'] = true,
        ['Showcase Mode'] = false,
        ['White Screen'] = false,
        ['Hide Map'] = false
    },
    Skills = {
        ['Melee'] = {
            ['Enabled'] = {true, true},
            ['Z'] = {true, 1.5, 0},
            ['X'] = {true, 0, 0},
            ['C'] = {true, 0, 0}
        },
        ['Blox Fruit'] = {
            ['Enabled'] = {false, false},
            ['Z'] = {true, 0, 0},
            ['X'] = {true, 0, 0},
            ['C'] = {true, 0, 0},
            ['V'] = {false, 0, 0},
            ['F'] = {true, 0, 0}
        },
        ['Sword'] = {
            ['Enabled'] = {false, false},
            ['Z'] = {true, 0.5, 0},
            ['X'] = {true, 0, 0},
        },
        ['Gun'] = {
            ['Enabled'] = {true, true},
            ['Z'] = {true, 0, 0},
            ['X'] = {true, 0, 0},
        }
    },
    Macro = {
        ['Enabled'] = true,
        ['Skills'] = {
            [1] = {'Melee', {'Z'}},
            [2] = {'Gun', {'Z'}},
            [3] = {'Melee', {'C'}},
            [4] = {'Gun', {'X'}},
            [5] = {'Melee', {'X'}}
        }
    },
    Counter = {
        ['Enabled'] = true,
        ['Webhook'] = {
            ['Enabled'] = false,
            ['Url'] = ''
        },
        ['Theme'] = {
            ['Character'] = 'Yae',
            ['Custom'] = {
                ['Enabled'] = false,
                ['Config'] = {}
            }
        }
    }
}

local cfg = getgenv().BountyConfig
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local httpService = game:GetService("HttpService")
local localPlayer = players.LocalPlayer
local virtualInput = game:GetService("VirtualInputManager")
local workspace = game:GetService("Workspace")

local function getTeam(player)
    if player:FindFirstChild("Team") then
        return player.Team.Value
    end
    return nil
end

local function getBounty(player)
    local ls = player:FindFirstChild("leaderstats")
    if ls and ls:FindFirstChild("Bounty") then
        return ls.Bounty.Value
    end
    return 0
end

local function getHealth(player)
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        return player.Character.Humanoid.Health, player.Character.Humanoid.MaxHealth
    end
    return 0, 0
end

local function getFruitName(player)
    if player.Character then
        local fruit = player.Character:FindFirstChild("Fruit")
        if fruit and fruit:FindFirstChild("Name") then
            return fruit.Name.Value
        end
    end
    return ""
end

local function isV4(player)
    if player.Character then
        local v4gear = player.Character:FindFirstChild("V4") or player.Character:FindFirstChild("GearV4")
        if v4gear then return true end
    end
    return false
end

local function isVulnerable(player)
    local char = player.Character
    if not char then return false end
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid and humanoid.Health <= 0 then return false end
    return true
end

local chatMessages = cfg.Setup.Chatting
local lastChatTime = 0
local function autoChat()
    if #chatMessages == 0 then return end
    if tick() - lastChatTime > 30 then
        local msg = chatMessages[math.random(#chatMessages)]
        pcall(function()
            game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
        end)
        lastChatTime = tick()
    end
end

local function autoTeam()
    if not cfg.Setup["Auto Team"].Enabled then return end
    local myTeam = getTeam(localPlayer)
    local myBounty = getBounty(localPlayer)
    local lock = cfg.Setup["Auto Team"].Lock
    local desiredTeam = nil
    if myTeam == "Pirates" then
        if myBounty < lock.Pirate[1] or myBounty > lock.Pirate[2] then
            desiredTeam = "Marines"
        end
    elseif myTeam == "Marines" then
        if myBounty < lock.Marines[1] or myBounty > lock.Marines[2] then
            desiredTeam = "Pirates"
        end
    else
        desiredTeam = cfg.Setup.Team
    end

    if desiredTeam then
        local args = {[1] = "SetTeam", [2] = desiredTeam}
        pcall(function()
            game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer(unpack(args))
        end)
    end
end

local function checkPanic()
    local currentHealth, maxHealth = getHealth(localPlayer)
    if maxHealth == 0 then return false end
    local percent = currentHealth / maxHealth * 100
    local low, high = cfg.Setup["Panic % Health"][1], cfg.Setup["Panic % Health"][2]
    return (percent >= low and percent <= high)
end

local function getNearestEnemy()
    local nearest = nil
    local minDist = math.huge
    local myTeam = getTeam(localPlayer)
    local myChar = localPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = myChar.HumanoidRootPart.Position

    for _, player in ipairs(players:GetPlayers()) do
        if player ~= localPlayer then
            local team = getTeam(player)
            if team and team ~= myTeam then
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") and isVulnerable(player) then
                    local pos = char.HumanoidRootPart.Position
                    local dist = (pos - myPos).Magnitude
                    local fruit = getFruitName(player)
                    local ignoredFruits = cfg.Hunter.Ignore.Fruit
                    local ignoreFruit = false
                    for _, f in ipairs(ignoredFruits) do
                        if fruit:lower() == f:lower() then
                            ignoreFruit = true
                            break
                        end
                    end
                    local ignoreTimer = (os.time() - (player.LastHitTime or 0)) < cfg.Hunter.Ignore.Timer
                    local ignoreV4 = cfg.Hunter.Ignore.V4 and isV4(player)

                    if not ignoreFruit and not ignoreTimer and not ignoreV4 then
                        if dist < minDist then
                            minDist = dist
                            nearest = player
                        end
                    end
                end
            end
        end
    end
    return nearest
end

local lastSkillTime = 0
local lastSkillIndex = 0
local function executeSkills(target)
    if not cfg.Macro.Enabled then return end
    if tick() - lastSkillTime < cfg.Setup["Click Delay"] then return end

    local macro = cfg.Macro.Skills
    local skillIndex = lastSkillIndex + 1
    if skillIndex > #macro then skillIndex = 1 end
    lastSkillIndex = skillIndex
    local skillData = macro[skillIndex]
    local category, keys = skillData[1], skillData[2]

    local skillCfg = cfg.Skills[category]
    if not skillCfg or not skillCfg.Enabled[1] then return end

    for _, key in ipairs(keys) do
        local keyCfg = skillCfg[key]
        if keyCfg and keyCfg[1] then
            pcall(function()
                virtualInput:SendKeyEvent(true, key, false, game)
                task.wait(keyCfg[2] or 0)
                virtualInput:SendKeyEvent(false, key, false, game)
            end)
            task.wait(cfg.Setup["Click Delay"])
        end
    end
    lastSkillTime = tick()
end

local function hitAndRun(target)
    if not cfg.Hunter["Hit And Run"] then return end
    local myChar = localPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
    local targetPos = target.Character and target.Character:FindFirstChild("HumanoidRootPart") and target.Character.HumanoidRootPart.Position
    if not targetPos then return end
    local runDir = (myChar.HumanoidRootPart.Position - targetPos).Unit * 50 + Vector3.new(math.random(-20,20), 0, math.random(-20,20))
    local newPos = myChar.HumanoidRootPart.Position + runDir
    pcall(function()
        myChar.HumanoidRootPart.CFrame = CFrame.new(newPos)
    end)
end

local lastTarget = nil
local function checkComeback()
    if not cfg.Hunter["Comeback On Sus Kill"] then return end
    if localPlayer.Character == nil or (localPlayer.Character:FindFirstChild("Humanoid") and localPlayer.Character.Humanoid.Health <= 0) then
        if lastTarget then
            repeat task.wait(1) until localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") and localPlayer.Character.Humanoid.Health > 0
            if lastTarget.Character and lastTarget.Character:FindFirstChild("HumanoidRootPart") then
                pcall(function()
                    localPlayer.Character.HumanoidRootPart.CFrame = lastTarget.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,-5)
                end)
            end
        end
    end
end

local function mainLoop()
    if checkPanic() then
        local myChar = localPlayer.Character
        if myChar and myChar:FindFirstChild("HumanoidRootPart") then
            local randPos = myChar.HumanoidRootPart.Position + Vector3.new(math.random(-100,100), 0, math.random(-100,100))
            pcall(function()
                myChar.HumanoidRootPart.CFrame = CFrame.new(randPos)
            end)
        end
        return
    end

    autoTeam()
    autoChat()

    local target = getNearestEnemy()
    if target then
        lastTarget = target
        if cfg.Hunter["Predict Move"] then
            local targetChar = target.Character
            if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                local targetVel = targetChar.HumanoidRootPart.Velocity
                local predictedPos = targetChar.HumanoidRootPart.Position + targetVel * 0.5
                pcall(function()
                    localPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(predictedPos)
                end)
            end
        end
        executeSkills(target)
        hitAndRun(target)
    else
        if cfg.Hunter["Random Position"] then
            local myChar = localPlayer.Character
            if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                local randPos = Vector3.new(math.random(-500,500), 0, math.random(-500,500))
                pcall(function()
                    myChar.HumanoidRootPart.CFrame = CFrame.new(randPos)
                end)
            end
        end
    end
    checkComeback()
end

if cfg.Booster["Hide Gui"] then
end
if cfg.Booster["Hide Map"] then
    pcall(function()
        local map = workspace:FindFirstChild("Map")
        if map then
            for _, v in ipairs(map:GetDescendants()) do
                if v:IsA("BasePart") then v.Transparency = 1 end
            end
        end
    end)
end
if cfg.Booster["White Screen"] then
end

runService.Heartbeat:Connect(function()
    pcall(mainLoop)
end)
