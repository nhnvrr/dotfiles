local M = {}

local function to_rgb(hex)
  hex = hex:gsub("#", "")
  return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
end

--- Blend `fg` toward `bg` by `alpha` (1 = fg untouched, 0 = bg).
function M.blend(fg, bg, alpha)
  local r1, g1, b1 = to_rgb(fg)
  local r2, g2, b2 = to_rgb(bg)
  local function ch(a, b)
    return math.floor(alpha * a + (1 - alpha) * b + 0.5)
  end
  return string.format("#%02x%02x%02x", ch(r1, r2), ch(g1, g2), ch(b1, b2))
end

return M
