--[[
	Luminara UI
	A modern Roblox GUI library for your own experiences and authorized projects.

	Loadstring:
	local Luminara = loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/Luminara.lua"))()
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer and LocalPlayer:WaitForChild("PlayerGui")

local Luminara = {
	Version = "2.0.0",
	Windows = {},
	ConfigFolder = "Luminara",
}

local DEFAULT_THEME = {
	Background = Color3.fromRGB(12, 14, 20),
	Topbar = Color3.fromRGB(18, 22, 32),
	Sidebar = Color3.fromRGB(20, 24, 34),
	Panel = Color3.fromRGB(25, 30, 42),
	PanelAlt = Color3.fromRGB(31, 37, 52),
	Control = Color3.fromRGB(34, 41, 56),
	ControlHover = Color3.fromRGB(42, 50, 68),
	Stroke = Color3.fromRGB(69, 82, 112),
	Accent = Color3.fromRGB(92, 190, 255),
	AccentDark = Color3.fromRGB(38, 108, 169),
	Text = Color3.fromRGB(240, 245, 255),
	Subtext = Color3.fromRGB(159, 171, 195),
	Muted = Color3.fromRGB(105, 118, 145),
	Success = Color3.fromRGB(99, 230, 160),
	Warning = Color3.fromRGB(255, 203, 107),
	Danger = Color3.fromRGB(255, 100, 125),
	Shadow = Color3.fromRGB(0, 0, 0),
}

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

local WorkspaceTab = {}
WorkspaceTab.__index = WorkspaceTab

local function mergeTheme(theme)
	local merged = {}
	for key, value in pairs(DEFAULT_THEME) do
		merged[key] = value
	end
	for key, value in pairs(theme or {}) do
		merged[key] = value
	end
	return merged
end

local function make(className, props, children)
	local object = Instance.new(className)
	for key, value in pairs(props or {}) do
		object[key] = value
	end
	for _, child in ipairs(children or {}) do
		child.Parent = object
	end
	return object
end

local function corner(radius)
	return make("UICorner", { CornerRadius = UDim.new(0, radius or 12) })
end

local function stroke(color, thickness, transparency)
	return make("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0.35,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function pad(top, right, bottom, left)
	return make("UIPadding", {
		PaddingTop = UDim.new(0, top or 0),
		PaddingRight = UDim.new(0, right or top or 0),
		PaddingBottom = UDim.new(0, bottom or top or 0),
		PaddingLeft = UDim.new(0, left or right or top or 0),
	})
end

local function tween(object, duration, goal, style, direction)
	local info = TweenInfo.new(duration or 0.18, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out)
	local active = TweenService:Create(object, info, goal)
	active:Play()
	return active
end

local function safeCall(callback, ...)
	if typeof(callback) == "function" then
		local ok, err = pcall(callback, ...)
		if not ok then
			warn("[Luminara] callback error:", err)
		end
	end
end

local function normalizeIcon(icon)
	if typeof(icon) == "number" then
		return "rbxassetid://" .. tostring(icon)
	end
	if typeof(icon) == "string" and icon ~= "" then
		if icon:find("rbxassetid://") then
			return icon
		end
		if tonumber(icon) then
			return "rbxassetid://" .. icon
		end
		return icon
	end
	return ""
end

local function prettyKey(key)
	if typeof(key) == "EnumItem" then
		return key.Name
	end
	return tostring(key or "Unknown")
end

local function colorToTable(color)
	return {
		R = math.floor(color.R * 255 + 0.5),
		G = math.floor(color.G * 255 + 0.5),
		B = math.floor(color.B * 255 + 0.5),
	}
end

local function tableToColor(value, fallback)
	if typeof(value) == "Color3" then
		return value
	end
	if typeof(value) == "table" and value.R and value.G and value.B then
		return Color3.fromRGB(value.R, value.G, value.B)
	end
	return fallback or Color3.new(1, 1, 1)
end

local function isFileApiAvailable()
	return typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"
end

local function ensureFolder(folder)
	if typeof(makefolder) == "function" and typeof(isfolder) == "function" and not isfolder(folder) then
		pcall(makefolder, folder)
	end
end

local function buttonMotion(button, base, hover)
	button.AutoButtonColor = false
	button.MouseEnter:Connect(function()
		tween(button, 0.14, { BackgroundColor3 = hover })
	end)
	button.MouseLeave:Connect(function()
		tween(button, 0.14, { BackgroundColor3 = base })
	end)
end

local function attachDrag(handle, target)
	local dragging = false
	local startInput
	local startPosition
	local connections = {}

	table.insert(connections, handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startInput = input.Position
			startPosition = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end))

	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - startInput
			target.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
		end
	end))

	return connections
end

local function attachResize(handle, target, minSize)
	local resizing = false
	local startInput
	local startSize
	local connections = {}

	table.insert(connections, handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			startInput = input.Position
			startSize = target.Size
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					resizing = false
				end
			end)
		end
	end))

	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - startInput
			local width = math.max(minSize.X, startSize.X.Offset + delta.X)
			local height = math.max(minSize.Y, startSize.Y.Offset + delta.Y)
			target.Size = UDim2.fromOffset(width, height)
		end
	end))

	return connections
end

local function createText(parent, props)
	return make("TextLabel", {
		BackgroundTransparency = 1,
		Font = props.Font or Enum.Font.GothamMedium,
		Text = props.Text or "",
		TextColor3 = props.Color,
		TextSize = props.Size or 13,
		TextWrapped = props.Wrapped == true,
		TextXAlignment = props.X or Enum.TextXAlignment.Left,
		TextYAlignment = props.Y or Enum.TextYAlignment.Center,
		Position = props.Position or UDim2.fromOffset(0, 0),
		Size = props.BoxSize or UDim2.fromScale(1, 1),
		Parent = parent,
	})
end

local function createIcon(parent, icon, size, position)
	local image = normalizeIcon(icon)
	local label = make("ImageLabel", {
		BackgroundTransparency = 1,
		Image = image,
		ImageTransparency = image == "" and 1 or 0,
		Position = position or UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(size or 20, size or 20),
		Parent = parent,
	})
	return label
end

local function addGradient(frame, theme)
	return make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.PanelAlt),
			ColorSequenceKeypoint.new(1, theme.Panel),
		}),
		Rotation = 28,
		Parent = frame,
	})
end

local function createControlShell(section, config, height)
	local theme = section.Window.Theme
	local description = config.Description or config.Info or ""
	local frame = make("Frame", {
		Name = config.Name or config.Title or "Control",
		BackgroundColor3 = theme.Control,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Size = UDim2.new(1, 0, 0, height or (description ~= "" and 58 or 46)),
		Parent = section.Body,
	}, {
		corner(8),
		stroke(theme.Stroke, 1, 0.62),
	})
	section.Window:TrackTheme(frame, "BackgroundColor3", "Control")

	frame:SetAttribute("SearchText", string.lower((config.Name or "") .. " " .. (config.Title or "") .. " " .. description))
	table.insert(section.Tab.Searchables, frame)

	local titleLabel = createText(frame, {
		Text = config.Name or config.Title or "Control",
		Color = theme.Text,
		Font = Enum.Font.GothamBold,
		Size = 13,
		Position = UDim2.fromOffset(13, description ~= "" and 7 or 0),
		BoxSize = UDim2.new(1, -170, description ~= "" and 0 or 1, description ~= "" and 18 or 0),
	})
	section.Window:TrackTheme(titleLabel, "TextColor3", "Text")

	if description ~= "" then
		local descriptionLabel = createText(frame, {
			Text = description,
			Color = theme.Subtext,
			Font = Enum.Font.GothamMedium,
			Size = 11,
			Wrapped = true,
			Position = UDim2.fromOffset(13, 27),
			BoxSize = UDim2.new(1, -170, 0, 22),
			Y = Enum.TextYAlignment.Top,
		})
		section.Window:TrackTheme(descriptionLabel, "TextColor3", "Subtext")
	end

	return frame
end

function Luminara:CreateWindow(config)
	config = config or {}
	if not PlayerGui then
		error("Luminara must be required from a client context with PlayerGui available.")
	end

	local theme = mergeTheme(config.Theme)
	local size = config.Size or UDim2.fromOffset(config.Width or 720, config.Height or 500)
	local minSize = Vector2.new(config.MinWidth or 540, config.MinHeight or 360)
	local name = config.Name or config.Title or "Luminara"

	local screenGui = make("ScreenGui", {
		Name = config.GuiName or ("Luminara_" .. name:gsub("%W", "")),
		ResetOnSpawn = config.ResetOnSpawn == true,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = PlayerGui,
	})

	local root = make("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Position = config.Position or UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(0, 0),
		Parent = screenGui,
	}, {
		corner(10),
		stroke(theme.Stroke, 1, 0.24),
	})

	local shadow = make("ImageLabel", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Image = "rbxassetid://1316045217",
		ImageColor3 = theme.Shadow,
		ImageTransparency = 0.55,
		Position = UDim2.fromScale(0.5, 0.5),
		ScaleType = Enum.ScaleType.Slice,
		Size = UDim2.new(1, 44, 1, 44),
		SliceCenter = Rect.new(10, 10, 118, 118),
		ZIndex = 0,
		Parent = root,
	})

	local chrome = make("Frame", {
		Name = "ChromeTabs",
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 42),
		Parent = root,
	}, {
		stroke(theme.Stroke, 1, 0.72),
	})

	local workspaceHolder = make("Frame", {
		Name = "WorkspaceTabs",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.new(1, -66, 0, 30),
		Parent = chrome,
	})

	local workspaceLayout = make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 7),
		Parent = workspaceHolder,
	})

	local newWorkspace = make("TextButton", {
		Name = "NewWorkspace",
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = theme.Control,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBlack,
		Text = "+",
		TextColor3 = theme.Text,
		TextSize = 18,
		Position = UDim2.new(1, -12, 0, 8),
		Size = UDim2.fromOffset(32, 30),
		Parent = chrome,
	}, { corner(9), stroke(theme.Stroke, 1, 0.65) })

	local topbar = make("Frame", {
		Name = "Topbar",
		BackgroundColor3 = theme.Topbar,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 42),
		Size = UDim2.new(1, 0, 0, 60),
		Parent = root,
	}, {
		stroke(theme.Stroke, 1, 0.58),
	})

	createIcon(topbar, config.Icon, 30, UDim2.fromOffset(16, 14))
	createText(topbar, {
		Text = name,
		Color = theme.Text,
		Font = Enum.Font.GothamBlack,
		Size = 18,
		Position = UDim2.fromOffset(config.Icon and 56 or 18, 9),
		BoxSize = UDim2.new(1, -190, 0, 24),
	})
	createText(topbar, {
		Text = config.Subtitle or config.Description or "Modern interface library",
		Color = theme.Subtext,
		Font = Enum.Font.GothamMedium,
		Size = 11,
		Position = UDim2.fromOffset(config.Icon and 56 or 18, 32),
		BoxSize = UDim2.new(1, -190, 0, 16),
	})

	local minimize = make("TextButton", {
		Name = "Minimize",
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = theme.Control,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = "-",
		TextColor3 = theme.Text,
		TextSize = 18,
		Position = UDim2.new(1, -138, 0, 15),
		Size = UDim2.fromOffset(34, 30),
		Parent = topbar,
	}, { corner(9) })

	local settings = make("TextButton", {
		Name = "Settings",
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = theme.Control,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBlack,
		Text = "...",
		TextColor3 = theme.Text,
		TextSize = 14,
		Position = UDim2.new(1, -98, 0, 15),
		Size = UDim2.fromOffset(34, 30),
		Parent = topbar,
	}, { corner(9) })

	local maximize = make("TextButton", {
		Name = "Maximize",
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = theme.Control,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = "[]",
		TextColor3 = theme.Text,
		TextSize = 14,
		Position = UDim2.new(1, -58, 0, 15),
		Size = UDim2.fromOffset(34, 30),
		Parent = topbar,
	}, { corner(9) })

	local close = make("TextButton", {
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = theme.Control,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = "x",
		TextColor3 = theme.Text,
		TextSize = 15,
		Position = UDim2.new(1, -18, 0, 15),
		Size = UDim2.fromOffset(34, 30),
		Parent = topbar,
	}, { corner(9) })

	buttonMotion(minimize, theme.Control, theme.ControlHover)
	buttonMotion(settings, theme.Control, theme.ControlHover)
	buttonMotion(maximize, theme.Control, theme.ControlHover)
	buttonMotion(close, theme.Control, theme.Danger)

	local settingsMenu = make("Frame", {
		Name = "SettingsMenu",
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -58, 0, 49),
		Size = UDim2.fromOffset(190, 0),
		Visible = false,
		ZIndex = 10,
		Parent = topbar,
	}, {
		corner(10),
		stroke(theme.Stroke, 1, 0.36),
		pad(8),
	})
	make("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = settingsMenu,
	})

	local sidebar = make("Frame", {
		Name = "Tabs",
		BackgroundColor3 = theme.Sidebar,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(14, 116),
		Size = UDim2.new(0, 194, 1, -130),
		Parent = root,
	}, {
		corner(12),
		stroke(theme.Stroke, 1, 0.55),
		pad(10),
	})

	make("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 9),
		Parent = sidebar,
	})

	local content = make("Frame", {
		Name = "Content",
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Position = UDim2.fromOffset(222, 116),
		Size = UDim2.new(1, -236, 1, -130),
		Parent = root,
	}, {
		corner(12),
		stroke(theme.Stroke, 1, 0.55),
	})
	addGradient(content, theme)

	local resizeGrip = make("TextButton", {
		Name = "ResizeGrip",
		AnchorPoint = Vector2.new(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "\\",
		TextColor3 = theme.Muted,
		TextSize = 18,
		Position = UDim2.new(1, -5, 1, -4),
		Size = UDim2.fromOffset(32, 32),
		Parent = root,
	})

	local notifications = make("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -18, 0, 18),
		Size = UDim2.fromOffset(320, 500),
		Parent = screenGui,
	})
	make("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = notifications,
	})

	local window = setmetatable({
		Name = name,
		Theme = theme,
		ConfigName = config.ConfigName or name:gsub("%W", "_"),
		ScreenGui = screenGui,
		Root = root,
		Shadow = shadow,
		Chrome = chrome,
		WorkspaceHolder = workspaceHolder,
		WorkspaceLayout = workspaceLayout,
		NewWorkspaceButton = newWorkspace,
		Topbar = topbar,
		SettingsButton = settings,
		SettingsMenu = settingsMenu,
		Sidebar = sidebar,
		Content = content,
		Notifications = notifications,
		Tabs = {},
		SelectedTab = nil,
		Workspaces = {},
		SelectedWorkspace = nil,
		Options = {},
		Connections = {},
		ThemeBindings = {},
		HotkeyEnabled = true,
		Minimized = false,
		Maximized = false,
		NormalSize = size,
		NormalPosition = config.Position or UDim2.fromScale(0.5, 0.5),
	}, Window)

	for _, connection in ipairs(attachDrag(topbar, root)) do
		table.insert(window.Connections, connection)
	end
	for _, connection in ipairs(attachDrag(chrome, root)) do
		table.insert(window.Connections, connection)
	end
	for _, connection in ipairs(attachResize(resizeGrip, root, minSize)) do
		table.insert(window.Connections, connection)
	end

	window:TrackTheme(root, "BackgroundColor3", "Background")
	window:TrackTheme(chrome, "BackgroundColor3", "Background")
	window:TrackTheme(topbar, "BackgroundColor3", "Topbar")
	window:TrackTheme(sidebar, "BackgroundColor3", "Sidebar")
	window:TrackTheme(content, "BackgroundColor3", "Panel")
	window:TrackTheme(settingsMenu, "BackgroundColor3", "Panel")
	window:TrackTheme(newWorkspace, "BackgroundColor3", "Control")
	window:TrackTheme(minimize, "BackgroundColor3", "Control")
	window:TrackTheme(settings, "BackgroundColor3", "Control")
	window:TrackTheme(maximize, "BackgroundColor3", "Control")

	minimize.MouseButton1Click:Connect(function()
		window:SetMinimized(not window.Minimized)
	end)

	settings.MouseButton1Click:Connect(function()
		window:ToggleSettings()
	end)

	maximize.MouseButton1Click:Connect(function()
		window:SetMaximized(not window.Maximized)
	end)

	close.MouseButton1Click:Connect(function()
		window:Destroy()
	end)

	newWorkspace.MouseButton1Click:Connect(function()
		local created = window:CreateWorkspace({
			Name = "Window " .. tostring(#window.Workspaces + 1),
		})
		window:SelectWorkspace(created)
	end)

	if config.Watermark then
		window:CreateWatermark(typeof(config.Watermark) == "table" and config.Watermark or { Text = tostring(config.Watermark) })
	end

	if config.Keybind ~= false then
		local key = config.Keybind or Enum.KeyCode.RightControl
		table.insert(window.Connections, UserInputService.InputBegan:Connect(function(input, processed)
			if window.HotkeyEnabled and not processed and input.KeyCode == key then
				window:Toggle()
			end
		end))
	end

	window:BuildSettingsMenu()
	window:CreateWorkspace({ Name = config.WorkspaceName or "Window 1" })

	root.Size = UDim2.fromOffset(0, size.Y.Offset)
	tween(root, 0.34, { Size = size }, Enum.EasingStyle.Back)
	table.insert(Luminara.Windows, window)

	return window
end

function Window:TrackTheme(object, property, key)
	if object and property and key then
		table.insert(self.ThemeBindings, { Object = object, Property = property, Key = key })
		object[property] = self.Theme[key]
	end
	return object
end

function Window:SetTheme(theme)
	for key, value in pairs(theme or {}) do
		self.Theme[key] = value
	end
	for _, binding in ipairs(self.ThemeBindings) do
		if binding.Object and binding.Object.Parent and self.Theme[binding.Key] then
			binding.Object[binding.Property] = self.Theme[binding.Key]
		end
	end
	if self.SelectedWorkspace then
		for _, item in ipairs(self.Workspaces) do
			item.Button.BackgroundColor3 = item == self.SelectedWorkspace and self.Theme.AccentDark or self.Theme.Control
			item.Button.TextColor3 = item == self.SelectedWorkspace and self.Theme.Text or self.Theme.Subtext
		end
	end
	if self.SelectedTab then
		for _, item in ipairs(self.Tabs) do
			item.Button.BackgroundColor3 = item == self.SelectedTab and self.Theme.AccentDark or self.Theme.Control
		end
	end
end

function Window:_makeSettingsButton(text, callback)
	local button = make("TextButton", {
		BackgroundColor3 = self.Theme.Control,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = text,
		TextColor3 = self.Theme.Text,
		TextSize = 12,
		Size = UDim2.new(1, 0, 0, 32),
		ZIndex = 11,
		Parent = self.SettingsMenu,
	}, { corner(8) })
	self:TrackTheme(button, "BackgroundColor3", "Control")
	buttonMotion(button, self.Theme.Control, self.Theme.ControlHover)
	button.MouseButton1Click:Connect(function()
		self:ToggleSettings(false)
		safeCall(callback)
	end)
	return button
end

function Window:BuildSettingsMenu()
	self:_makeSettingsButton("Toggle hotkey: on", function()
		self.HotkeyEnabled = not self.HotkeyEnabled
		self:Notify({
			Title = "Settings",
			Content = "GUI hotkey is now " .. (self.HotkeyEnabled and "enabled." or "disabled."),
			Duration = 3,
		})
	end)
	self:_makeSettingsButton("Save current window", function()
		if self.SelectedWorkspace then
			self.SelectedWorkspace.Config = self:GetConfig()
			self:SaveConfig(self.ConfigName .. "_" .. self.SelectedWorkspace.Name:gsub("%W", "_"))
		end
		self:Notify({ Title = "Settings", Content = "Current window config saved.", Duration = 3 })
	end)
	self:_makeSettingsButton("Load current window", function()
		if self.SelectedWorkspace then
			local loaded = self:LoadConfig(self.ConfigName .. "_" .. self.SelectedWorkspace.Name:gsub("%W", "_"), true, true)
			if loaded then
				self.SelectedWorkspace.Config = loaded
			end
		end
		self:Notify({ Title = "Settings", Content = "Current window config loaded.", Duration = 3 })
	end)
	self:_makeSettingsButton("Destroy GUI", function()
		self:Destroy()
	end)
end

function Window:ToggleSettings(force)
	local visible = force
	if visible == nil then
		visible = not self.SettingsMenu.Visible
	end
	self.SettingsMenu.Visible = visible
	tween(self.SettingsMenu, 0.16, { Size = UDim2.fromOffset(190, visible and 146 or 0) })
end

function Window:CreateWorkspace(config)
	config = config or {}
	local name = config.Name or ("Window " .. tostring(#self.Workspaces + 1))
	local button = make("TextButton", {
		Name = name:gsub("%W", "") .. "Workspace",
		BackgroundColor3 = self.Theme.Control,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = name,
		TextColor3 = self.Theme.Text,
		TextSize = 12,
		Size = UDim2.fromOffset(138, 30),
		Parent = self.WorkspaceHolder,
	}, {
		corner(10),
		stroke(self.Theme.Stroke, 1, 0.55),
	})
	self:TrackTheme(button, "BackgroundColor3", "Control")

	local workspace = setmetatable({
		Name = name,
		Button = button,
		Config = config.Config or {},
	}, WorkspaceTab)
	button.MouseButton1Click:Connect(function()
		self:SelectWorkspace(workspace)
	end)
	table.insert(self.Workspaces, workspace)
	if not self.SelectedWorkspace then
		self:SelectWorkspace(workspace)
	end
	return workspace
end

function Window:SelectWorkspace(workspace)
	if self.SelectedWorkspace == workspace then
		return
	end
	if self.SelectedWorkspace then
		self.SelectedWorkspace.Config = self:GetConfig()
	end
	self.SelectedWorkspace = workspace
	for _, item in ipairs(self.Workspaces) do
		local active = item == workspace
		tween(item.Button, 0.16, {
			BackgroundColor3 = active and self.Theme.AccentDark or self.Theme.Control,
			TextColor3 = active and self.Theme.Text or self.Theme.Subtext,
		})
	end
	self:LoadConfigData(workspace.Config or {}, true, true)
end

function Window:RegisterOption(flag, option)
	if flag and flag ~= "" then
		self.Options[flag] = option
	end
end

function Window:SetMinimized(value)
	self.Minimized = value == true
	if self.Minimized then
		self.NormalSize = self.Root.Size
		tween(self.Root, 0.22, { Size = UDim2.fromOffset(self.Root.AbsoluteSize.X, 58) })
	else
		tween(self.Root, 0.22, { Size = self.NormalSize })
	end
end

function Window:SetMaximized(value)
	self.Maximized = value == true
	if self.Maximized then
		self.NormalSize = self.Root.Size
		self.NormalPosition = self.Root.Position
		tween(self.Root, 0.24, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -28, 1, -28),
		})
	else
		tween(self.Root, 0.24, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = self.NormalPosition,
			Size = self.NormalSize,
		})
	end
end

function Window:Toggle()
	self.Root.Visible = not self.Root.Visible
end

function Window:Destroy()
	for _, connection in ipairs(self.Connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	if self.ScreenGui then
		self.ScreenGui:Destroy()
	end
	for index, window in ipairs(Luminara.Windows) do
		if window == self then
			table.remove(Luminara.Windows, index)
			break
		end
	end
end

function Window:CreateTab(config)
	config = typeof(config) == "table" and config or { Name = tostring(config) }
	local theme = self.Theme
	local tabName = config.Name or config.Title or "Tab"

	local button = make("TextButton", {
		Name = tabName .. "Tab",
		BackgroundColor3 = theme.Control,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = "",
		TextColor3 = theme.Text,
		TextSize = 13,
		Size = UDim2.new(1, 0, 0, 64),
		Parent = self.Sidebar,
	}, {
		corner(8),
		stroke(theme.Stroke, 1, 0.7),
	})
	self:TrackTheme(button, "BackgroundColor3", "Control")

	createIcon(button, config.Icon, 26, UDim2.fromOffset(12, 19))
	createText(button, {
		Text = tabName,
		Color = theme.Text,
		Font = Enum.Font.GothamBold,
		Size = 13,
		Position = UDim2.fromOffset(config.Icon and 48 or 14, 10),
		BoxSize = UDim2.new(1, config.Icon and -58 or -24, 0, 20),
	})
	createText(button, {
		Text = config.Description or config.Subtitle or "",
		Color = theme.Subtext,
		Font = Enum.Font.GothamMedium,
		Size = 10,
		Wrapped = true,
		Position = UDim2.fromOffset(config.Icon and 48 or 14, 30),
		BoxSize = UDim2.new(1, config.Icon and -58 or -24, 0, 26),
		Y = Enum.TextYAlignment.Top,
	})

	local page = make("ScrollingFrame", {
		Name = tabName,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		ScrollBarImageColor3 = theme.Accent,
		ScrollBarThickness = 4,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		Parent = self.Content,
	}, { pad(14) })

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
		Button = button,
		Page = page,
		Layout = layout,
		Sections = {},
		Searchables = {},
	}, Tab)

	button.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)

	table.insert(self.Tabs, tab)
	if not self.SelectedTab then
		self:SelectTab(tab)
	end
	return tab
end

function Window:SelectTab(tab)
	for _, item in ipairs(self.Tabs) do
		local active = item == tab
		item.Page.Visible = active
		tween(item.Button, 0.18, {
			BackgroundColor3 = active and self.Theme.AccentDark or self.Theme.Control,
		})
	end
	self.SelectedTab = tab
end

function Window:Notify(config)
	config = config or {}
	local theme = self.Theme
	local duration = config.Duration or 4
	local card = make("Frame", {
		Name = "Notification",
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(320, 0),
		Parent = self.Notifications,
	}, {
		corner(8),
		stroke(theme.Stroke, 1, 0.32),
		pad(12),
	})
	addGradient(card, theme)

	createIcon(card, config.Icon, 24, UDim2.fromOffset(0, 4))
	createText(card, {
		Text = config.Title or "Notification",
		Color = theme.Text,
		Font = Enum.Font.GothamBold,
		Size = 14,
		Position = UDim2.fromOffset(config.Icon and 34 or 0, 0),
		BoxSize = UDim2.new(1, config.Icon and -34 or 0, 0, 20),
	})
	createText(card, {
		Text = config.Content or config.Description or "",
		Color = theme.Subtext,
		Font = Enum.Font.GothamMedium,
		Size = 12,
		Wrapped = true,
		Position = UDim2.fromOffset(config.Icon and 34 or 0, 25),
		BoxSize = UDim2.new(1, config.Icon and -34 or 0, 0, 42),
		Y = Enum.TextYAlignment.Top,
	})

	tween(card, 0.22, { Size = UDim2.fromOffset(320, 88) }, Enum.EasingStyle.Back)
	task.delay(duration, function()
		if card.Parent then
			tween(card, 0.18, { Size = UDim2.fromOffset(320, 0), BackgroundTransparency = 1 })
			task.delay(0.2, function()
				if card.Parent then
					card:Destroy()
				end
			end)
		end
	end)
	return card
end

function Window:CreateWatermark(config)
	config = config or {}
	local theme = self.Theme
	if self.Watermark then
		self.Watermark:Destroy()
	end
	local mark = make("TextButton", {
		Name = "Watermark",
		AnchorPoint = Vector2.new(0, 0),
		BackgroundColor3 = theme.Topbar,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = config.Text or (self.Name .. " | Luminara"),
		TextColor3 = theme.Text,
		TextSize = 12,
		Position = config.Position or UDim2.fromOffset(16, 16),
		Size = config.Size or UDim2.fromOffset(210, 34),
		Parent = self.ScreenGui,
	}, {
		corner(7),
		stroke(theme.Stroke, 1, 0.45),
	})
	for _, connection in ipairs(attachDrag(mark, mark)) do
		table.insert(self.Connections, connection)
	end
	self.Watermark = mark
	return mark
end

function Window:PromptDiscord(config)
	config = config or {}
	local text = config.Invite or config.Code or "discord.gg/example"
	self:Notify({
		Title = config.Title or "Discord",
		Content = (config.Content or "Join the community: ") .. text,
		Duration = config.Duration or 8,
		Icon = config.Icon,
	})
	if typeof(setclipboard) == "function" and config.Copy ~= false then
		pcall(setclipboard, text)
	end
end

function Window:CreateKeySystem(config)
	config = config or {}
	local theme = self.Theme
	local overlay = make("Frame", {
		Name = "KeySystem",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.28,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 20,
		Parent = self.ScreenGui,
	})

	local card = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(390, 210),
		ZIndex = 21,
		Parent = overlay,
	}, {
		corner(10),
		stroke(theme.Stroke, 1, 0.25),
		pad(18),
	})

	createText(card, {
		Text = config.Title or "Enter Key",
		Color = theme.Text,
		Font = Enum.Font.GothamBlack,
		Size = 20,
		BoxSize = UDim2.new(1, 0, 0, 28),
	})
	createText(card, {
		Text = config.Description or "Enter your access key to continue.",
		Color = theme.Subtext,
		Wrapped = true,
		Position = UDim2.fromOffset(0, 34),
		BoxSize = UDim2.new(1, 0, 0, 38),
		Y = Enum.TextYAlignment.Top,
	})

	local box = make("TextBox", {
		BackgroundColor3 = theme.Control,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Font = Enum.Font.GothamMedium,
		PlaceholderText = config.Placeholder or "Key",
		Text = "",
		TextColor3 = theme.Text,
		TextSize = 14,
		Position = UDim2.fromOffset(0, 86),
		Size = UDim2.new(1, 0, 0, 40),
		ZIndex = 22,
		Parent = card,
	}, {
		corner(7),
		pad(0, 10, 0, 10),
	})

	local submit = make("TextButton", {
		BackgroundColor3 = theme.AccentDark,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = config.SubmitText or "Unlock",
		TextColor3 = theme.Text,
		TextSize = 13,
		Position = UDim2.new(1, -130, 1, -40),
		Size = UDim2.fromOffset(130, 36),
		ZIndex = 22,
		Parent = card,
	}, { corner(7) })

	local keys = config.Keys or {}
	local function verify()
		local accepted = false
		for _, key in ipairs(keys) do
			if box.Text == tostring(key) then
				accepted = true
				break
			end
		end
		if accepted or typeof(config.Verify) == "function" and config.Verify(box.Text) == true then
			overlay:Destroy()
			safeCall(config.Callback, box.Text)
		else
			self:Notify({ Title = "Invalid key", Content = config.InvalidMessage or "That key was not accepted.", Duration = 3 })
		end
	end

	submit.MouseButton1Click:Connect(verify)
	box.FocusLost:Connect(function(enter)
		if enter then
			verify()
		end
	end)
	return overlay
end

function Window:GetConfig()
	local data = {}
	for flag, option in pairs(self.Options) do
		if typeof(option.Get) == "function" then
			local value = option:Get()
			if typeof(value) == "Color3" then
				data[flag] = { Type = "Color3", Value = colorToTable(value) }
			elseif typeof(value) == "EnumItem" then
				data[flag] = { Type = "EnumItem", Value = value.Name }
			else
				data[flag] = { Type = "Value", Value = value }
			end
		end
	end
	return data
end

function Window:LoadConfigData(data, fireCallbacks, resetMissing)
	data = data or {}
	if resetMissing then
		for flag, option in pairs(self.Options) do
			if data[flag] == nil and typeof(option.Set) == "function" and option.DefaultValue ~= nil then
				option:Set(option.DefaultValue, not fireCallbacks)
			end
		end
	end
	for flag, item in pairs(data) do
		local option = self.Options[flag]
		if option and typeof(option.Set) == "function" then
			local value = item.Value
			if item.Type == "Color3" then
				value = tableToColor(value)
			elseif item.Type == "EnumItem" and Enum.KeyCode[item.Value] then
				value = Enum.KeyCode[item.Value]
			end
			option:Set(value, not fireCallbacks)
		end
	end
end

function Window:SaveConfig(name)
	local fileName = name or self.ConfigName
	local data = self:GetConfig()
	if isFileApiAvailable() then
		ensureFolder(Luminara.ConfigFolder)
		writefile(Luminara.ConfigFolder .. "/" .. fileName .. ".json", HttpService:JSONEncode(data))
	end
	return data
end

function Window:LoadConfig(name, fireCallbacks, resetMissing)
	local fileName = name or self.ConfigName
	if isFileApiAvailable() then
		local path = Luminara.ConfigFolder .. "/" .. fileName .. ".json"
		if isfile(path) then
			local decoded = HttpService:JSONDecode(readfile(path))
			self:LoadConfigData(decoded, fireCallbacks, resetMissing)
			return decoded
		end
	end
	return nil
end

function Tab:CreateSearchBar(config)
	config = config or {}
	local theme = self.Window.Theme
	local holder = make("Frame", {
		Name = "Search",
		BackgroundColor3 = theme.Control,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 46),
		Parent = self.Page,
	}, {
		corner(8),
		stroke(theme.Stroke, 1, 0.62),
	})

	local box = make("TextBox", {
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		Font = Enum.Font.GothamMedium,
		PlaceholderText = config.Placeholder or "Search controls...",
		Text = "",
		TextColor3 = theme.Text,
		TextSize = 13,
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -28, 1, 0),
		Parent = holder,
	})

	box:GetPropertyChangedSignal("Text"):Connect(function()
		local query = string.lower(box.Text)
		for _, frame in ipairs(self.Searchables) do
			frame.Visible = query == "" or tostring(frame:GetAttribute("SearchText")):find(query, 1, true) ~= nil
		end
	end)
	return box
end

function Tab:CreateSection(config)
	config = typeof(config) == "table" and config or { Name = tostring(config) }
	local theme = self.Window.Theme
	local description = config.Description or ""
	local frame = make("Frame", {
		Name = config.Name or config.Title or "Section",
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = theme.PanelAlt,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = self.Page,
	}, {
		corner(8),
		stroke(theme.Stroke, 1, 0.55),
		pad(12),
	})

	createText(frame, {
		Text = config.Title or config.Name or "Section",
		Color = theme.Text,
		Font = Enum.Font.GothamBlack,
		Size = 15,
		BoxSize = UDim2.new(1, 0, 0, 20),
	})

	if description ~= "" then
		createText(frame, {
			Text = description,
			Color = theme.Subtext,
			Font = Enum.Font.GothamMedium,
			Size = 11,
			Wrapped = true,
			Position = UDim2.fromOffset(0, 24),
			BoxSize = UDim2.new(1, 0, 0, 28),
			Y = Enum.TextYAlignment.Top,
		})
	end

	local body = make("Frame", {
		Name = "Body",
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, description ~= "" and 62 or 32),
		Size = UDim2.new(1, 0, 0, 0),
		Parent = frame,
	})
	make("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = body,
	})

	local section = setmetatable({
		Tab = self,
		Window = self.Window,
		Frame = frame,
		Body = body,
	}, Section)
	table.insert(self.Sections, section)
	return section
end

function Tab:CreateButton(config) config = config or {} return self:CreateSection({ Name = config.Section or "Controls" }):CreateButton(config) end
function Tab:CreateToggle(config) config = config or {} return self:CreateSection({ Name = config.Section or "Controls" }):CreateToggle(config) end
function Tab:CreateSlider(config) config = config or {} return self:CreateSection({ Name = config.Section or "Controls" }):CreateSlider(config) end
function Tab:CreateDropdown(config) config = config or {} return self:CreateSection({ Name = config.Section or "Controls" }):CreateDropdown(config) end
function Tab:CreateMultiDropdown(config) config = config or {} return self:CreateSection({ Name = config.Section or "Controls" }):CreateMultiDropdown(config) end
function Tab:CreateTextbox(config) config = config or {} return self:CreateSection({ Name = config.Section or "Controls" }):CreateTextbox(config) end
function Tab:CreateInput(config) return self:CreateTextbox(config) end
function Tab:CreateLabel(config) config = config or {} return self:CreateSection({ Name = "Text" }):CreateLabel(config) end
function Tab:CreateParagraph(config) config = config or {} return self:CreateSection({ Name = "Text" }):CreateParagraph(config) end
function Tab:CreateKeybind(config) config = config or {} return self:CreateSection({ Name = config.Section or "Controls" }):CreateKeybind(config) end
function Tab:CreateColorPicker(config) config = config or {} return self:CreateSection({ Name = config.Section or "Controls" }):CreateColorPicker(config) end

function Section:CreateLabel(config)
	config = typeof(config) == "table" and config or { Text = tostring(config) }
	local theme = self.Window.Theme
	local label = make("TextLabel", {
		Name = "Label",
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = config.Text or config.Name or "Label",
		TextColor3 = config.Color or theme.Text,
		TextSize = config.TextSize or 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 20),
		Parent = self.Body,
	})
	return label
end

function Section:CreateParagraph(config)
	config = config or {}
	local theme = self.Window.Theme
	local frame = make("Frame", {
		Name = config.Title or "Paragraph",
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = theme.Control,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = self.Body,
	}, {
		corner(8),
		stroke(theme.Stroke, 1, 0.66),
		pad(12),
	})
	createText(frame, {
		Text = config.Title or "Paragraph",
		Color = theme.Text,
		Font = Enum.Font.GothamBold,
		Size = 13,
		BoxSize = UDim2.new(1, 0, 0, 18),
	})
	local body = createText(frame, {
		Text = config.Content or config.Text or "",
		Color = theme.Subtext,
		Font = Enum.Font.GothamMedium,
		Size = 12,
		Wrapped = true,
		Position = UDim2.fromOffset(0, 24),
		BoxSize = UDim2.new(1, 0, 0, config.Height or 46),
		Y = Enum.TextYAlignment.Top,
	})
	return { Frame = frame, Set = function(_, text) body.Text = text end }
end

function Section:CreateButton(config)
	config = config or {}
	local theme = self.Window.Theme
	local frame = createControlShell(self, config, config.Description and 58 or 46)
	local button = make("TextButton", {
		Name = "Action",
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = theme.AccentDark,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = config.ButtonText or "Run",
		TextColor3 = theme.Text,
		TextSize = 12,
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(110, 30),
		Parent = frame,
	}, { corner(10) })
	self.Window:TrackTheme(button, "BackgroundColor3", "AccentDark")
	self.Window:TrackTheme(button, "TextColor3", "Text")
	buttonMotion(button, theme.AccentDark, theme.Accent)
	button.MouseButton1Click:Connect(function()
		safeCall(config.Callback)
	end)
	return button
end

function Section:CreateToggle(config)
	config = config or {}
	local theme = self.Window.Theme
	local state = config.Default == true or config.CurrentValue == true
	local frame = createControlShell(self, config)
	local hitbox = make("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		Parent = frame,
	})
	local track = make("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = state and theme.Accent or theme.PanelAlt,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(48, 24),
		Parent = frame,
	}, { corner(20) })
	local knob = make("Frame", {
		BackgroundColor3 = theme.Text,
		BorderSizePixel = 0,
		Position = state and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3),
		Size = UDim2.fromOffset(18, 18),
		Parent = track,
	}, { corner(20) })
	self.Window:TrackTheme(knob, "BackgroundColor3", "Text")

	local api = {}
	api.DefaultValue = state
	function api:Set(value, silent)
		state = value == true
		tween(track, 0.16, { BackgroundColor3 = state and self.Window.Theme.Accent or self.Window.Theme.PanelAlt })
		tween(knob, 0.16, { Position = state and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3) })
		if not silent then
			safeCall(config.Callback, state)
		end
	end
	function api:Get()
		return state
	end
	hitbox.MouseButton1Click:Connect(function()
		api:Set(not state)
	end)
	self.Window:RegisterOption(config.Flag or config.Name, api)
	return api
end

function Section:CreateSlider(config)
	config = config or {}
	local theme = self.Window.Theme
	local min = config.Minimum or config.Min or (config.Range and config.Range[1]) or 0
	local max = config.Maximum or config.Max or (config.Range and config.Range[2]) or 100
	if max == min then max = min + 1 end
	local increment = config.Increment or 1
	local value = math.clamp(config.Default or config.CurrentValue or min, min, max)
	local dragging = false
	local frame = createControlShell(self, config, config.Description and 76 or 64)
	local label = createText(frame, {
		Text = tostring(value),
		Color = theme.Accent,
		Font = Enum.Font.GothamBold,
		Size = 13,
		X = Enum.TextXAlignment.Right,
		Position = UDim2.new(1, -82, 0, 0),
		BoxSize = UDim2.fromOffset(70, 34),
	})
	local bar = make("Frame", {
		BackgroundColor3 = theme.PanelAlt,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 13, 1, -22),
		Size = UDim2.new(1, -26, 0, 7),
		Parent = frame,
	}, { corner(10) })
	local fill = make("Frame", {
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.fromScale((value - min) / (max - min), 1),
		Parent = bar,
	}, { corner(10) })
	self.Window:TrackTheme(label, "TextColor3", "Accent")
	self.Window:TrackTheme(fill, "BackgroundColor3", "Accent")

	local api = {}
	api.DefaultValue = value
	function api:Set(newValue, silent)
		local rounded = math.floor((newValue / increment) + 0.5) * increment
		value = math.clamp(rounded, min, max)
		label.Text = tostring(value)
		tween(fill, 0.09, { Size = UDim2.fromScale((value - min) / (max - min), 1) })
		if not silent then
			safeCall(config.Callback, value)
		end
	end
	function api:Get()
		return value
	end
	local function setFromInput(input)
		local alpha = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		api:Set(min + (max - min) * alpha)
	end
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromInput(input)
		end
	end)
	table.insert(self.Window.Connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromInput(input)
		end
	end))
	table.insert(self.Window.Connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
	self.Window:RegisterOption(config.Flag or config.Name, api)
	return api
end

function Section:CreateDropdown(config)
	config = config or {}
	local theme = self.Window.Theme
	local options = config.Options or {}
	local selected = config.Default or config.CurrentOption or options[1]
	local open = false
	local frame = createControlShell(self, config, 48)
	local valueButton = make("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = theme.PanelAlt,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = tostring(selected or "Select") .. "  v",
		TextColor3 = theme.Text,
		TextSize = 12,
		Position = UDim2.new(1, -10, 0, 24),
		Size = UDim2.fromOffset(170, 30),
		Parent = frame,
	}, { corner(7) })
	local list = make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 54),
		Size = UDim2.new(1, -20, 0, 0),
		Parent = frame,
	})
	make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = list })

	local api = {}
	api.DefaultValue = selected
	local function rebuild()
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("GuiButton") then child:Destroy() end
		end
		for _, option in ipairs(options) do
			local item = make("TextButton", {
				BackgroundColor3 = theme.PanelAlt,
				BorderSizePixel = 0,
				Font = Enum.Font.GothamMedium,
				Text = tostring(option),
				TextColor3 = theme.Subtext,
				TextSize = 12,
				Size = UDim2.new(1, 0, 0, 30),
				Parent = list,
			}, { corner(7) })
			buttonMotion(item, theme.PanelAlt, theme.ControlHover)
			item.MouseButton1Click:Connect(function()
				api:Set(option)
				open = false
				valueButton.Text = tostring(selected) .. "  v"
				tween(frame, 0.16, { Size = UDim2.new(1, 0, 0, 48) })
			end)
		end
	end
	function api:Set(option, silent)
		selected = option
		valueButton.Text = tostring(selected or "Select") .. "  v"
		if not silent then safeCall(config.Callback, selected) end
	end
	function api:Get() return selected end
	function api:Refresh(newOptions)
		options = newOptions or {}
		rebuild()
	end
	rebuild()
	valueButton.MouseButton1Click:Connect(function()
		open = not open
		valueButton.Text = tostring(selected or "Select") .. (open and "  ^" or "  v")
		tween(frame, 0.16, { Size = UDim2.new(1, 0, 0, open and (62 + #options * 36) or 48) })
	end)
	self.Window:RegisterOption(config.Flag or config.Name, api)
	return api
end

function Section:CreateMultiDropdown(config)
	config = config or {}
	local selected = {}
	for _, value in ipairs(config.Default or config.CurrentOptions or {}) do
		selected[value] = true
	end
	local dropdown = self:CreateDropdown({
		Name = config.Name,
		Description = config.Description,
		Options = config.Options,
		Default = "Select",
		Callback = function(option)
			selected[option] = not selected[option]
			local values = {}
			for key, enabled in pairs(selected) do
				if enabled then table.insert(values, key) end
			end
			safeCall(config.Callback, values)
		end,
	})
	dropdown.DefaultValue = config.Default or config.CurrentOptions or {}
	function dropdown:Set(values, silent)
		selected = {}
		for _, value in ipairs(values or {}) do
			selected[value] = true
		end
		if not silent then safeCall(config.Callback, dropdown:Get()) end
	end
	function dropdown:Get()
		local values = {}
		for key, enabled in pairs(selected) do
			if enabled then table.insert(values, key) end
		end
		return values
	end
	self.Window:RegisterOption(config.Flag or config.Name, dropdown)
	return dropdown
end

function Section:CreateTextbox(config)
	config = config or {}
	local theme = self.Window.Theme
	local frame = createControlShell(self, config, config.Description and 62 or 50)
	local box = make("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = theme.PanelAlt,
		BorderSizePixel = 0,
		ClearTextOnFocus = config.ClearOnFocus == true,
		Font = Enum.Font.GothamMedium,
		PlaceholderText = config.Placeholder or config.PlaceholderText or "Type...",
		Text = config.Default or config.CurrentValue or "",
		TextColor3 = theme.Text,
		TextSize = 12,
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(180, 31),
		Parent = frame,
	}, { corner(7), pad(0, 8, 0, 8) })
	local api = {}
	api.DefaultValue = box.Text
	function api:Set(value, silent)
		box.Text = tostring(value or "")
		if not silent then safeCall(config.Callback, box.Text) end
	end
	function api:Get() return box.Text end
	box.FocusLost:Connect(function(enter)
		if config.SubmitOnEnter and not enter then return end
		safeCall(config.Callback, box.Text)
	end)
	self.Window:RegisterOption(config.Flag or config.Name, api)
	return api
end

function Section:CreateKeybind(config)
	config = config or {}
	local theme = self.Window.Theme
	local current = config.Default or config.CurrentKeybind or Enum.KeyCode.F
	local waiting = false
	local frame = createControlShell(self, config)
	local button = make("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = theme.PanelAlt,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = prettyKey(current),
		TextColor3 = theme.Text,
		TextSize = 12,
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(120, 30),
		Parent = frame,
	}, { corner(7) })
	local api = {}
	api.DefaultValue = current
	function api:Set(key, silent)
		current = key
		button.Text = prettyKey(current)
		if not silent then safeCall(config.ChangedCallback, current) end
	end
	function api:Get() return current end
	button.MouseButton1Click:Connect(function()
		waiting = true
		button.Text = "..."
	end)
	table.insert(self.Window.Connections, UserInputService.InputBegan:Connect(function(input, processed)
		if waiting and input.KeyCode ~= Enum.KeyCode.Unknown then
			waiting = false
			api:Set(input.KeyCode)
			return
		end
		if not processed and input.KeyCode == current then
			safeCall(config.Callback, current)
		end
	end))
	self.Window:RegisterOption(config.Flag or config.Name, api)
	return api
end

function Section:CreateColorPicker(config)
	config = config or {}
	local theme = self.Window.Theme
	local value = config.Default or config.CurrentColor or theme.Accent
	local frame = createControlShell(self, config, 88)
	local preview = make("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = value,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.fromOffset(46, 32),
		Parent = frame,
	}, { corner(10), stroke(theme.Stroke, 1, 0.5) })
	local sliders = {}
	local api = {}
	local draggingChannel = nil
	local function channelOf(color, channel)
		if channel == "R" then return color.R end
		if channel == "G" then return color.G end
		return color.B
	end
	local function update(silent)
		value = Color3.fromRGB(sliders.R:Get(), sliders.G:Get(), sliders.B:Get())
		preview.BackgroundColor3 = value
		if config.ThemeKey then
			local updateTheme = {}
			updateTheme[config.ThemeKey] = value
			if config.ThemeKey == "Accent" and config.UpdateAccentDark ~= false then
				updateTheme.AccentDark = value:Lerp(Color3.fromRGB(0, 0, 0), 0.38)
			end
			self.Window:SetTheme(updateTheme)
		end
		if not silent then safeCall(config.Callback, value) end
	end
	for index, channel in ipairs({ "R", "G", "B" }) do
		local bar = make("Frame", {
			BackgroundColor3 = theme.PanelAlt,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(13 + ((index - 1) * 94), 62),
			Size = UDim2.fromOffset(82, 8),
			Parent = frame,
		}, { corner(10) })
		make("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBlack,
			Text = channel,
			TextColor3 = theme.Subtext,
			TextSize = 10,
			Position = UDim2.fromOffset(13 + ((index - 1) * 94), 47),
			Size = UDim2.fromOffset(82, 12),
			Parent = frame,
		})
		local fill = make("Frame", {
			BackgroundColor3 = channel == "R" and Color3.fromRGB(255, 90, 110) or channel == "G" and Color3.fromRGB(90, 230, 140) or Color3.fromRGB(90, 170, 255),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(channelOf(value, channel), 1),
			Parent = bar,
		}, { corner(10) })
		local channelValue = math.floor(channelOf(value, channel) * 255 + 0.5)
		local function setFromInput(input)
			sliders[channel]:Set(((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X) * 255)
		end
		sliders[channel] = {
			Get = function() return channelValue end,
			Set = function(_, newValue, silent)
				channelValue = math.clamp(math.floor(newValue + 0.5), 0, 255)
				fill.Size = UDim2.fromScale(channelValue / 255, 1)
				if not silent then update() end
			end,
		}
		bar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				draggingChannel = channel
				setFromInput(input)
			end
		end)
		table.insert(self.Window.Connections, UserInputService.InputChanged:Connect(function(input)
			if draggingChannel == channel and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				setFromInput(input)
			end
		end))
	end
	table.insert(self.Window.Connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingChannel = nil
		end
	end))
	api.DefaultValue = value
	function api:Set(color, silent)
		value = tableToColor(color, value)
		sliders.R:Set(value.R * 255, true)
		sliders.G:Set(value.G * 255, true)
		sliders.B:Set(value.B * 255, true)
		preview.BackgroundColor3 = value
		update(silent)
	end
	function api:Get() return value end
	self.Window:RegisterOption(config.Flag or config.Name, api)
	return api
end

function Luminara:Notify(config)
	local window = self.Windows[#self.Windows]
	if window then
		return window:Notify(config)
	end
end

function Luminara:Destroy()
	local windows = {}
	for _, window in ipairs(self.Windows) do
		table.insert(windows, window)
	end
	for _, window in ipairs(windows) do
		window:Destroy()
	end
	self.Windows = {}
end

return Luminara
