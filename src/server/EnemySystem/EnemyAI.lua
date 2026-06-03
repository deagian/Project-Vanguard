-- EnemyAI gestisce rilevamento, movimento e attacco base dei bot.
-- Il danno al player viene applicato solo dal server.

local Players = game:GetService("Players")

local EnemyAI = {}

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

	return humanoid, rootPart
end

local function getNearestPlayer(enemyRootPart, detectionRange)
	local nearestPlayer = nil
	local nearestHumanoid = nil
	local nearestRootPart = nil
	local nearestDistance = detectionRange

	for _, player in ipairs(Players:GetPlayers()) do
		local humanoid, rootPart = getAliveCharacterParts(player)
		if humanoid and rootPart then
			local distance = (rootPart.Position - enemyRootPart.Position).Magnitude
			if distance <= nearestDistance then
				nearestPlayer = player
				nearestHumanoid = humanoid
				nearestRootPart = rootPart
				nearestDistance = distance
			end
		end
	end

	return nearestPlayer, nearestHumanoid, nearestRootPart, nearestDistance
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

	humanoid.WalkSpeed = config.WalkSpeed

	humanoid.Died:Connect(function()
		alive = false
		print("[EnemyAI] Enemy died")
	end)

	task.spawn(function()
		while alive and enemyModel.Parent do
			local targetPlayer, targetHumanoid, targetRootPart, distance = getNearestPlayer(rootPart, config.DetectionRange)

			if targetPlayer and targetHumanoid and targetRootPart then
				if currentTarget ~= targetPlayer then
					currentTarget = targetPlayer
					print("[EnemyAI] Enemy detected player")
				end

				faceTarget(rootPart, targetRootPart.Position)

				if distance > config.AttackRange then
					humanoid:MoveTo(targetRootPart.Position)
				else
					humanoid:MoveTo(rootPart.Position)

					local now = os.clock()
					if now - lastAttackTime >= config.FireCooldown then
						lastAttackTime = now
						print("[EnemyAI] Enemy attacking player")
						targetHumanoid:TakeDamage(config.Damage)
						print("[EnemyAI] Player damaged amount=" .. tostring(config.Damage))
					end
				end
			else
				currentTarget = nil

				local now = os.clock()
				if now - lastPatrolTime >= config.PatrolCooldown then
					lastPatrolTime = now
					humanoid:MoveTo(getPatrolPoint(homePosition, config.PatrolRadius))
				end
			end

			task.wait(0.15)
		end
	end)
end

return EnemyAI
