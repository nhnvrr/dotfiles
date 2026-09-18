--- The default browser: checked on every load, never silently assumed.
---
--- macOS 27 does not let a third party set the http/https handler. The
--- deprecated LSSetDefaultHandlerForURLScheme that hs.urlevent.setDefaultHandler
--- and duti both call is accepted and then ignored — it returns no error and
--- getDefaultHandler still answers with the old browser — because the only
--- supported path now is the browser asking for itself through NSWorkspace,
--- which is what puts up the "change your default browser?" dialog. Measured on
--- 27.0 (26A5425a), in both directions so it is the API and not one app. The
--- other app in the table is Helium, which is what this config placed when the
--- measurement was taken; the finding is about LaunchServices, not about either
--- browser:
---
---   handler was Chrome   setDefaultHandler("http", helium)   ──► still Chrome
---   handler was Helium   setDefaultHandler("http", chrome)   ──► still Helium
---   duti -s net.imput.helium http all                        ──► error -50
---   duti -s net.imput.helium public.html all                 ──► no change
---
--- So the attempt stays — it costs nothing and is the supported call on the
--- macOS versions that still honour it — but the result is verified, and a
--- handler that is not the browser this config places gets said out loud. That
--- is the whole point: the failure mode this replaces was silent.

local apps = require("mate.apps")

local M = {}

--- Case-insensitive, because getDefaultHandler answers with whatever casing
--- LaunchServices has on file rather than the casing that went in.
local function sameBundle(a, b)
  return a ~= nil and b ~= nil and a:lower() == b:lower()
end

function M.ensureDefault()
  local bid = apps.bundles.defaultBrowser

  -- Without the app installed there is nothing to point at, and LaunchServices
  -- accepts the call anyway rather than failing.
  if not hs.application.infoForBundleID(bid) then
    hs.printf("mate.browser: %s is not installed; leaving the default handler alone", bid)
    return
  end

  for _, scheme in ipairs({ "http", "https" }) do
    if not sameBundle(hs.urlevent.getDefaultHandler(scheme), bid) then
      hs.urlevent.setDefaultHandler(scheme, bid)
    end
  end

  local current = hs.urlevent.getDefaultHandler("http")
  if sameBundle(current, bid) then return end

  local name = hs.application.nameForBundleID(bid) or bid
  hs.printf("mate.browser: default http handler is %s, not %s", tostring(current), bid)
  hs.alert.show("⚠️  Default browser is not " .. name .. ".\n" ..
    "System Settings → Desktop & Dock → Default web browser",
    { textSize = 18 }, 8)
end

return M
