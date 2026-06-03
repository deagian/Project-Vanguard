-- EnemyAI gestisce rilevamento, movimento e attacco base dei bot.
-- Il danno al player viene applicato solo dal server.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local EnemyAI = {}

local LOST_SIGHT_MEMORY_TIME = 3
local ENEMY_GUN_SOUND_ID = "rbxassetid://9119561046"
local ATTACK_LOG_COOLDOWN = 6

local function getAliveCharacterParts(player)
	local character = player.Character
	if not character then
		return nil, nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart or humanoid.Health <= 0 then
		return nil, nil
	end

	return character, humanoid, rootPart
end

local function getNearestPlayer(enemyRootPart, detectionRange)
	local nearestPlayer = nil
	local nearestCharacter = nil
	local nearestHumanoid = nil
	local nearestRootPart = nil
	local nearestDistance = detectionRange

	for _, player in ipairs(Players:GetPlayers()) do
		local character, humanoid, rootPart = getAliveCharacterParts(player)
		if humanoid and rootPart then
			local distance = (rootPart.Position - enemyRootPart.Position).Magnitude
			if distance <= nearestDistance then
				nearestPlayer = player
				nearestCharacter = character
				nearestHumanoid = humanoid
				nearestRootPart = rootPart
				nearestDistance = distance
			end
		end
	end

	return nearestPlayer, nearestCharacter, nearestHumanoid, nearestRootPart, nearestDistance
end

local function faceTarget(enemyRootPart, targetPosition)
	local enemyPosition = enemyRootPart.Position
	local flatTarget = Vector3.new(targetPosition.X, enemyPosition.Y, targetPosition.Z)
	local direction = flatTarget - enemyPosition

	if direction.Magnitude <= 0.01 then
		return
	end

	enemyRootPart.CFrame = CFrame.lookAt(enemyPosition, enemyPosition + direction.Unit)
end

local function getPatrolPoint(homePosition, radius)
	local angle = math.random() * math.pi * 2
	local distance = math.random() * radius
	local offset = Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)

	return homePosition + offset
end

local function getAimPart(model)
	return model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
end

local function hasLineOfSight(enemyModel, enemyRootPart, targetCharacter)
	local enemyAimPart = getAimPart(enemyModel) or enemyRootPart
	local targetAimPart = getAimPart(targetCharacter)
	if not targetAimPart then
		return false
	end

	local origin = enemyAimPart.Position
	local targetPosition = targetAimPart.Position
	local direction = targetPosition - origin
	if direction.Magnitude <= 0 then
		return false
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { enemyModel }
	raycastParams.IgnoreWater = true

	local result = workspace:Raycast(origin, direction, raycastParams)
	if result and result.Instance:IsDescendantOf(targetCharacter) then
		return true
	end

	return false
end

local function getMuzzlePosition(enemyModel, enemyRootPart)
	local attachment = enemyModel:FindFirstChild("EnemyMuzzleAttachment", true)
	if attachment and attachment:IsA("Attachment") then
		return attachment.WorldPosition
	end

	local rifle = enemyModel:FindFirstChild("EnemyRifle", true)
	if rifle and rifle:IsA("BasePart") then
		return rifle.Position + rifle.CFrame.LookVector * (rifle.Size.Z * 0.5)
	end

	return enemyRootPart.Position
end

local function playMuzzleFlash(enemyModel, enemyRootPart)
	local muzzlePosition = getMuzzlePosition(enemyModel, enemyRootPart)

	local flash = Instance.new("Part")
	flash.Name = "EnemyMuzzleFlash"
	flash.Shape = Enum.PartType.Ball
	flash.Size = Vector3.new(0.35, 0.35, 0.35)
	flash.Material = Enum.Material.Neon
	flash.Color = Color3.fromRGB(255, 190, 60)
	flash.Anchored = true
	flash.CanCollide = false
	flash.CanQuery = false
	flash.CanTouch = false
	flash.CFrame = CFrame.new(muzzlePosition)
	flash.Parent = workspace

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 185, 75)
	light.Brightness = 4
	light.Range = 8
	light.Parent = flash

	Debris:AddItem(flash, 0.08)
end

local function playGunSound(enemyModel, enemyRootPart)
	local soundParent = enemyModel:FindFirstChild("EnemyRifle", true) or enemyRootPart

	local sound = Instance.new("Sound")
	sound.Name = "EnemyGunshot"
	sound.SoundId = ENEMY_GUN_SOUND_ID
	sound.Volume = 0.28
	sound.RollOffMaxDistance = 85
	sound.RollOffMinDistance = 8
	sound.Parent = soundParent
	sound:Play()

	Debris:AddItem(sound, 2)
end

local function playTracer(enemyModel, enemyRootPart, targetPosition)
	local muzzlePosition = getMuzzlePosition(enemyModel, enemyRootPart)
	local direction = targetPosition - muzzlePosition
	if direction.Magnitude <= 0 then
		return
	end

	local tracer = Instance.new("Part")
	tracer.Name = "EnemyBulletTracer"
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.CanQuery = false
	tracer.CanTouch = false
	tracer.Material = Enum.Material.Neon
	tracer.Color = Color3.fromRGB(255, 140, 45)
	tracer.Size = Vector3.new(0.12, 0.12, direction.Magnitude)
	tracer.CFrame = CFrame.lookAt(muzzlePosition + direction * 0.5, targetPosition)
	tracer.Parent = workspace

	Debris:AddItem(tracer, 0.08)
end

local function playHitReaction(enemyModel)
	local originalStates = {}

	for _, descendant in ipairs(enemyModel:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
			originalStates[descendant] = {
				Color = descendant.Color,
				Material = descendant.Material,
			}
			descendant.Color = Color3.fromRGB(255, 45, 45)
			descendant.Material = Enum.Material.Neon
		end
	end

	task.delay(0.08, function()
		for part, state in pairs(originalStates) do
			if part.Parent then
				part.Color = state.Color
				part.Material = state.Material
			end
		end
	end)
end

function EnemyAI.Start(enemyModel, config, homePosition)
	local humanoid = enemyModel:FindFirstChildOfClass("Humanoid")
	local rootPart = enemyModel:FindFirstChild("HumanoidRootPart")

	if not humanoid or not rootPart then
		warn("[EnemyAI] Enemy missing Humanoid or HumanoidRootPart")
		return
	end

	local alive = true
	local currentTarget = nil
	local lastAttackTime = 0
	local lastPatrolTime = 0
	local lastKnownPlayerPosition = nil
	local lastSeenTime = 0
	local lastHealth = humanoid.Health
	local lastAttackLogTime = 0

	humanoid.WalkSpeed = config.WalkSpeed

	humanoid.HealthChanged:Connect(function(newHealth)
		if newHealth < lastHealth and newHealth > 0 then
			playHitReaction(enemyModel)
		end

		lastHealth = newHealth
	end)

	humanoid.Died:Connect(function()
		alive = false
		print("[EnemyAI] Enemy died")
	end)

	task.spawn(function()
		while alive and enemyModel.Parent do
			local targetPlayer, targetCharacter, targetHumanoid, targetRootPart, distance =
				getNearestPlayer(rootPart, config.DetectionRange)

			if targetPlayer and targetCharacter and targetHumanoid and targetRootPart then
				if currentTarget ~= targetPlayer then
					currentTarget = targetPlayer
					print("[EnemyAI] Enemy detected player")
				end

				faceTarget(rootPart, targetRootPart.Position)
				local hasLOS = hasLineOfSight(enemyModel, rootPart, targetCharacter)
				if hasLOS then
					lastKnownPlayerPosition = targetRootPart.Position
					lastSeenTime = os.clock()
				end

				local now = os.clock()
				local hasRecentLastKnownPosition = lastKnownPlayerPosition ~= nil and now - lastSeenTime <= LOST_SIGHT_MEMORY_TIME

				if distance > config.AttackRange then
					if hasLOS or not lastKnownPlayerPosition then
						humanoid:MoveTo(targetRootPart.Position)
					elseif hasRecentLastKnownPosition then
						humanoid:MoveTo(lastKnownPlayerPosition)
					else
						lastKnownPlayerPosition = nil
						currentTarget = nil
					end
				elseif not hasLOS and hasRecentLastKnownPosition then
					humanoid:MoveTo(lastKnownPlayerPosition)
				else
					humanoid:MoveTo(rootPart.Position)

					if hasLOS and now - lastAttackTime >= config.FireCooldown then
						if targetHumanoid.Health > 0 and humanoid.Health > 0 then
							lastAttackTime = now
							local targetAimPart = getAimPart(targetCharacter) or targetRootPart
							playMuzzleFlash(enemyModel, rootPart)
							playGunSound(enemyModel, rootPart)
							playTracer(enemyModel, rootPart, targetAimPart.Position)
							targetHumanoid:TakeDamage(config.Damage)

							-- Log limitato per non riempire Output durante i test con piu' nemici.
							if now - lastAttackLogTime >= ATTACK_LOG_COOLDOWN then
								lastAttackLogTime = now
								print("[EnemyAI] Enemy attacking player")
								print("[EnemyAI] Player damaged amount=" .. tostring(config.Damage))
							end
						end
					end
				end
			else
				currentTarget = nil

				local now = os.clock()
				if lastKnownPlayerPosition and now - lastSeenTime <= LOST_SIGHT_MEMORY_TIME then
					humanoid:MoveTo(lastKnownPlayerPosition)
				elseif now - lastPatrolTime >= config.PatrolCooldown then
					lastKnownPlayerPosition = nil
					lastPatrolTime = now
					humanoid:MoveTo(getPatrolPoint(homePosition, config.PatrolRadius))
				end
			end

			task.wait(0.15)
		end
	end)
end

return EnemyAI
