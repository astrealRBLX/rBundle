local Logger = {
	Prefix = '[rBundle]'
}

local TestService = game:GetService('TestService')

local function f(str: string, ...)
	return string.format(str, ...)
end

function Logger.error(...)
	TestService:Error(f('%s %s', Logger.Prefix, f(...)))
end

function Logger.info(...)
	TestService:Message(f('%s %s', Logger.Prefix, f(...)))
end

return Logger