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

local lastFireTimes = {}

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

local function onWeaponFire(player, weaponName, targetPosition)
	print("[WeaponServer] Fire request", player.Name, weaponName)

	if typeof(weaponName) ~= "string" or typeof(targetPosition) ~= "Vector3" then
		return
	end

	local settings = WeaponConfig[weaponName]
	if not settings then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	if not getEquippedTool(player, weaponName) then
		return
	end

	if not canFire(player, weaponName, settings.FireCooldown) then
		return
	end

	local rayOrigin = getRayOrigin(character)
	if not rayOrigin then
		return
	end

	local targetDirection = targetPosition - rayOrigin
	if targetDirection.Magnitude <= 0 then
		return
	end

	local rayDirection = targetDirection.Unit * settings.Range

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character }
	raycastParams.IgnoreWater = true

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if not result then
		print("[WeaponServer] Shot missed")
		return
	end

	print("[WeaponServer] Hit object " .. result.Instance.Name)

	local humanoid = findHumanoidFromHit(result.Instance)
	if not humanoid or humanoid.Health <= 0 then
		print("[WeaponServer] Hit had no living humanoid")
		return
	end

	if humanoid.Parent == character then
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
	humanoid:TakeDamage(damage)
	print("[WeaponServer] Damage applied", healthBefore, "->", humanoid.Health)

	print("[WeaponServer] Hit confirmed")
	WeaponHitConfirm:FireClient(player, isHeadshot)
end

WeaponFire.OnServerEvent:Connect(onWeaponFire)

Players.PlayerRemoving:Connect(function(player)
	lastFireTimes[player] = nil
end)
