local UserInputService = game:GetService("UserInputService")

local InputManager = {}

InputManager.Actions = {}

InputManager.Actions.Sprint = false

function InputManager:IsSprinting()

	return self.Actions.Sprint

end

UserInputService.InputBegan:Connect(function(input, gameProcessed)

	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.LeftShift then

		InputManager.Actions.Sprint = true

	end

end)

UserInputService.InputEnded:Connect(function(input)

	if input.KeyCode == Enum.KeyCode.LeftShift then

		InputManager.Actions.Sprint = false

	end

end)

return InputManager