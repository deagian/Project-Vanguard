-- Assembla il placeholder AssaultRifle attorno all'Handle.
-- La forma e piu lunga della pistola per leggere chiaramente il fucile in mano.

local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local receiver = tool:WaitForChild("Receiver")
local barrel = tool:WaitForChild("Barrel")
local stock = tool:WaitForChild("Stock")
local gripPart = tool:WaitForChild("GripPart")
local magazine = tool:WaitForChild("Magazine")

local visualParts = {
	{
		part = receiver,
		offset = CFrame.new(0, 0.06, -0.42),
	},
	{
		part = barrel,
		offset = CFrame.new(0, 0.09, -1.55),
	},
	{
		part = stock,
		offset = CFrame.new(0, 0.06, 0.55),
	},
	{
		part = gripPart,
		offset = CFrame.new(0, -0.36, -0.05) * CFrame.Angles(math.rad(-10), 0, 0),
	},
	{
		part = magazine,
		offset = CFrame.new(0, -0.44, -0.48) * CFrame.Angles(math.rad(8), 0, 0),
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
