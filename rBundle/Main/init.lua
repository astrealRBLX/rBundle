local Util = script.Parent.Util

local Path = require(Util.Path)
local CLI = require(script.CLI)
CLI.plugin = plugin

function main()
	-- Provide access to rBundle globally
	shared.rBundle = CLI
	
	-- Default installation directory
	if CLI.getDirectory() == nil then
		local f = game:GetService('ReplicatedStorage'):FindFirstChild('Bundles') or Instance.new('Folder')
		f.Name = 'Bundles'
		f.Parent = game:GetService('ReplicatedStorage')
		CLI.setDirectory(f)
	end
end

if not game:GetService('RunService'):IsRunning() then
	main()
end