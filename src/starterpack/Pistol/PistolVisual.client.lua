-- Assembles the temporary Pistol placeholder parts around the Handle.
-- Tool grip metadata controls hand position/orientation; this only welds visual parts.

local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local body = tool:WaitForChild("Body")
local barrel = tool:WaitForChild("Barrel")
local gripPart = tool:WaitForChild("GripPart")

local visualParts = {
	{
		part = body,
		offset = CFrame.new(0, 0.04, -0.1),
	},
	{
		part = barrel,
		offset = CFrame.new(0, 0.08, -0.7),
	},
	{
		part = gripPart,
		offset = CFrame.new(0, -0.36, 0.16) * CFrame.Angles(math.rad(-12), 0, 0),
	},
}

local function preparePart(part)
	part.Anchored = false
	part.CanCollide = false
	part.Massless = true
end

preparePart(handle)

for _, visual in ipairs(visualParts) do
	local part = visual.part
	preparePart(part)
	part.CFrame = handle.CFrame * visual.offset

	local weld = part:FindFirstChild("HandleWeld")
	if not weld then
		weld = Instance.new("WeldConstraint")
		weld.Name = "HandleWeld"
		weld.Parent = part
	end

	weld.Part0 = handle
	weld.Part1 = part
end
