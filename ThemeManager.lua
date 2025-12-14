local httpService = game:GetService('HttpService')
local ThemeManager = {} do
	ThemeManager.Folder = 'LinoriaLibSettings'
	ThemeManager.Library = nil
	ThemeManager.BuiltInThemes = {
		['Default'] 		= { 1, httpService:JSONDecode('{"FontColor":"BFBFBF","MainColor":"0F0F0F","AccentColor":"d17bff","BackgroundColor":"101010","OutlineColor":"0B0B0B"}') },
		['Venom'] 		= { 2, httpService:JSONDecode('{"FontColor":"BFBFBF","MainColor":"0E0E0E","AccentColor":"ff0000","BackgroundColor":"0E0E0E","OutlineColor":"0B0B0B"}') },
		['Cyan'] 		= { 3, httpService:JSONDecode('{"FontColor":"BFBFBF","MainColor":"0F0F0F","AccentColor":"00ffef","BackgroundColor":"101010","OutlineColor":"0B0B0B"}') },
		['Burn'] 		= { 4, httpService:JSONDecode('{"FontColor":"FF8200","MainColor":"0C0C0C","AccentColor":"FF8200","BackgroundColor":"0C0C0C","OutlineColor":"0C0C0C"}') },
		['Fatality'] 		= { 5, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1842","AccentColor":"c50754","BackgroundColor":"191335","OutlineColor":"28204F"}') },
		['GameSense'] 		= { 6, httpService:JSONDecode('{"FontColor":"FFFFFF","MainColor":"171717","AccentColor":"98E22E","BackgroundColor":"171717","OutlineColor":"31371C"}') },
		['Comet.pub'] 		= { 7, httpService:JSONDecode('{"FontColor":"5E5E5E","MainColor":"0F0F0F","AccentColor":"5D589D","BackgroundColor":"0F0F0F","OutlineColor":"191919"}') },
		['Neon Violet'] 	= { 8, httpService:JSONDecode('{"FontColor":"EFEFEF","MainColor":"1A1A1A","AccentColor":"8A2BE2","BackgroundColor":"151515","OutlineColor":"0D0D0D"}') },
		['Ocean Blue'] 		= { 9, httpService:JSONDecode('{"FontColor":"FFFFFF","MainColor":"132238","AccentColor":"00BFFF","BackgroundColor":"0F1E34","OutlineColor":"0A1828"}') },
		['Forest Green'] 	= { 10, httpService:JSONDecode('{"FontColor":"D4D4D4","MainColor":"1F2A21","AccentColor":"228B22","BackgroundColor":"1B261D","OutlineColor":"182119"}') },
		['Crimson'] 		= { 11, httpService:JSONDecode('{"FontColor":"F0F0F0","MainColor":"251212","AccentColor":"DC143C","BackgroundColor":"200F0F","OutlineColor":"1A0C0C"}') },
		['Gold Rush'] 		= { 12, httpService:JSONDecode('{"FontColor":"000000","MainColor":"FFD700","AccentColor":"DAA520","BackgroundColor":"F2C400","OutlineColor":"C49A00"}') },
		['Matrix'] 		= { 13, httpService:JSONDecode('{"FontColor":"39FF14","MainColor":"0A0A0A","AccentColor":"00FF00","BackgroundColor":"000000","OutlineColor":"030303"}') },
		['Solar Flare'] 	= { 14, httpService:JSONDecode('{"FontColor":"FDFDFD","MainColor":"121212","AccentColor":"FF4500","BackgroundColor":"0E0E0E","OutlineColor":"151515"}') },
		['Monokai'] 		= { 15, httpService:JSONDecode('{"FontColor":"F8F8F2","MainColor":"272822","AccentColor":"F92672","BackgroundColor":"1E1E1E","OutlineColor":"141414"}') },
		['Pastel Pink'] 	= { 16, httpService:JSONDecode('{"FontColor":"333333","MainColor":"FFE4E1","AccentColor":"FF69B4","BackgroundColor":"FFF0F5","OutlineColor":"F0E6EF"}') },
		['Charcoal'] 		= { 17, httpService:JSONDecode('{"FontColor":"AFAFAF","MainColor":"2C3E50","AccentColor":"3498DB","BackgroundColor":"233140","OutlineColor":"1C2630"}') },
	}

	function ThemeManager:ApplyTheme(theme)
		local customThemeData = self:GetCustomTheme(theme)
		local data = customThemeData or self.BuiltInThemes[theme]

		if not data then return end

		local scheme = data[2]
		for idx, col in next, customThemeData or scheme do
			self.Library[idx] = Color3.fromHex(col)
			
			if Options[idx] then
				Options[idx]:SetValueRGB(Color3.fromHex(col))
			end
		end

		self:ThemeUpdate()
	end

	function ThemeManager:ThemeUpdate()
		local options = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }
		for i, field in next, options do
			if Options and Options[field] then
				self.Library[field] = Options[field].Value
			end
		end

		self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor);
		self.Library:UpdateColorsUsingRegistry()
	end

	function ThemeManager:LoadDefault()		
		local theme = 'Default'
		local content = isfile(self.Folder .. '/themes/default.txt') and readfile(self.Folder .. '/themes/default.txt')

		local isDefault = true
		if content then
			if self.BuiltInThemes[content] then
				theme = content
			elseif self:GetCustomTheme(content) then
				theme = content
				isDefault = false;
			end
		elseif self.BuiltInThemes[self.DefaultTheme] then
		 	theme = self.DefaultTheme
		end

		if isDefault then
			Options.ThemeManager_ThemeList:SetValue(theme)
		else
			self:ApplyTheme(theme)
		end
	end

	function ThemeManager:SaveDefault(theme)
		writefile(self.Folder .. '/themes/default.txt', theme)
	end

	function ThemeManager:CreateThemeManager(groupbox)
        groupbox:AddDivider()
		groupbox:AddLabel('Background color'):AddColorPicker('BackgroundColor', { Default = self.Library.BackgroundColor });
		groupbox:AddLabel('Main color')	:AddColorPicker('MainColor', { Default = self.Library.MainColor });
		groupbox:AddLabel('Accent color'):AddColorPicker('AccentColor', { Default = self.Library.AccentColor });
		groupbox:AddLabel('Outline color'):AddColorPicker('OutlineColor', { Default = self.Library.OutlineColor });
		groupbox:AddLabel('Font color')	:AddColorPicker('FontColor', { Default = self.Library.FontColor });

		local ThemesArray = {}
		for Name, Theme in next, self.BuiltInThemes do
			table.insert(ThemesArray, Name)
		end

		table.sort(ThemesArray, function(a, b) return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1] end)

		groupbox:AddDivider()
		groupbox:AddDropdown('ThemeManager_ThemeList', { Text = 'Theme list', Values = ThemesArray, Default = 1 })

		groupbox:AddButton('Set as default', function()
			self:SaveDefault(Options.ThemeManager_ThemeList.Value)
			self.Library:Notify(string.format('Set default theme to %q', Options.ThemeManager_ThemeList.Value))
		end)

		Options.ThemeManager_ThemeList:OnChanged(function()
			self:ApplyTheme(Options.ThemeManager_ThemeList.Value)
		end)

		groupbox:AddDivider()
		groupbox:AddDropdown('ThemeManager_CustomThemeList', { Text = 'Custom themes', Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 })
		groupbox:AddInput('ThemeManager_CustomThemeName', { Text = 'Custom theme name' })

		groupbox:AddButton('Load theme', function() 
			self:ApplyTheme(Options.ThemeManager_CustomThemeList.Value) 
		end):AddButton('Save theme', function() 
			self:SaveCustomTheme(Options.ThemeManager_CustomThemeName.Value)

			Options.ThemeManager_CustomThemeList.Values = self:ReloadCustomThemes()
			Options.ThemeManager_CustomThemeList:SetValues()
			Options.ThemeManager_CustomThemeList:SetValue(nil)
		end)

		groupbox:AddButton('Refresh list', function()
			Options.ThemeManager_CustomThemeList.Values = self:ReloadCustomThemes()
			Options.ThemeManager_CustomThemeList:SetValues()
			Options.ThemeManager_CustomThemeList:SetValue(nil)
		end)

		groupbox:AddButton('Set as default', function()
			if Options.ThemeManager_CustomThemeList.Value ~= nil and Options.ThemeManager_CustomThemeList.Value ~= '' then
				self:SaveDefault(Options.ThemeManager_CustomThemeList.Value)
				self.Library:Notify(string.format('Set default theme to %q', Options.ThemeManager_CustomThemeList.Value))
			end
		end)

		ThemeManager:LoadDefault()

		local function UpdateTheme()
			self:ThemeUpdate()
		end

		Options.BackgroundColor:OnChanged(UpdateTheme)
		Options.MainColor:OnChanged(UpdateTheme)
		Options.AccentColor:OnChanged(UpdateTheme)
		Options.OutlineColor:OnChanged(UpdateTheme)
		Options.FontColor:OnChanged(UpdateTheme)
	end

	function ThemeManager:GetCustomTheme(file)
		local path = self.Folder .. '/themes/' .. file
		if not isfile(path) then
			return nil
		end

		local data = readfile(path)
		local success, decoded = pcall(httpService.JSONDecode, httpService, data)
		
		if not success then
			return nil
		end

		return decoded
	end

	function ThemeManager:SaveCustomTheme(file)
		if file:gsub(' ', '') == '' then
			return self.Library:Notify('Invalid file name for theme (empty)', 3)
		end

		local theme = {}
		local fields = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }

		for _, field in next, fields do
			theme[field] = Options[field].Value:ToHex()
		end

		writefile(self.Folder .. '/themes/' .. file .. '.json', httpService:JSONEncode(theme))
	end

	function ThemeManager:ReloadCustomThemes()
		local list = listfiles(self.Folder .. '/themes')

		local out = {}
		for i = 1, #list do
			local file = list[i]
			if file:sub(-5) == '.json' then
				local pos = file:find('.json', 1, true)
				local char = file:sub(pos, pos)

				while char ~= '/' and char ~= '\\' and char ~= '' do
					pos = pos - 1
					char = file:sub(pos, pos)
				end

				if char == '/' or char == '\\' then
					table.insert(out, file:sub(pos + 1))
				end
			end
		end

		return out
	end

	function ThemeManager:SetLibrary(lib)
		self.Library = lib
	end

	function ThemeManager:BuildFolderTree()
		local paths = {}

		local parts = self.Folder:split('/')
		for idx = 1, #parts do
			paths[#paths + 1] = table.concat(parts, '/', 1, idx)
		end

		table.insert(paths, self.Folder .. '/themes')
		table.insert(paths, self.Folder .. '/settings')

		for i = 1, #paths do
			local str = paths[i]
			if not isfolder(str) then
				makefolder(str)
			end
		end
	end

	function ThemeManager:SetFolder(folder)
		self.Folder = folder
		self:BuildFolderTree()
	end

	function ThemeManager:CreateGroupBox(tab)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		return tab:AddLeftGroupbox('Themes')
	end

	function ThemeManager:ApplyToTab(tab)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		local groupbox = self:CreateGroupBox(tab)
		self:CreateThemeManager(groupbox)
	end

	function ThemeManager:ApplyToGroupbox(groupbox)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		self:CreateThemeManager(groupbox)
	end

	ThemeManager:BuildFolderTree()
end
return ThemeManager
