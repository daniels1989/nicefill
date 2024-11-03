if not string.starts_with then
	---@param haystack string
	---@param needle string
	---@return boolean
	function string.starts_with(haystack, needle)
		return string.sub(haystack, 1, string.len(needle)) == needle
	end
end

if not string.ends_with then
	---@param haystack string
	---@param needle string
	---@return boolean
	function string.ends_with(haystack, needle)
		return string.sub(haystack, string.len(needle) * -1) == needle
	end
end