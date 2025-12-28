if not game:IsLoaded() then
    game.Loaded:Wait()
end

local placeId = game.PlaceId
if placeId ~= 84988808589910 and placeId ~= 96105075537655 then 
    return 
end

local function getOrdinalSuffix(day)
    day = tonumber(day)
    if day >= 11 and day <= 13 then return "th" end
    local lastDigit = day % 10
    if lastDigit == 1 then return "st"
    elseif lastDigit == 2 then return "nd"
    elseif lastDigit == 3 then return "rd"
    else return "th" end
end

local day, month, year = os.date("%d"), os.date("%B"), os.date("%Y")
local date = day .. getOrdinalSuffix(day) .. ", " .. month .. ", " .. year

local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/12wrfw/test/refs/heads/main/L.lua'))()
local SaveManager = loadstring(game:HttpGet('https://raw.githubusercontent.com/12wrfw/test/refs/heads/main/Sa'))()
local ThemeManager = loadstring(game:HttpGet('https://raw.githubusercontent.com/BigHacker123/Library.lua/main/Theme.lua'))()

local Window = Library:CreateWindow({ Title = 'Vial | ' .. date, Center = true, AutoShow = true })
local Tabs = { Main = Window:AddTab('Main'), ['UI Settings'] = Window:AddTab('UI Settings') }
local MainGroup = Tabs.Main:AddLeftGroupbox('Main')
local MiscGroup = Tabs.Main:AddRightGroupbox('Miscellaneous')

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local VIM = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CooldownModule = require(ReplicatedStorage.Modules.Cooldown)

local instaKillRunning, autoSwingRunning, moneyFarmRunning, bossFarmRunning, gemFarmRunning = false, false, false, false, false
local autoMiscRunning, autoSkillRunning, hakiRunning, spoofNameRunning = false, false, false, false
local autoDungeonRunning, autoMaxLevelRunning = false, false
local selectedSkills = {}
local lastEquippedWeapon = nil

local bossStartTime, currentBoss, lastBossName, usedInstaOnBoss = 0, nil, "", false

local function virtualClick(btn)
    if not btn or not btn:IsA("GuiObject") then return end
    local x, y = btn.AbsolutePosition.X + (btn.AbsoluteSize.X / 2), btn.AbsolutePosition.Y + (btn.AbsoluteSize.Y / 2) + 58
    VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
    task.wait(0.1)
    VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
end

local function cancelCurrentQuest()
    pcall(function()
        local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
        local questFrame = hud and hud.Bar.List.Quest
        local cancelBtn = questFrame and questFrame.Bar.Cancel.Button
        if cancelBtn and cancelBtn.Visible then
            virtualClick(cancelBtn)
            task.wait(0.5)
        end
    end)
end

local function isTargetAlive(model)
    if not model or not model.Parent then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    local hrp = model:FindFirstChild("HumanoidRootPart")
    return hum and hum.Health > 0 and hrp
end

local function getTargetBoss()
    if isTargetAlive(currentBoss) then return currentBoss, currentBoss.HumanoidRootPart, currentBoss:FindFirstChildOfClass("Humanoid") end
    local charFolder = workspace:FindFirstChild("Main") and workspace.Main:FindFirstChild("Characters")
    if charFolder then
        for _, areaFolder in pairs(charFolder:GetChildren()) do
            local bossContainer = areaFolder:FindFirstChild("Boss")
            if bossContainer then
                for _, bossModel in pairs(bossContainer:GetChildren()) do
                    if bossModel:IsA("Model") and isTargetAlive(bossModel) then
                        currentBoss = bossModel
                        return bossModel, bossModel.HumanoidRootPart, bossModel:FindFirstChildOfClass("Humanoid")
                    end
                end
            end
        end
    end
    currentBoss = nil
    return nil
end

local function isEnemyNearby()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    for _, model in pairs(workspace.Main.Characters:GetDescendants()) do
        if model:IsA("Model") and model ~= char and not Players:GetPlayerFromCharacter(model) then
            local eHrp, eHum = model:FindFirstChild("HumanoidRootPart"), model:FindFirstChildOfClass("Humanoid")
            if eHrp and eHum and eHum.Health > 0 and (hrp.Position - eHrp.Position).Magnitude <= 45 then 
                return true 
            end
        end
    end
    return false
end

local function acceptQuest(npcId, questName)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local npcFolder = workspace:FindFirstChild("Main") and workspace.Main:FindFirstChild("NPCs") and workspace.Main.NPCs:FindFirstChild("Quests")
    local npc = npcFolder and npcFolder:FindFirstChild(tostring(npcId))
    
    if hrp and npc then
        local questData = LocalPlayer:FindFirstChild("Quest")
        local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
        local questFrame = hud and hud.Bar.List.Quest
        local questLabel = questFrame and questFrame.Bar.Label
        
        local currentQuestTitle = questData and questData:FindFirstChild("Title") and questData.Title.Value or ""
        local hudQuestVisible = questFrame and questFrame.Visible
        local hudQuestText = (hudQuestVisible and questLabel) and questLabel.Text or ""

        local hasAnyQuest = (hudQuestVisible and hudQuestText ~= "" and hudQuestText ~= " ")
        local isTargetQuest = hasAnyQuest and (hudQuestText:lower():find(questName:lower()) or currentQuestTitle:lower():find(questName:lower()))

        if hasAnyQuest and not isTargetQuest then
            cancelCurrentQuest()
            task.wait(0.5)
            hasAnyQuest = false
        end
        
        if not hasAnyQuest then
            hrp.CFrame = npc:GetPivot()
            task.wait(0.3)
            VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(math.random(20, 25) / 10)
            VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            
            local startTime = tick()
            while tick() - startTime < 3 do
                local dialog = LocalPlayer.PlayerGui:FindFirstChild("Dialogue")
                if dialog and dialog.Enabled then
                    local acceptBtn = dialog:FindFirstChild("Accept", true) or dialog:FindFirstChild("Yes", true)
                    if acceptBtn then 
                        virtualClick(acceptBtn)
                        task.wait(0.5)
                        break
                    end
                end
                task.wait(0.2)
            end
            task.wait(1)
        end
    end
end

local function equipLastWeapon()
    pcall(function()
        if lastEquippedWeapon and LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild(lastEquippedWeapon) then
            local tool = LocalPlayer.Backpack:FindFirstChild(lastEquippedWeapon)
            if tool then
                LocalPlayer.Character.Humanoid:EquipTool(tool)
            end
        end
    end)
end

local function doMoneyFarmLogic()
    local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
    local questFrame = hud and hud.Bar.List.Quest
    local questLabel = questFrame and questFrame.Bar.Label
    
    local hudQuestVisible = questFrame and questFrame.Visible
    local hudQuestText = (hudQuestVisible and questLabel) and questLabel.Text or ""
    
    local hasQuest = (hudQuestVisible and hudQuestText:lower():find("sorcerer's student"))

    if not hasQuest then
        acceptQuest(9, "Sorcerer's Student")
    else
        local mobPath = workspace.Main.Characters:FindFirstChild("Jujutsu Highschool") and workspace.Main.Characters["Jujutsu Highschool"]:FindFirstChild("Sorcerer's Student")
        local targetMob = nil
        if mobPath then 
            for _, mob in pairs(mobPath:GetChildren()) do 
                if isTargetAlive(mob) then 
                    targetMob = mob.HumanoidRootPart 
                    break 
                end 
            end 
        end
        if targetMob then 
            LocalPlayer.Character.HumanoidRootPart.CFrame = targetMob.CFrame * CFrame.new(0, 0, 3) 
        else 
            local npcFolder = workspace.Main.NPCs.Quests:FindFirstChild("9")
            if npcFolder then
                LocalPlayer.Character.HumanoidRootPart.CFrame = npcFolder:GetPivot()
            end
        end
    end
end

if placeId == 84988808589910 then
    MainGroup:AddToggle('AutoMaxLevel', { Text = 'Auto Max Level', Default = false, callback = function(v)
        autoMaxLevelRunning = v
        if v then 
            if moneyFarmRunning then Toggles.MoneyFarm:SetValue(false) end
            task.spawn(function()
                while autoMaxLevelRunning do
                    pcall(function()
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0 then
                            equipLastWeapon()
                            local playerLevel = LocalPlayer:FindFirstChild("Info") and LocalPlayer.Info:FindFirstChild("Level") and LocalPlayer.Info.Level.Value or 0
                            local questData = {
                                {max = 100, npc = "1", qName = "Bandit", mob = "Bandit"},
                                {max = 200, npc = "2", qName = "Bandit Leader", mob = "Bandit Leader"},
                                {max = 300, npc = "3", qName = "Skeleton", mob = "Skeleton"},
                                {max = 450, npc = "4", qName = "Pirate Skeleton", mob = "Pirate Skeleton"},
                                {max = 600, npc = "5", qName = "Desert Thief", mob = "Desert Thief"},
                                {max = 750, npc = "6", qName = "Katana Master", mob = "Katana Master"},
                                {max = 1000, npc = "7", qName = "Mihawk", mob = "Mihawk"},
                                {max = 1500, npc = "8", qName = "Sukuna", mob = "Sukuna"},
                                {max = 2000, npc = "9", qName = "Sorcerer's Student", mob = "Sorcerer's Student"},
                                {max = 4001, npc = "10", qName = "Sorcerer's Teacher", mob = "Sorcerer's Teacher"}
                            }
                            
                            local target = questData[1]
                            for i, d in ipairs(questData) do
                                if playerLevel >= (questData[i-1] and questData[i-1].max or 0) then
                                    target = d
                                end
                            end

                            local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                            local qFrame = hud and hud.Bar.List.Quest
                            local hasQ = (qFrame and qFrame.Visible and qFrame.Bar.Label.Text:lower():find(target.qName:lower()))

                            if not hasQ then
                                acceptQuest(target.npc, target.qName)
                            else
                                local targetMob = nil
                                for _, m in pairs(workspace.Main.Characters:GetDescendants()) do
                                    if m:IsA("Model") and m.Name == target.mob and isTargetAlive(m) then
                                        targetMob = m.HumanoidRootPart
                                        break
                                    end
                                end
                                if targetMob then 
                                    LocalPlayer.Character.HumanoidRootPart.CFrame = targetMob.CFrame * CFrame.new(0, 0, 3) 
                                else
                                    local npcFolder = workspace.Main.NPCs.Quests:FindFirstChild(target.npc)
                                    if npcFolder then
                                        LocalPlayer.Character.HumanoidRootPart.CFrame = npcFolder:GetPivot()
                                    end
                                end
                            end
                        end
                    end)
                    task.wait()
                end
            end)
        end
    end})

    MainGroup:AddToggle('MoneyFarm', { Text = 'Money Farm', Default = false, callback = function(v)
        moneyFarmRunning = v
        if v then
            local pLevel = LocalPlayer:FindFirstChild("Info") and LocalPlayer.Info:FindFirstChild("Level") and LocalPlayer.Info.Level.Value or 0
            if pLevel < 2750 then Library:Notify("Requires Level 2750!", 3) Toggles.MoneyFarm:SetValue(false) return end
            if autoMaxLevelRunning then Toggles.AutoMaxLevel:SetValue(false) end
            task.spawn(function() while moneyFarmRunning do pcall(function() if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0 then equipLastWeapon() if not ((bossFarmRunning or gemFarmRunning) and getTargetBoss()) then doMoneyFarmLogic() end end end) task.wait() end end)
        end
    end})

    MainGroup:AddToggle('BossFarm', { Text = 'Boss Farm', Default = false, callback = function(v)
        bossFarmRunning = v
        if v then task.spawn(function()
            while bossFarmRunning do
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0 then
                    equipLastWeapon()
                    local boss, bHrp = getTargetBoss()
                    if boss then
                        if currentBoss ~= boss then currentBoss, lastBossName, bossStartTime, usedInstaOnBoss = boss, boss.Name, tick(), false end
                        LocalPlayer.Character.HumanoidRootPart.CFrame = bHrp.CFrame * CFrame.new(0, 0, 3)
                    elseif currentBoss then
                        Library:Notify(string.format("%s Killed In %s Seconds (%s)", lastBossName, tostring(math.floor((tick() - bossStartTime) * 10) / 10), usedInstaOnBoss and "Instant" or "Legit"), 5)
                        currentBoss = nil
                    end
                end
                task.wait()
            end
        end) end
    end})

    MainGroup:AddToggle('GemFarm', { Text = 'Gem Farm', Default = false, callback = function(v)
        gemFarmRunning = v
        if v then 
            task.spawn(function()
                while gemFarmRunning do
                    local success, err = pcall(function()
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0 then
                            equipLastWeapon()
                            local currencys = LocalPlayer:FindFirstChild("Currencys")
                            local gemsValue = currencys and currencys:FindFirstChild("Gems") and currencys.Gems.Value or 0
                            
                            if gemsValue >= 500 then
                                gemFarmRunning = false
                                Toggles.GemFarm:SetValue(false)
                                return
                            end
                            
                            local charactersFolder = workspace:FindFirstChild("Main") and workspace.Main:FindFirstChild("Characters")
                            local throneIsle = charactersFolder and charactersFolder:FindFirstChild("Throne Isle")
                            local throneBossContainer = throneIsle and throneIsle:FindFirstChild("Boss")
                            
                            local activeThroneBoss = nil
                            if throneBossContainer then
                                for _, b in pairs(throneBossContainer:GetChildren()) do
                                    if b:IsA("Model") and isTargetAlive(b) then
                                        activeThroneBoss = b
                                        break
                                    end
                                end
                            end
                            
                            if activeThroneBoss then
                                currentBoss = activeThroneBoss
                                LocalPlayer.Character.HumanoidRootPart.CFrame = activeThroneBoss.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                            else
                                local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                                local buttonGui = playerGui and playerGui:FindFirstChild("Button")
                                local storageFrame = buttonGui and buttonGui:FindFirstChild("Storage_Frame")
                                local matFrame = storageFrame and storageFrame:FindFirstChild("Material_Frame")
                                local summonOrb = matFrame and matFrame:FindFirstChild("Summon Orb")
                                
                                local hasOrb = false
                                if summonOrb and summonOrb:FindFirstChild("Quantity") then
                                    local qty = tonumber(summonOrb.Quantity.Text:gsub("%D", "")) or 0
                                    if qty > 0 then hasOrb = true end
                                end

                                if not hasOrb then
                                    local moneyValue = currencys and currencys:FindFirstChild("Money") and currencys.Money.Value or 0
                                    if moneyValue < 42500 then
                                        doMoneyFarmLogic()
                                    else
                                        local hud = playerGui:FindFirstChild("HUD")
                                        local shopBtn = hud and hud:FindFirstChild("Main") and hud.Main:FindFirstChild("Shop")
                                        if shopBtn then virtualClick(shopBtn) task.wait(0.5) end
                                        
                                        local shopItemUI = buttonGui:FindFirstChild("Shop Item")
                                        if shopItemUI then
                                            shopItemUI.Visible = true
                                            task.wait(0.3)
                                            local moneyCategory = shopItemUI:FindFirstChild("Money")
                                            local orbFrame = moneyCategory and moneyCategory:FindFirstChild("Summon Orb")
                                            local buyBtn = orbFrame and orbFrame:FindFirstChild("Buy") and orbFrame.Buy:FindFirstChild("Button")
                                            if buyBtn then virtualClick(buyBtn) task.wait(0.5) end
                                            shopItemUI.Visible = false
                                        end
                                    end
                                else
                                    local hud = playerGui:FindFirstChild("HUD")
                                    local bossSpawnMainBtn = hud and hud:FindFirstChild("Main") and (hud.Main:FindFirstChild("Boss Spawn") or hud.Main:FindFirstChild("Boss"))
                                    if bossSpawnMainBtn then virtualClick(bossSpawnMainBtn) task.wait(0.5) end

                                    local bossSpawnUI = buttonGui:FindFirstChild("Boss Spawn")
                                    if bossSpawnUI then
                                        bossSpawnUI.Visible = true
                                        task.wait(0.4)
                                        local frame = bossSpawnUI:FindFirstChild("Frame")
                                        local akazaBtn = frame and frame:FindFirstChild("Akaza") and frame.Akaza:FindFirstChild("Button")
                                        local finalSpawnBtn = bossSpawnUI:FindFirstChild("Spawn") and bossSpawnUI.Spawn:FindFirstChild("Button")
                                        
                                        if akazaBtn then virtualClick(akazaBtn) task.wait(0.3) end
                                        if finalSpawnBtn then virtualClick(finalSpawnBtn) task.wait(0.5) end
                                        bossSpawnUI.Visible = false
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(0.2)
                end
            end) 
        end
    end})
elseif placeId == 96105075537655 then
    MainGroup:AddToggle('AutoDungeon', { Text = 'Auto Dungeon', Default = false, callback = function(v)
        autoDungeonRunning = v
        if v then task.spawn(function()
            while autoDungeonRunning do
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0 then
                    equipLastWeapon()
                    local dgGui = LocalPlayer.PlayerGui:FindFirstChild("Dungeon")
                    if dgGui then
                        if dgGui.Start.Visible then virtualClick(dgGui.Start) end
                        if dgGui.Restart.Visible then virtualClick(dgGui.Restart) end
                    end
                    local colosseum = workspace.Main.Characters:FindFirstChild("Colosseum")
                    if colosseum then
                        for _, enemy in pairs(colosseum:GetDescendants()) do
                            if enemy:IsA("Model") and isTargetAlive(enemy) and enemy.Name ~= LocalPlayer.Name then
                                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(enemy.HumanoidRootPart.Position + Vector3.new(0, 10, 0), enemy.HumanoidRootPart.Position)
                                break
                            end
                        end
                    end
                end
                task.wait()
            end
        end) end
    end})
end

MiscGroup:AddToggle('AutoSwing', { Text = 'Auto Swing', Default = false, callback = function(v)
    autoSwingRunning = v
    if v then task.spawn(function()
        while autoSwingRunning do
            pcall(function()
                if isEnemyNearby() then
                    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                    if tool then lastEquippedWeapon = tool.Name end
                    local typeToUse, nameToUse = "Combat", "Combat"
                    if tool and CooldownModule[tool.Name] then typeToUse, nameToUse = CooldownModule[tool.Name].Type, tool.Name end
                    ReplicatedStorage.Remotes.Serverside:FireServer("Server", typeToUse, "M1s", nameToUse, math.random(1, 4))
                end
            end)
            task.wait(0.1)
        end
    end) end
end})

MiscGroup:AddToggle('AutoMisc', { Text = 'Auto Haki / Observation', Default = false, callback = function(v)
    autoMiscRunning = v
    if v then task.spawn(function()
        while autoMiscRunning do
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0 then
                if not LocalPlayer.Character:FindFirstChild("Haki") then ReplicatedStorage.Remotes.Serverside:FireServer("Server", "Misc", "Haki", 1) end
                local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                if hud and hud.Dodge.Visible == false then ReplicatedStorage.Remotes.Serverside:FireServer("Server", "Misc", "Observation", 1) end
            end
            task.wait(1.5)
        end
    end) end
end})

MiscGroup:AddToggle('MaxLevelHaki', { Text = 'Max Level Haki (Quick)', Default = false, callback = function(v)
    hakiRunning = v
    if v then task.spawn(function()
        while hakiRunning do
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0 then
                local hl = LocalPlayer.Technique:FindFirstChild("HakiLevel")
                if hl and hl.Value >= 10 then Toggles.MaxLevelHaki:SetValue(false) return end
                ReplicatedStorage.Remotes.Serverside:FireServer("Server", "Misc", "Haki", 2)
                ReplicatedStorage.Remotes.Serverside:FireServer("Server", "Misc", "Haki", 1)
            end
            task.wait(0.1)
        end
    end) end
end})

MiscGroup:AddToggle('SpoofName', { Text = 'Spoof Name', Default = false, callback = function(v)
    spoofNameRunning = v
    if v then task.spawn(function()
        while spoofNameRunning do
            pcall(function()
                local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                local status = hud and hud:FindFirstChild("Boss Bar") and hud["Boss Bar"].Health.Status.Player
                if status and status.Visible then for _, label in pairs(status:GetDescendants()) do if label:IsA("TextLabel") and (label.Text == LocalPlayer.Name or label.Name == LocalPlayer.Name) then label.Text = "Vial.pw" end end end
                local hudName = hud and hud.Main:FindFirstChild("Name")
                if hudName then hudName.Text = "Vial.pw" end
            end)
            task.wait()
        end
    end) end
end})

MiscGroup:AddDropdown('SkillSelector', { Values = { 'Z', 'X', 'C', 'V' }, Default = {}, Multi = true, Text = 'Select Skills', callback = function(value) selectedSkills = value end })

MiscGroup:AddToggle('AutoSkill', { Text = 'Auto Skill', Default = false, callback = function(v)
    autoSkillRunning = v
    if v then task.spawn(function()
        local skillMap, skillOrder = {Z = "Skill1", X = "Skill2", C = "Skill3", V = "Skill4"}, {Z = 1, X = 2, C = 3, V = 4}
        while autoSkillRunning do
            if isEnemyNearby() then
                local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if tool and CooldownModule[tool.Name] then 
                    lastEquippedWeapon = tool.Name
                    for key, enabled in next, selectedSkills do if enabled then ReplicatedStorage.Remotes.Serverside:FireServer("Server", CooldownModule[tool.Name].Type, skillMap[key], tool.Name, skillOrder[key]) end end 
                end
            end
            task.wait(0.1)
        end
    end) end
end})

MiscGroup:AddToggle('InstaKill', { Text = 'InstaKill', Default = false, callback = function(v)
    instaKillRunning = v
    if v then task.spawn(function()
        while instaKillRunning do
            pcall(function()
                for _, model in pairs(workspace.Main.Characters:GetDescendants()) do
                    if model:IsA("Model") and model ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(model) then
                        local hum, hrp = model:FindFirstChildOfClass("Humanoid"), model:FindFirstChild("HumanoidRootPart")
                        if hum and hum.Health > 0 and hrp and (hum.Health / hum.MaxHealth) * 100 <= 89 then
                            if isnetworkowner(hrp) then
                                if currentBoss and model == currentBoss then usedInstaOnBoss = true end
                                hum:ChangeState(Enum.HumanoidStateType.Dead)
                                hum.Health = 0
                            end
                        end
                    end
                end
            end)
            task.wait()
        end
    end) end
end})

Library:OnUnload(function() Library.Unloaded = true end)
local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu keybind' }) 

Library.ToggleKeybind = Options.MenuKeybind
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
ThemeManager:SetFolder('Vial')
SaveManager:SetFolder('Vial/BrainRotSeas')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])