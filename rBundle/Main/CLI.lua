local CLI = {}

local HTTP = game:GetService('HttpService')

local Util = script.Parent.Parent.Util
local Path = require(Util.Path)
local Logger = require(Util.Logger)

local function f(str: string, ...)
	return string.format(str, ...)
end

local function validateGitHubToken()
	local storedToken = CLI.getToken()
	if storedToken then
		return storedToken
	else
		Logger.error('No GitHub token is currently set')
	end
end

local function resolveRepoEntry(str: string)
	local s = string.split(str, '/')
	return s[1], s[2]
end

local function rerequire(inst: Instance)
	local new = inst:Clone()
	new.Parent = inst.Parent
	inst.Parent = nil
	local data = require(new)
	inst.Parent = new.Parent
	new:Destroy()
	return data
end

--[[
	Install one or multiple repositories
	using rBundle
	
	@example
		CLI.install('astrealrblx/testing')
	
	@example
		CLI.install({'astrealrblx/testing', 'astrealrblx/volt'})

]]
function CLI.install(entries: string | { string })
	if typeof(entries) == 'string' then
		entries = { entries }
	end
	
	if not validateGitHubToken() then return end
	
	local installed = 0
	
	-- Install
	for _, entry in ipairs(entries) do
		local user, repo = resolveRepoEntry(entry)
		if user and repo then
			local suc, res = pcall(function()
				print('')
				Logger.info("Attempting to install '%s'", entry)
				
				-- Access Glitch endpoint
				local success, result = pcall(function()
					return HTTP:JSONDecode(
						HTTP:GetAsync('https://rbundle-endpoint.glitch.me/' .. entry, nil, {
							Token = CLI.getToken()
						})
					)
				end)
				
				if not success then
					error(result)
				end
				
				Logger.info("Repository '%s' data downloaded...", entry)
				
				-- Extract latest bundle.json data
				local latestBundle
				for _, file in pairs(result) do
					local path = Path.parse(file.path)
					if path.base == 'bundle.json' then
						latestBundle = HTTP:JSONDecode(file.data)

						break
					end
				end
				
				-- Validate bundle.json
				if latestBundle == nil then
					error('Repository is missing a bundle.json')
				elseif latestBundle.name == nil then
					error("bundle.json is missing a 'name' field")
				elseif latestBundle.id == nil then
					error("bundle.json is missing an 'id' field")
				elseif latestBundle.version == nil then
					error("bundle.json is missing a 'version' field")
				end
				
				-- Default src
				if latestBundle.src == nil then
					latestBundle.src = ''
				end
				
				local src = Path.parse(repo .. '/' .. latestBundle.src)
				
				Logger.info("Resolved '%s' bundle.json...", entry)
				
				-- Preprocessing
				local localBundleCreated
				for _, file in pairs(result) do
					file.path = repo .. file.path
					local path = Path.parse(file.path)
					if path.base == 'bundle.json' then
						x, localBundleCreated = Path.process(file.path, CLI.getDirectory(), file.data)
						if localBundleCreated then
							x:Destroy()
						end
					end
				end
				
				-- Bundle comparison
				if localBundleCreated == false then
					local localBundle = CLI.getDirectory():FindFirstChild(repo):FindFirstChild('bundle')
					if localBundle then
						-- Ensure the data is up to date
						local localBundleData = rerequire(localBundle)

						Logger.info("Previous installation of '%s' (%s) located", entry, localBundleData.version)

						if localBundleData.version ~= latestBundle.version then
							warn(string.format("Mismatching versions of '%s' (installed: %s, latest: %s)", entry, localBundleData.version, latestBundle.version))
						end
					end
				end
				
				-- Build
				local created = 0
				for _, file in pairs(result) do
					local path = Path.parse(file.path)
					if path.base == 'bundle.json' or string.find(path.dir, src.dir .. '(.*)') then
						local x, built = Path.process(file.path, CLI.getDirectory(), file.data)
						if built then
							created += 1
						end
					end
				end
				
				Logger.info('Built %d files', created)
				
				local repoDir = CLI.getDirectory():FindFirstChild(repo)
				
				-- Postprocessing
				for _, child in pairs(repoDir:GetDescendants()) do
					if child.Name == 'init' and not child:IsA('Folder') then
						for _, deepChild in pairs(child.Parent:GetChildren()) do
							if deepChild ~= child then
								deepChild.Parent = child
							end
						end
						child.Name = child.Parent.Name
						child.Parent.Name = '__processed'
						child.Parent = child.Parent.Parent
						child.Parent:FindFirstChild('__processed'):Destroy()
					end
				end
			end)
			
			if suc then
				installed += 1
				Logger.info("Successfully installed '%s'", entry)
				print('')
			else
				Logger.error("Failed to install '%s': %s", entry, res)
			end
		else
			Logger.error("Unable to install '%s': Repository source should be formatted as 'owner/repository'", entry)
		end
	end
	
	Logger.info('Finished installing all bundles (%d/%d)', installed, #entries)
end

--[[
	List installed bundles
	
	@example
		CLI.list()
]]
function CLI.list()
	local dir = CLI.getDirectory()
	
	Logger.info('Installed bundles:')
	
	local bundleCount = 0
	for _, bundle in pairs(dir:GetChildren()) do
		local bundleData = bundle:FindFirstChild('bundle')
		if bundleData then
			bundleCount += 1
			bundleData = rerequire(bundleData)
			Logger.info('\t• %s (%s) @ %s', bundleData.name, bundleData.id, bundleData.version)
		end
	end
	
	Logger.info('Listing %d bundle(s)', bundleCount)
end

--[[
	Get info about a locally installed bundle
	
	@example
		CLI.info('testing')
]]
function CLI.info(id: string)
	local dir = CLI.getDirectory()
	
	local foundBundleData
	for _, bundle in pairs(dir:GetChildren()) do
		local bundleData = bundle:FindFirstChild('bundle')
		if bundleData then
			bundleData = rerequire(bundleData)
			if bundleData.id == id then
				foundBundleData = bundleData
			end
		end
	end
	
	if foundBundleData then
		Logger.info('%s (%s) @ %s', foundBundleData.name, foundBundleData.id, foundBundleData.version)
		if foundBundleData.description then
			Logger.info('Description: %s', foundBundleData.description)
		end
	else
		Logger.info("No bundle found with id '%s'", id)
	end
	
end

--[[
	Set a GitHub token

	@example
		CLI.setToken('my-token')
]]
function CLI.setToken(token: string)
	if typeof(token) ~= 'string' then
		Logger.error('Token must be a string')
		return
	end
	
	if string.sub(token, 1, 4) ~= 'ghp_' then
		Logger.error('Provided an invalid GitHub token')
		return
	end
	
	CLI.plugin:SetSetting('rbundle-gh-token', token)
	Logger.info('Successfully set GitHub token')
end

--[[
	Get current GitHub token
	
	@example
		CLI.getToken()
]]
function CLI.getToken()
	return CLI.plugin:GetSetting('rbundle-gh-token')
end

--[[
	Set a bundle installation directory

	@example
		CLI.setDirectory(workspace)
]]
function CLI.setDirectory(dir: Instance)
	if typeof(dir) ~= 'Instance' then
		Logger.error('Directory must be an instance')
		return
	end
	
	CLI.plugin:SetSetting('rbundle-directory', Path.fromInstance(dir))
	Logger.info('Successfully set bundle installation directory')
end

--[[
	Get the bundle installation directory
	
	@example
		CLI.getDirectory()
]]
function CLI.getDirectory()
	local dir = CLI.plugin:GetSetting('rbundle-directory')
	if dir then
		return Path.process(dir, game)
	end
end


return CLI