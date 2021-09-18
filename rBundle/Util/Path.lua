--[[
	
	Path
	@author	AstrealDev
	@desc	Manipulate paths (strings with a delimeter of /) similar to path.js
	
]]

local Path = {}

local Inspect = require(script.Parent.Inspect)
local Logger = require(script.Parent.Logger)

local extensionClasses = {
	['.lua'] = 'ModuleScript',
	['.server.lua'] = 'Script',
	['.client.lua'] = 'LocalScript',
	['.json'] = 'ModuleScript'
}

local function validateString(str: string)
	if typeof(str) ~= 'string' then
		Logger.error('Failed to validate %s as a string', str)
		return true
	end
end

local function isSeparator(char: string)
	return char == '/'
end

local function isFile(name: string)
	return string.match(name, '%.')
end

local function processFileName(name: string)
	local s = string.split(name, '.')
	local x = s[1]
	table.remove(s, 1)
	return x, '.' .. table.concat(s, '.')
end

local function instantiateScript(of: string, name: string, parent: Instance, source: string?)
	local s = Instance.new(of)
	s.Name = name
	s.Parent = parent
	s.Source = source or ''
	return s
end

--[[
	Parse a path extracting significant features
	of the path
	
	@example
		path.parse('hello/world/test.lua')
		@return {
			dir = 'hello/world',
			base = 'test.lua',
			ext = '.lua',
			name = 'test'
		}
]]
function Path.parse(path: string)
	if validateString(path) then return end
	
	local ret = { dir = '', base = '', ext = '', name = '' }
	
	local len = string.len(path)
	
	-- Process an empty path
	if len == 0 then
		return ret
	end
	
	-- Remove a separator suffix
	if isSeparator(string.sub(path, len, len)) then
		path = string.sub(path, 1, len - 1)
	end
	
	-- Remove a separator prefix
	if isSeparator(string.sub(path, 1, 1)) then
		path = string.sub(path, 2)
	end
	
	local split = string.split(path, '/')
	
	-- Parse the path
	for i, str in ipairs(split) do
		if isFile(str) then
			ret.base, ret.name, ret.ext = str, processFileName(str)
			break
		else
			ret.dir = ret.dir .. str .. '/'
		end
	end
	
	-- Remove trailing separator on dir
	ret.dir = string.sub(ret.dir, 1, string.len(ret.dir) - 1)
	
	return ret
end

--[[
	Process a path
	
	@example
		Path.process('hello/world.lua', workspace, 'print("Hello!")')
		@return world, true
		Generates
		- hello
			- world.lua
]]
function Path.process(path: string, root: Instance, content: string?)
	local data = Path.parse(path)
	local generated = false
	
	-- Process the directory path
	if data.dir ~= '' then
		for _, dir in pairs(string.split(data.dir, '/')) do
			local child = root:FindFirstChild(dir)
			if child then
				root = child
			else
				local directory = Instance.new('Folder')
				directory.Name = dir
				directory.Parent = root
				root = directory
				generated = true
			end
		end
	end
	
	-- Process the file
	if data.base ~= '' then
		local file = root:FindFirstChild(data.name)
		if file == nil then
			if data.ext == '.lua' then
				return instantiateScript(extensionClasses[data.ext], data.name, root, content), true
			elseif data.ext == '.server.lua' then
				return instantiateScript(extensionClasses[data.ext], data.name, root, content), true
			elseif data.ext == '.client.lua' then
				return instantiateScript(extensionClasses[data.ext], data.name, root, content), true
			elseif data.ext == '.json' then
				return instantiateScript(extensionClasses[data.ext],
					data.name,
					root,
					'return ' .. Inspect(game:GetService('HttpService'):JSONDecode(content))),
					true
			end
		else
			return file, generated
		end
	else
		return root, generated
	end
end

--[[
	Determine if the path is already instanced
	
	@example
		Path.exists('foo/bar/foobar.lua', workspace)
		@return true
	
	@example
		Path.exists('foo/bar/foofoo.lua', workspace)
		@return false, 'bar'
]]
function Path.exists(path: string, root: Instance)
	local data = Path.parse(path)
	
	-- Check directory path
	if data.dir ~= '' then
		for _, dir in pairs(string.split(data.dir, '/')) do
			local child = root:FindFirstChild(dir)
			if child then
				root = child
			else
				return false, dir
			end
		end
	end
	
	-- Check file
	if data.base ~= '' then
		local file = root:FindFirstChild(data.name)
		if file == nil then
			return false, data.name
		end
	end
	
	return true
end

--[[
	Generate a path string from an instance
]]
function Path.fromInstance(inst: Instance)
	if typeof(inst) ~= 'Instance' then
		Logger.error('Expected an instance')
		return
	end
	
	local fullName = inst:GetFullName()
	local split = string.split(fullName, '.')
	
	if not inst:IsA('Folder') then
		local ext
		for k, v in pairs(extensionClasses) do
			if v == inst.ClassName then
				ext = k
				break
			end
		end
		if ext then
			split[#split] = split[#split] .. ext
		end
	end
	
	return table.concat(split, '/')
end

return Path