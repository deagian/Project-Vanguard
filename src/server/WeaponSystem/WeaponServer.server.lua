-- WeaponServer handles trusted weapon firing for all players.
-- Clients can request a shot, but the server validates cooldown, hit detection, and damage.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Modules = Shared:WaitForChild("Modules")
local Remotes = Shared:WaitForChild("Remotes")

local WeaponConfig = require(Modules:WaitForChild("WeaponConfig"))
local WeaponFire = Remotes:WaitForChild("WeaponFire")
local WeaponHitConfirm = Remotes:WaitForChild("WeaponHitConfirm")

print("[WeaponServer] Loaded and listening")

local lastFireTimes = {}

local function rejectFire(weaponName, reason)
	if weaponName == "AssaultRifle" then
		print("[WeaponServer] Rejected AssaultRifle: " .. reason)
	end
end

local function logAR(message)
	print("[WeaponServer][AR] " .. message)
end

local function getEquippedTool(player, weaponName)
	local character = player.Character
	if not character then
		return nil
	end

	local tool = character:FindFirstChild(weaponName)
	if tool and tool:IsA("Tool") then
		return tool
	end

	return nil
end

local function getRayOrigin(character)
	local head = character:FindFirstChild("Head")
	if head then
		return head.Position
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		return rootPart.Position
	end

	return nil
end

local function findHumanoidFromHit(hitInstance)
	local current = hitInstance

	while current and current ~= workspace do
		local humanoid = current:FindFirstChildOfClass("Humanoid")
		if humanoid then
			return humanoid
		end

		current = current.Parent
	end

	return nil
end

local function tagEnemyKillCredit(humanoid, player)
	if not humanoid.Parent or humanoid.Parent.Name ~= "EnemyBot" then
		return
	end

	local lastDamagedBy = humanoid:FindFirstChild("LastDamagedBy")
	if not lastDamagedBy then
		lastDamagedBy = Instance.new("ObjectValue")
		lastDamagedBy.Name = "LastDamagedBy"
		lastDamagedBy.Parent = humanoid
	end

	lastDamagedBy.Value = player
end

local function canFire(player, weaponName, cooldown)
	local playerCooldowns = lastFireTimes[player]
	if not playerCooldowns then
		playerCooldowns = {}
		lastFireTimes[player] = playerCooldowns
	end

	local now = os.clock()
	local lastFireTime = playerCooldowns[weaponName] or 0

	if now - lastFireTime < cooldown then
		return false
	end

	playerCooldowns[weaponName] = now
	return true
end

local function getAimTargetPoint(shotOriginOrTarget, shotDirection, aimPoint, range)
	if typeof(aimPoint) == "Vector3" then
		return aimPoint
	end

	if typeof(shotDirection) == "Vector3" then
		if shotDirection.Magnitude <= 0 then
			return nil
		end

		if typeof(shotOriginOrTarget) ~= "Vector3" then
			return nil
		end

		return shotOriginOrTarget + shotDirection.Unit * range
	end

	if typeof(shotOriginOrTarget) ~= "Vector3" then
		return nil
	end

	return shotOriginOrTarget
end

local function onWeaponFire(player, weaponName, shotOriginOrTarget, shotDirection, aimPoint)
	print(
		"[WeaponServer] OnServerEvent received from player="
			.. player.Name
			.. " args="
			.. tostring(weaponName)
			.. ", "
			.. typeof(shotOriginOrTarget)
			.. ", "
			.. typeof(shotDirection)
			.. ", "
			.. typeof(aimPoint)
	)
	print("[WeaponServer] Fire request", player.Name, weaponName)
	if weaponName == "AssaultRifle" then
		print("[WeaponServer] Fire request AssaultRifle")
		logAR(
			"received args weaponName="
				.. tostring(weaponName)
				.. " originType="
				.. typeof(shotOriginOrTarget)
				.. " directionType="
				.. typeof(shotDirection)
				.. " aimPointType="
				.. typeof(aimPoint)
		)
	end

	if typeof(weaponName) ~= "string" then
		return
	end

	local settings = WeaponConfig[weaponName]
	if weaponName == "AssaultRifle" then
		logAR("config found=" .. tostring(settings ~= nil))
	end

	if not settings then
		rejectFire(weaponName, "missing config")
		return
	end

	local character = player.Character
	if not character then
		rejectFire(weaponName, "missing character")
		return
	end

	local equippedTool = getEquippedTool(player, weaponName)
	if weaponName == "AssaultRifle" then
		logAR("equipped ok=" .. tostring(equippedTool ~= nil) .. " toolName=" .. (equippedTool and equippedTool.Name or "nil"))
	end

	if not equippedTool then
		rejectFire(weaponName, "weapon not equipped")
		return
	end

	local rayOrigin = getRayOrigin(character)
	if not rayOrigin then
		rejectFire(weaponName, "missing ray origin")
		return
	end

	local aimTargetPoint = getAimTargetPoint(shotOriginOrTarget, shotDirection, aimPoint, settings.Range)
	if not aimTargetPoint then
		rejectFire(weaponName, "invalid direction")
		return
	end

	local serverDirection = aimTargetPoint - rayOrigin
	if serverDirection.Magnitude <= 0 then
		rejectFire(weaponName, "invalid server direction")
		return
	end

	local cooldownOk = canFire(player, weaponName, settings.FireCooldown)
	if weaponName == "AssaultRifle" then
		logAR("cooldown ok=" .. tostring(cooldownOk))
	end

	if not cooldownOk then
		rejectFire(weaponName, "cooldown")
		return
	end

	local rayDistance = settings.Range
	if typeof(aimPoint) == "Vector3" then
		rayDistance = math.min(serverDirection.Magnitude + 5, settings.Range)
	end

	local rayDirection = serverDirection.Unit * rayDistance
	print("[WeaponServer] serverOrigin=", rayOrigin)
	print("[WeaponServer] aimTargetPoint=", aimTargetPoint)
	print("[WeaponServer] finalRayDirection=", rayDirection)
	if weaponName == "AssaultRifle" then
		logAR("ray origin=" .. tostring(rayOrigin) .. " direction=" .. tostring(serverDirection.Unit) .. " range=" .. tostring(settings.Range))
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character }
	raycastParams.IgnoreWater = true

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if not result then
		print("[WeaponServer] hit=nil")
		if weaponName == "AssaultRifle" then
			logAR("ray hit part=nil model=nil")
		end
		print("[WeaponServer] Shot missed")
		rejectFire(weaponName, "miss")
		return
	end

	if weaponName == "AssaultRifle" then
		logAR(
			"ray hit part="
				.. result.Instance.Name
				.. " model="
				.. (result.Instance:FindFirstAncestorOfClass("Model") and result.Instance:FindFirstAncestorOfClass("Model").Name or "nil")
		)
	end

	print("[WeaponServer] hit=", result.Instance.Name)
	print("[WeaponServer] Hit object " .. result.Instance.Name)

	local humanoid = findHumanoidFromHit(result.Instance)
	if weaponName == "AssaultRifle" then
		logAR("humanoid found=" .. tostring(humanoid ~= nil))
	end

	if not humanoid or humanoid.Health <= 0 then
		print("[WeaponServer] Hit had no living humanoid")
		rejectFire(weaponName, "no living humanoid")
		return
	end

	if humanoid.Parent == character then
		rejectFire(weaponName, "self hit")
		return
	end

	local healthBefore = humanoid.Health
	print("[WeaponServer] Humanoid found")

	local isHeadshot = result.Instance.Name == "Head"
	local damage = settings.Damage

	if isHeadshot then
		damage *= settings.HeadshotMultiplier or 2
		print("[WeaponServer] Headshot")
	else
		print("[WeaponServer] Body shot")
	end

	-- Damage is always chosen by the server, never by the client request.
	tagEnemyKillCredit(humanoid, player)
	humanoid:TakeDamage(damage)
	print("[WeaponServer] Damage applied", healthBefore, "->", humanoid.Health)
	if weaponName == "AssaultRifle" then
		logAR("damage applied amount=" .. tostring(damage))
	end

	print("[WeaponServer] Hit confirmed")
	if weaponName == "AssaultRifle" then
		print("[WeaponServer] Hit confirmed AssaultRifle")
	end
	WeaponHitConfirm:FireClient(player, isHeadshot)
end

WeaponFire.OnServerEvent:Connect(onWeaponFire)

Players.PlayerRemoving:Connect(function(player)
	lastFireTimes[player] = nil
end)
