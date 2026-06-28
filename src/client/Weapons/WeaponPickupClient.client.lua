-- WeaponPickupClient forwards ProximityPrompt pickups to the server.
-- The server owns validation and decides whether a weapon is granted.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = Shared:WaitForChild("Remotes")
local RequestWeaponPickup = Remotes:WaitForChild("RequestWeaponPickup")

local HIGHLIGHT_NAME = "WeaponPickupHighlight"
local HIGHLIGHT_FILL_COLOR = Color3.fromRGB(190, 225, 255)
local HIGHLIGHT_OUTLINE_COLOR = Color3.fromRGB(240, 250, 255)

local pickupByPrompt = setmetatable({}, { __mode = "k" })
local shownPrompts = setmetatable({}, { __mode = "k" })
local watchedPrompts = setmetatable({}, { __mode = "k" })

local function findPickupRoot(instance)
	local current = instance

	while current and current ~= workspace do
		if current:GetAttribute("WeaponId") ~= nil then
			return current
		end

		current = current.Parent
	end

	return nil
end

local function getOrCreateHighlight(pickupRoot)
	local highlight = pickupRoot:FindFirstChild(HIGHLIGHT_NAME)
	if highlight and not highlight:IsA("Highlight") then
		return nil
	end

	if not highlight then
		highlight = Instance.new("Highlight")
		highlight.Name = HIGHLIGHT_NAME
		highlight.Parent = pickupRoot
	end

	local adornee = pickupRoot
	if not pickupRoot:IsA("BasePart") and not pickupRoot:IsA("Model") then
		adornee = pickupRoot:FindFirstChildWhichIsA("BasePart", true)
	end

	if not adornee then
		return nil
	end

	highlight.Adornee = adornee
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = HIGHLIGHT_FILL_COLOR
	highlight.FillTransparency = 0.7
	highlight.OutlineColor = HIGHLIGHT_OUTLINE_COLOR
	highlight.OutlineTransparency = 0
	highlight.Enabled = false

	return highlight
end

local function registerPickupPrompt(prompt)
	if prompt:GetAttribute("PVWeaponPickupPrompt") ~= true then
		return
	end

	local pickupRoot = findPickupRoot(prompt.Parent)
	if not pickupRoot then
		return
	end

	pickupByPrompt[prompt] = pickupRoot

	local highlight = getOrCreateHighlight(pickupRoot)
	if highlight and shownPrompts[prompt] then
		highlight.Enabled = true
	end
end

local function watchPrompt(instance)
	if not instance:IsA("ProximityPrompt") or watchedPrompts[instance] then
		return
	end

	watchedPrompts[instance] = true
	registerPickupPrompt(instance)

	instance:GetAttributeChangedSignal("PVWeaponPickupPrompt"):Connect(function()
		registerPickupPrompt(instance)
	end)
end

for _, descendant in ipairs(workspace:GetDescendants()) do
	watchPrompt(descendant)
end

workspace.DescendantAdded:Connect(watchPrompt)

ProximityPromptService.PromptShown:Connect(function(prompt)
	shownPrompts[prompt] = true
	registerPickupPrompt(prompt)

	local pickupRoot = pickupByPrompt[prompt]
	local highlight = pickupRoot and pickupRoot:FindFirstChild(HIGHLIGHT_NAME)
	if highlight and highlight:IsA("Highlight") then
		highlight.Enabled = true
	end
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
	shownPrompts[prompt] = nil

	local pickupRoot = pickupByPrompt[prompt]
	local highlight = pickupRoot and pickupRoot:FindFirstChild(HIGHLIGHT_NAME)
	if highlight and highlight:IsA("Highlight") then
		highlight.Enabled = false
	end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if prompt:GetAttribute("PVWeaponPickupPrompt") ~= true then
		return
	end

	local pickupRoot = findPickupRoot(prompt.Parent)
	if not pickupRoot then
		return
	end

	RequestWeaponPickup:FireServer(pickupRoot)
end)
