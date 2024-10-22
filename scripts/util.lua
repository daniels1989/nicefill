function string.starts(haystack, needle)
	return string.sub(haystack, 1, string.len(needle)) == needle
end

function string.ends(haystack, needle)
	return string.sub(haystack, string.len(needle) * -1) == needle
end

function math.absfloor(x)
	if x > 0 then
		return math.floor(x)
	end

	return math.ceil(x)
end

function math.round(a)
	return math.floor(a + 0.5)
end