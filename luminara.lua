--[[
	Luminara UI
	A polished Roblox GUI template library for your own experiences and authorized projects.

	Usage:
	local Luminara = loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/Luminara.lua"))()
	local Window = Luminara:CreateWindow({ Name = "My Hub" })
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer and LocalPlayer:WaitForChild("PlayerGui")

local Luminara = {}
Luminara.__index = Luminara
Luminara.Version = "1.0.0"

local DEFAULT_THEME = {
	Background = Color3.fromRGB(13, 16, 24),
	BackgroundLight = Color3.fromRGB(20, 25, 36),
	Panel = Color3.fromRGB(25, 31, 44),
	PanelLight = Color3.fromRGB(32, 39, 55),
	Stroke = Color3.fromRGB(74, 89, 124),
	Accent = Color3.fromRGB(118, 199, 255),
	AccentDark = Color3.fromRGB(62, 119, 168),
	Success = Color3.fromRGB(92, 227, 150),
	Danger = Color3.fromRGB(255, 105, 125),
	Text = Color3.fromRGB(238, 243, 255),
	Muted = Color3.fromRGB(150, 161, 184),
	Shadow = Color3.fromRGB(0, 0, 0),
}

local function mergeTheme(custom)
	local theme = {}
	for key, value in pairs(DEFAULT_THEME) do
		theme[key] = value
	end
	for key, value in pairs(custom or {}) do
		theme[key] = value
	end
	return theme
end

local function make(className, props, children)
	local instance = Instance.new(className)
	for key, value in pairs(props or {}) do
		instance[key] = value
	end
	for _, child in ipairs(children or {}) do
		child.Parent = instance
	end
	return instance
end

local function corner(radius)
	return make("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

local function stroke(color, thickness, transparency)
	return make("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function padding(px)
	return make("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
	})
end

local function tween(object, time, goal, style, direction)
	local info = TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out)
	local active = TweenService:Create(object, info, goal)
	active:Play()
	return active
end

local function protectCall(callback, ...)
	if typeof(callback) == "function" then
		local ok, err = pcall(callback, ...)
		if not ok then
			warn("[Luminara] Callback error:", err)
		end
	end
end

local function createTextButton(props, children)
	return make("TextButton", props, children)
end

local function createLabel(props, children)
	return make("TextLabel", props, children)
end

local function createContainer(props, children)
	return make("Frame", props, children)
end

local function applyButtonMotion(button, baseColor, hoverColor)
	button.AutoButtonColor = false
	button.MouseEnter:Connect(function()
		tween(button, 0.16, { BackgroundColor3 = hoverColor })
	end)
	button.MouseLeave:Connect(function()
		tween(button, 0.16, { BackgroundColor3 = baseColor })
	end)
end

local function makeDraggable(handle, target)
	local dragging = false
	local dragStart
	local startPosition

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPosition = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
		end
	end)
end

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

function Luminara:CreateWindow(config)
	config = config or {}
	local theme = mergeTheme(config.Theme)
	local windowName = config.Name or "Luminara"
	local subtitle = config.Subtitle or "Interface"
	local width = config.Width or 640
	local height = config.Height or 460

	if not PlayerGui then
		error("Luminara must run on the client after PlayerGui is available.")
	end

	local existing = PlayerGui:FindFirstChild("Luminara")
	if existing then
		existing:Destroy()
	end

	local screenGui = make("ScreenGui", {
		Name = "Luminara",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = false,
		Parent = PlayerGui,
	})

	local root = createContainer({
		Name = "Root",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width, height),
		Parent = screenGui,
	}, {
		corner(12),
		stroke(theme.Stroke, 1, 0.25),
		make("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, theme.BackgroundLight),
				ColorSequenceKeypoint.new(1, theme.Background),
			}),
			Rotation = 35,
		}),
	})

	local dropShadow = make("ImageLabel", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Image = "rbxassetid://1316045217",
		ImageColor3 = theme.Shadow,
		ImageTransparency = 0.55,
		Position = UDim2.fromScale(0.5, 0.5),
		ScaleType = Enum.ScaleType.Slice,
		Size = UDim2.new(1, 42, 1, 42),
		SliceCenter = Rect.new(10, 10, 118, 118),
		ZIndex = 0,
		Parent = root,
	})
	dropShadow.Parent = root

	local topbar = createContainer({
		Name = "Topbar",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 64),
		Parent = root,
	})

	local brand = createContainer({
		Name = "Brand",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(20, 12),
		Size = UDim2.new(1, -120, 0, 42),
		Parent = topbar,
	})

	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 1),
		Parent = brand,
	})

	createLabel({
		Name = "Title",
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = windowName,
		TextColor3 = theme.Text,
		TextSize = 19,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 24),
		Parent = brand,
	})

	createLabel({
		Name = "Subtitle",
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = subtitle,
		TextColor3 = theme.Muted,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 16),
		Parent = brand,
	})

	local close = createTextButton({
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = "x",
		TextColor3 = theme.Muted,
		TextSize = 16,
		Position = UDim2.new(1, -16, 0, 16),
		Size = UDim2.fromOffset(34, 34),
		Parent = topbar,
	}, {
		corner(8),
		stroke(theme.Stroke, 1, 0.45),
	})
	applyButtonMotion(close, theme.Panel, theme.PanelLight)
	close.MouseButton1Click:Connect(function()
		tween(root, 0.24, { Size = UDim2.fromOffset(width, 0), BackgroundTransparency = 1 })
		task.delay(0.25, function()
			screenGui:Destroy()
		end)
	end)

	local sidebar = createContainer({
		Name = "Sidebar",
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(16, 72),
		Size = UDim2.new(0, 166, 1, -88),
		Parent = root,
	}, {
		corner(10),
		stroke(theme.Stroke, 1, 0.5),
		padding(10),
	})

	make("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = sidebar,
	})

	local content = createContainer({
		Name = "Content",
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Position = UDim2.fromOffset(194, 72),
		Size = UDim2.new(1, -210, 1, -88),
		Parent = root,
	}, {
		corner(10),
		stroke(theme.Stroke, 1, 0.5),
	})

	local notifyHolder = createContainer({
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -18, 0, 18),
		Size = UDim2.fromOffset(290, 360),
		Parent = screenGui,
	})

	make("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Parent = notifyHolder,
	})

	makeDraggable(topbar, root)

	local window = setmetatable({
		Config = config,
		Theme = theme,
		ScreenGui = screenGui,
		Root = root,
		Sidebar = sidebar,
		Content = content,
		NotifyHolder = notifyHolder,
		Tabs = {},
		SelectedTab = nil,
	}, Window)

	root.Size = UDim2.fromOffset(width, 0)
	root.BackgroundTransparency = 1
	tween(root, 0.35, { Size = UDim2.fromOffset(width, height), BackgroundTransparency = 0 }, Enum.EasingStyle.Back)

	if config.Keybind ~= false then
		local bind = config.Keybind or Enum.KeyCode.RightControl
		UserInputService.InputBegan:Connect(function(input, processed)
			if not processed and input.KeyCode == bind then
				window:Toggle()
			end
		end)
	end

	return window
end

function Window:Toggle()
	self.Root.Visible = not self.Root.Visible
end

function Window:Notify(config)
	config = config or {}
	local theme = self.Theme
	local duration = config.Duration or 4

	local card = createContainer({
		Name = "Notification",
		BackgroundColor3 = theme.Panel,
		BackgroundTransparency = 0.03,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(290, 0),
		Parent = self.NotifyHolder,
	}, {
		corner(9),
		stroke(theme.Stroke, 1, 0.35),
		padding(12),
	})

	createLabel({
		Name = "Title",
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = config.Title or "Luminara",
		TextColor3 = theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 18),
		Parent = card,
	})

	createLabel({
		Name = "Body",
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = config.Content or config.Text or "",
		TextColor3 = theme.Muted,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(0, 24),
		Size = UDim2.new(1, 0, 0, 38),
		Parent = card,
	})

	tween(card, 0.22, { Size = UDim2.fromOffset(290, 84) }, Enum.EasingStyle.Back)
	task.delay(duration, function()
		if card.Parent then
			tween(card, 0.18, { BackgroundTransparency = 1, Size = UDim2.fromOffset(290, 0) })
			task.delay(0.2, function()
				if card.Parent then
					card:Destroy()
				end
			end)
		end
	end)
end

function Window:CreateTab(config)
	config = typeof(config) == "table" and config or { Name = tostring(config) }
	local theme = self.Theme
	local tabName = config.Name or "Tab"

	local tabButton = createTextButton({
		Name = tabName .. "Button",
		BackgroundColor3 = theme.BackgroundLight,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = tabName,
		TextColor3 = theme.Muted,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 38),
		Parent = self.Sidebar,
	}, {
		corner(8),
		padding(12),
	})

	local page = make("ScrollingFrame", {
		Name = tabName,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		ScrollBarImageColor3 = theme.Accent,
		ScrollBarThickness = 3,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		Parent = self.Content,
	}, {
		padding(14),
	})

	local layout = make("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 12),
		Parent = page,
	})

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		page.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 28)
	end)

	local tab = setmetatable({
		Window = self,
		Name = tabName,
		Button = tabButton,
		Page = page,
		Layout = layout,
		Sections = {},
	}, Tab)

	tabButton.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)
	table.insert(self.Tabs, tab)

	if not self.SelectedTab then
		self:SelectTab(tab)
	end

	return tab
end

function Window:SelectTab(tab)
	for _, existing in ipairs(self.Tabs) do
		local active = existing == tab
		existing.Page.Visible = active
		tween(existing.Button, 0.18, {
			BackgroundColor3 = active and self.Theme.AccentDark or self.Theme.BackgroundLight,
			TextColor3 = active and self.Theme.Text or self.Theme.Muted,
		})
	end
	self.SelectedTab = tab
end

function Tab:CreateSection(config)
	config = typeof(config) == "table" and config or { Name = tostring(config) }
	local theme = self.Window.Theme

	local sectionFrame = createContainer({
		Name = config.Name or "Section",
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = theme.BackgroundLight,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = self.Page,
	}, {
		corner(10),
		stroke(theme.Stroke, 1, 0.55),
		padding(12),
	})

	local title = createLabel({
		Name = "Title",
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = config.Name or "Section",
		TextColor3 = theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 18),
		Parent = sectionFrame,
	})

	local body = createContainer({
		Name = "Body",
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 28),
		Size = UDim2.new(1, 0, 0, 0),
		Parent = sectionFrame,
	})

	make("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = body,
	})

	local section = setmetatable({
		Tab = self,
		Window = self.Window,
		Frame = sectionFrame,
		Title = title,
		Body = body,
	}, Section)

	table.insert(self.Sections, section)
	return section
end

function Tab:CreateButton(config)
	config = config or {}
	return self:CreateSection({ Name = config.Section or "Controls" }):CreateButton(config)
end

function Tab:CreateToggle(config)
	config = config or {}
	return self:CreateSection({ Name = config.Section or "Controls" }):CreateToggle(config)
end

function Tab:CreateSlider(config)
	config = config or {}
	return self:CreateSection({ Name = config.Section or "Controls" }):CreateSlider(config)
end

function Tab:CreateDropdown(config)
	config = config or {}
	return self:CreateSection({ Name = config.Section or "Controls" }):CreateDropdown(config)
end

function Tab:CreateInput(config)
	config = config or {}
	return self:CreateSection({ Name = config.Section or "Controls" }):CreateInput(config)
end

function Tab:CreateKeybind(config)
	config = config or {}
	return self:CreateSection({ Name = config.Section or "Controls" }):CreateKeybind(config)
end

function Section:_controlBase(config, height)
	local theme = self.Window.Theme
	local control = createContainer({
		Name = config.Name or "Control",
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, height or 42),
		Parent = self.Body,
	}, {
		corner(8),
		stroke(theme.Stroke, 1, 0.65),
	})

	createLabel({
		Name = "Label",
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamSemibold,
		Text = config.Name or "Control",
		TextColor3 = theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -24, 1, 0),
		Parent = control,
	})

	return control
end

function Section:CreateButton(config)
	config = config or {}
	local theme = self.Window.Theme
	local button = createTextButton({
		Name = config.Name or "Button",
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = config.Name or "Button",
		TextColor3 = theme.Text,
		TextSize = 13,
		Size = UDim2.new(1, 0, 0, 42),
		Parent = self.Body,
	}, {
		corner(8),
		stroke(theme.Stroke, 1, 0.6),
	})
	applyButtonMotion(button, theme.Panel, theme.PanelLight)
	button.MouseButton1Click:Connect(function()
		protectCall(config.Callback)
	end)
	return button
end

function Section:CreateToggle(config)
	config = config or {}
	local theme = self.Window.Theme
	local state = config.CurrentValue == true or config.Default == true
	local control = self:_controlBase(config, 44)

	local hitbox = createTextButton({
		Name = "Hitbox",
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		Parent = control,
	})

	local track = createContainer({
		Name = "Track",
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = state and theme.Accent or theme.PanelLight,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(46, 24),
		Parent = control,
	}, {
		corner(20),
	})

	local knob = createContainer({
		Name = "Knob",
		BackgroundColor3 = theme.Text,
		BorderSizePixel = 0,
		Position = state and UDim2.fromOffset(24, 3) or UDim2.fromOffset(3, 3),
		Size = UDim2.fromOffset(18, 18),
		Parent = track,
	}, {
		corner(20),
	})

	local api = {}
	function api:Set(value)
		state = value == true
		tween(track, 0.18, { BackgroundColor3 = state and theme.Accent or theme.PanelLight })
		tween(knob, 0.18, { Position = state and UDim2.fromOffset(24, 3) or UDim2.fromOffset(3, 3) })
		protectCall(config.Callback, state)
	end

	hitbox.MouseButton1Click:Connect(function()
		api:Set(not state)
	end)

	return api
end

function Section:CreateSlider(config)
	config = config or {}
	local theme = self.Window.Theme
	local min = config.Range and config.Range[1] or config.Min or 0
	local max = config.Range and config.Range[2] or config.Max or 100
	if max == min then
		max = min + 1
	end
	local increment = config.Increment or 1
	local value = math.clamp(config.CurrentValue or config.Default or min, min, max)
	local dragging = false

	local control = self:_controlBase(config, 64)
	control.Label.Size = UDim2.new(1, -82, 0, 34)

	local valueLabel = createLabel({
		Name = "Value",
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = tostring(value),
		TextColor3 = theme.Accent,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(1, -12, 0, 0),
		Size = UDim2.fromOffset(70, 34),
		Parent = control,
	})

	local bar = createContainer({
		Name = "Bar",
		BackgroundColor3 = theme.PanelLight,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 12, 1, -20),
		Size = UDim2.new(1, -24, 0, 6),
		Parent = control,
	}, {
		corner(10),
	})

	local fill = createContainer({
		Name = "Fill",
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.fromScale((value - min) / (max - min), 1),
		Parent = bar,
	}, {
		corner(10),
	})

	local function setFromAlpha(alpha, fire)
		alpha = math.clamp(alpha, 0, 1)
		local raw = min + (max - min) * alpha
		value = math.floor((raw / increment) + 0.5) * increment
		value = math.clamp(value, min, max)
		valueLabel.Text = tostring(value)
		tween(fill, 0.1, { Size = UDim2.fromScale((value - min) / (max - min), 1) })
		if fire ~= false then
			protectCall(config.Callback, value)
		end
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromAlpha((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromAlpha((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	return {
		Set = function(_, newValue)
			setFromAlpha((newValue - min) / (max - min))
		end,
		Get = function()
			return value
		end,
	}
end

function Section:CreateDropdown(config)
	config = config or {}
	local theme = self.Window.Theme
	local options = config.Options or {}
	local selected = config.CurrentOption or config.Default or options[1] or "None"
	local open = false

	local control = self:_controlBase(config, 44)
	control.ClipsDescendants = true

	local valueButton = createTextButton({
		Name = "Value",
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = theme.PanelLight,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamSemibold,
		Text = tostring(selected) .. "  v",
		TextColor3 = theme.Text,
		TextSize = 12,
		Position = UDim2.new(1, -10, 0, 22),
		Size = UDim2.fromOffset(150, 28),
		Parent = control,
	}, {
		corner(7),
	})

	local list = createContainer({
		Name = "List",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 48),
		Size = UDim2.new(1, -20, 0, 0),
		Parent = control,
	})

	make("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = list,
	})

	local function rebuild()
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("GuiButton") then
				child:Destroy()
			end
		end
		for _, option in ipairs(options) do
			local optionButton = createTextButton({
				Name = tostring(option),
				BackgroundColor3 = theme.PanelLight,
				BorderSizePixel = 0,
				Font = Enum.Font.GothamMedium,
				Text = tostring(option),
				TextColor3 = theme.Muted,
				TextSize = 12,
				Size = UDim2.new(1, 0, 0, 30),
				Parent = list,
			}, {
				corner(7),
			})
			optionButton.MouseButton1Click:Connect(function()
				selected = option
				valueButton.Text = tostring(selected) .. "  v"
				open = false
				tween(control, 0.18, { Size = UDim2.new(1, 0, 0, 44) })
				protectCall(config.Callback, selected)
			end)
		end
	end

	rebuild()

	valueButton.MouseButton1Click:Connect(function()
		open = not open
		valueButton.Text = tostring(selected) .. (open and "  ^" or "  v")
		tween(control, 0.18, { Size = UDim2.new(1, 0, 0, open and (58 + (#options * 36)) or 44) })
	end)

	return {
		Set = function(_, option)
			selected = option
			valueButton.Text = tostring(selected) .. "  v"
			protectCall(config.Callback, selected)
		end,
		Refresh = function(_, newOptions)
			options = newOptions or {}
			rebuild()
		end,
	}
end

function Section:CreateInput(config)
	config = config or {}
	local theme = self.Window.Theme
	local control = self:_controlBase(config, 48)

	local box = make("TextBox", {
		Name = "Input",
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = theme.PanelLight,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Font = Enum.Font.GothamMedium,
		PlaceholderColor3 = theme.Muted,
		PlaceholderText = config.PlaceholderText or config.Placeholder or "Type...",
		Text = config.CurrentValue or config.Default or "",
		TextColor3 = theme.Text,
		TextSize = 12,
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(170, 30),
		Parent = control,
	}, {
		corner(7),
		padding(8),
	})

	box.FocusLost:Connect(function(enterPressed)
		if config.SubmitOnEnter and not enterPressed then
			return
		end
		protectCall(config.Callback, box.Text)
	end)

	return box
end

function Section:CreateKeybind(config)
	config = config or {}
	local theme = self.Window.Theme
	local current = config.CurrentKeybind or config.Default or Enum.KeyCode.F
	local waiting = false
	local control = self:_controlBase(config, 44)

	local button = createTextButton({
		Name = "Bind",
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = theme.PanelLight,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = current.Name,
		TextColor3 = theme.Text,
		TextSize = 12,
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(112, 28),
		Parent = control,
	}, {
		corner(7),
	})

	button.MouseButton1Click:Connect(function()
		waiting = true
		button.Text = "..."
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if waiting and input.KeyCode ~= Enum.KeyCode.Unknown then
			current = input.KeyCode
			waiting = false
			button.Text = current.Name
			protectCall(config.ChangedCallback, current)
			return
		end
		if not processed and input.KeyCode == current then
			protectCall(config.Callback, current)
		end
	end)

	return {
		Set = function(_, keyCode)
			current = keyCode
			button.Text = current.Name
		end,
		Get = function()
			return current
		end,
	}
end

function Luminara:Destroy()
	local gui = PlayerGui and PlayerGui:FindFirstChild("Luminara")
	if gui then
		gui:Destroy()
	end
end

return Luminara
