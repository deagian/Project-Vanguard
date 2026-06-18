local UserInputService = game:GetService("UserInputService")

local InputManager = {}

InputManager.Actions = {}

InputManager.Actions.Sprint = false
InputManager.Actions.Crouch = false

function InputManager:IsSprinting()

	return self.Actions.Sprint

end

function InputManager:IsCrouching()

	return self.Actions.Crouch

end

function InputManager:SetCrouching(isCrouching)

	self.Actions.Crouch = isCrouching == true

end

UserInputService.InputBegan:Connect(function(input, gameProcessed)

	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.LeftShift then

		InputManager.Actions.Sprint = true

	elseif input.KeyCode == Enum.KeyCode.C then

		InputManager.Actions.Crouch = not InputManager.Actions.Crouch

	end

end)

UserInputService.InputEnded:Connect(function(input)

	if input.KeyCode == Enum.KeyCode.LeftShift then

		InputManager.Actions.Sprint = false

	end

end)

return InputManager
