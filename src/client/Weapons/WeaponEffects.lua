local Debris = game:GetService("Debris")

local WeaponEffects = {}

local FLASH_DURATION = 0.06
local DEFAULT_FIRE_SOUND_ID = "rbxassetid://9119561046"

local FIRE_SOUND_IDS = {
	Pistol = DEFAULT_FIRE_SOUND_ID,
	AssaultRifle = DEFAULT_FIRE_SOUND_ID,
	SMG = DEFAULT_FIRE_SOUND_ID,
}

local function findDescendantBasePart(root, name)
	local descendant = root:FindFirstChild(name, true)
	if descendant and descendant:IsA("BasePart") then
		return descendant
	end

	return nil
end

local function findMuzzlePart(tool)
	local muzzle = findDescendantBasePart(tool, "Muzzle")
	if muzzle then
		return muzzle
	end

	local barrel = findDescendantBasePart(tool, "Barrel")
	if barrel then
		return barrel
	end

	local handle = findDescendantBasePart(tool, "Handle")
	if handle then
		return handle
	end

	return nil
end

local function findMuzzleAttachment(tool)
	local attachment = tool:FindFirstChild("MuzzleAttachment", true)
	if attachment and attachment:IsA("Attachment") then
		return attachment
	end

	return nil
end

local function getOrCreateMuzzleAttachment(tool)
	local existingAttachment = findMuzzleAttachment(tool)
	if existingAttachment then
		return existingAttachment
	end

	local muzzlePart = findMuzzlePart(tool)
	if not muzzlePart then
		return nil
	end

	local attachment = muzzlePart:FindFirstChild("MuzzleAttachment")
	if attachment and attachment:IsA("Attachment") then
		return attachment
	end

	attachment = Instance.new("Attachment")
	attachment.Name = "MuzzleAttachment"
	-- TODO: sostituire con modello arma professionale con attachment muzzle gia posizionato.
	attachment.Position = Vector3.new(0, 0, -muzzlePart.Size.Z / 2 - 0.12)
	attachment.Parent = muzzlePart

	return attachment
end

function WeaponEffects.GetMuzzleWorldPosition(tool)
	local attachment = findMuzzleAttachment(tool)
	if attachment then
		print("[WeaponEffects] Muzzle source=Attachment weapon=" .. tool.Name)
		return attachment.WorldPosition
	end

	local muzzle = findDescendantBasePart(tool, "Muzzle")
	if muzzle then
		print("[WeaponEffects] Muzzle source=Muzzle weapon=" .. tool.Name)
		return muzzle.Position + muzzle.CFrame.LookVector * (muzzle.Size.Z / 2 + 0.12)
	end

	local barrel = findDescendantBasePart(tool, "Barrel")
	if barrel then
		print("[WeaponEffects] Muzzle source=Barrel weapon=" .. tool.Name)
		return barrel.Position + barrel.CFrame.LookVector * (barrel.Size.Z / 2 + 0.12)
	end

	local handle = findDescendantBasePart(tool, "Handle")
	if handle then
		print("[WeaponEffects] Muzzle source=Handle weapon=" .. tool.Name)
		return handle.Position + handle.CFrame.LookVector * (handle.Size.Z / 2 + 0.12)
	end

	print("[WeaponEffects] No muzzle point found for " .. tool.Name)
	return nil
end

local function getSoundParent(tool)
	return tool:FindFirstChild("Handle") or tool
end

function WeaponEffects.PlayMuzzleFlash(tool)
	local attachment = getOrCreateMuzzleAttachment(tool)
	if not attachment then
		print("[WeaponEffects] No muzzle point found for " .. tool.Name)
		return
	end

	local light = Instance.new("PointLight")
	light.Name = "TemporaryMuzzleLight"
	light.Brightness = 14
	light.Range = 12
	light.Color = Color3.fromRGB(255, 185, 70)
	light.Parent = attachment

	local particles = Instance.new("ParticleEmitter")
	particles.Name = "TemporaryMuzzleParticles"
	particles.Texture = "rbxasset://textures/particles/fire_main.dds"
	particles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 245, 170)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 115, 25)),
	})
	particles.LightEmission = 1
	particles.Lifetime = NumberRange.new(0.04, 0.08)
	particles.Rate = 0
	particles.Rotation = NumberRange.new(0, 360)
	particles.RotSpeed = NumberRange.new(-180, 180)
	particles.Speed = NumberRange.new(1, 3)
	particles.SpreadAngle = Vector2.new(18, 18)
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.32),
		NumberSequenceKeypoint.new(0.45, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	particles.Parent = attachment
	particles:Emit(10)

	Debris:AddItem(light, FLASH_DURATION)
	Debris:AddItem(particles, FLASH_DURATION + 0.08)

	print("[WeaponEffects] Muzzle flash played for " .. tool.Name)
end

function WeaponEffects.PlayFireSound(tool, weaponName)
	local soundId = FIRE_SOUND_IDS[weaponName] or DEFAULT_FIRE_SOUND_ID
	if soundId == "" then
		return
	end

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = if weaponName == "AssaultRifle" or weaponName == "SMG" then 0.58 else 0.75
	sound.RollOffMaxDistance = if weaponName == "AssaultRifle" or weaponName == "SMG" then 120 else 80
	sound.Parent = getSoundParent(tool)
	sound:Play()

	sound.Ended:Connect(function()
		sound:Destroy()
	end)

	task.delay(3, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

function WeaponEffects.PlayBulletTracer(origin, direction, range)
	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" or direction.Magnitude <= 0 then
		return
	end

	local tracerLength = math.min(range or 300, 160)
	local tracerDirection = direction.Unit
	local tracer = Instance.new("Part")
	tracer.Name = "TemporaryBulletTracer"
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.CanQuery = false
	tracer.CanTouch = false
	tracer.CastShadow = false
	tracer.Material = Enum.Material.Neon
	tracer.Color = Color3.fromRGB(255, 210, 95)
	tracer.Transparency = 0.18
	tracer.Size = Vector3.new(0.035, 0.035, tracerLength)
	tracer.CFrame = CFrame.lookAt(
		origin + tracerDirection * (tracerLength / 2),
		origin + tracerDirection * (tracerLength / 2 + 1)
	)
	tracer.Parent = workspace

	Debris:AddItem(tracer, 0.055)
end

return WeaponEffects
