-- Assembla il placeholder SMG attorno all'Handle.
-- La forma e compatta per distinguere lo slot 3 dal fucile d'assalto.

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
		offset = CFrame.new(0, 0.05, -0.32),
	},
	{
		part = barrel,
		offset = CFrame.new(0, 0.08, -1.0),
	},
	{
		part = stock,
		offset = CFrame.new(0, 0.05, 0.38),
	},
	{
		part = gripPart,
		offset = CFrame.new(0, -0.36, -0.05) * CFrame.Angles(math.rad(-10), 0, 0),
	},
	{
		part = magazine,
		offset = CFrame.new(0, -0.4, -0.34) * CFrame.Angles(math.rad(5), 0, 0),
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
