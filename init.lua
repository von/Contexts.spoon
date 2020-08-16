--- === Contexts ===
--- Allow defining contexts and switching between them.
--- A context is a set of windows around hs.layout and other
--- state.

local Contexts = {}


-- Metadata
Contexts.name="Contexts"
Contexts.version="0.1"
Contexts.author="Von Welch"
-- https://opensource.org/licenses/Apache-2.0
Contexts.license="Apache-2.0"
Contexts.homepage="https://github.com/von/Contexts.spoon"

-- debug() {{{ --
--- Contexts:debug(enable)
--- Method
--- Enable or disable debugging
---
--- Parameters:
---  * enable - Boolean indicating whether debugging should be on
---
--- Returns:
---  * Nothing
function Contexts:debug(enable)
  if enable then
    self.log.setLogLevel('debug')
    self.log.d("Debugging enabled")
  else
    self.log.d("Disabling debugging")
    self.log.setLogLevel('info')
  end
end
-- }}}  debug() --

-- init() {{{ --
--- Contexts:init()
--- Method
--- Initializes a Contexts
--- When a user calls hs.loadSpoon(), Hammerspoon will load and execute init.lua
--- from the relevant s.
--- Do generally not perform any work, map any hotkeys, start any timers/watchers/etc.
--- in the main scope of your init.lua. Instead, it should simply prepare an object
--- with methods to be used later, then return the object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Contexts object

function Contexts:init()
  -- Failed table lookups on the instances should fallback to the class table, to get methods
  self.__index = self

  -- Calls to Contexts return Contexts.new()
  setmetatable(self, {
    __call = function (cls, ...)
      return cls.new(...)
    end,
  })

  -- Set up logger for spoon
  self.log = hs.logger.new("Contexts")

  -- Path to this file itself
  -- See also http://www.hammerspoon.org/docs/hs.spoons.html#resourcePath
  self.path = hs.spoons.scriptPath()

  -- Current active context and the prior one, used by previous()
  self.current = nil
  self.previous = nil

  -- List of created contexts for chooser()
  self.contexts = {}

  return self
end
-- }}} init() --

-- bindHotKeys() {{{ --
--- Contexts:bindHotKeys(table)
--- Method
--- The method accepts a single parameter, which is a table. The keys of the table
--- are strings that describe the action performed, and the values of the table are
--- tables containing modifiers and keynames/keycodes. E.g.
---   {
---     chooser = {{"cmd", "alt"}, "c"},
---     previous = {{"cmd", "alt"}, "p"}
---    }
---
---
--- Parameters:
---  * table - Table of action to key mappings
---
--- Returns:
---  * Contexts object

function Contexts:bindHotKeys(table)
  for feature,mapping in pairs(table) do
    if feature == "chooser" then
      hs.hotkey.bind(mapping[1], mapping[2], function() self:chooser() end)
    elseif feature == "previous" then
      hs.hotkey.bind(mapping[1], mapping[2], function() self:previous() end)
    else
      self.log.wf("Unrecognized key binding feature '%s'", feature)
    end
  end
  return self
end
-- }}} bindHotKeys() --

-- new() {{{ --
--- Contexts.new()
--- Function
--- Create a new Contexts instance
---
--- Parameters:
--- * config: A table containing the following keys:
---   * title (string) [Required]: Title of context for display to user
---   * layout (table) [Optional]: A table suitable for use with hs.layout.apply
---   * enterFunction (function) [Optional]: A function called when context is applied
---   * exitFunction (function) [Optional]: A function called when context is exited
---
--- Returns:
--- * Contexts instance
function Contexts.new(config)
  Contexts.log.df("new context %s created", config.title)
  local self = setmetatable({}, Contexts)
  self.config = config
  -- TODO: Add a delete() method that removes from contexts
  table.insert(Contexts.contexts, self)
  return self
end
-- }}} new() --

-- {{{ apply() --
--- Contexts:apply()
--- Method
--- Apply given context.
---
--- Parameters:
--- * None
---
--- Returns:
--- * true on success, false on failure
function Contexts:apply()
  if not self.config then
    self.log.w("Context:apply() called with no configuation")
    return false
  end

  if Contexts.current then
    -- Don't unapply current context if we're switching to it.
    -- Not sure this is right, but trying this.
    if Contexts.current == self then
      self.log.df("Changing to current context. Not unapplying.")
    else
      if not Contexts.current:unapply() then
        return false
      end
    end
  end
  Contexts.current = self

  local title = self.config.title
  self.log.df("Applying context %s", title)

  if self.config.enterFunction then
    local ok, err = pcall(self.config.enterFunction)
    if not ok then
      self.log.ef("Context %s: enterFunction() returned error: %s", title, err)
      return false
    end
  end

  if self.config.layout then

    -- Make sure all the applications in layout are running
    -- and all the windows are unminimized
    hs.fnutils.map(self.config.layout,
      function(rule)
        local appName = rule[1]
        local app = hs.application.get(appName)
        -- Use get() as it requires an exact match
        if app == nil then
          self.log.df("Launching application %s", app)
          if not hs.application.launchOrFocus(appName) then
            self.log.ef("Error launch application %s", appName)
          end
        else
          local winName = rule[2]
          if type(winName) == "string" then
            local win = app:findWindow(winName)
            if win then
              win:unminimize()
            end
          elseif type(winName) == "function" then
            local win = winName()
            if win then
              win:unminimize()
            end
          else  -- nil
            -- Unminimize all windows
            hs.fnutils.map(app:allWindows(), function(w) w:unminimize() end)
          end
        end
      end)

    self.log.df("Applying layout")
    -- XXX There is a race condition in that apps we have launched above
    -- are unlikely to be running yet.
    hs.layout.apply(self.config.layout)
  end

  return true
end
-- }}} apply() --

-- unapply() {{{ --
--- Contexts:unapply()
--- Method
--- Unapply context.
---
--- Parameters:
--- * None
---
--- Returns:
--- * true on success, false on error
function Contexts:unapply()
  if self.config.exitFunction then
    local ok, err = pcall(self.config.exitFunction)
    if not ok then
      self.log.ef("Context %s: exitFunction() returned error: %s", self.config.title, err)
      return false
    end
  end

  Contexts.previous = self
  Contexts.current = nil

  return true
end
-- }}} unapply() --

-- applyPrevious() {{{ --
--- Contexts:applyPrevious()
--- Method
--- Switch to previous context stored in Contexts.previous by unapply()
---
--- Parameters:
--- * None
---
--- Returns:
--- * true on success, false on error

function Contexts:applyPrevious()
  if Contexts.previous then
    Contexts.previous:apply()
  else
    hs.alert("No previous context")
  end
end

-- }}} applyPrevious() --

-- chooser() {{{ --
--- Contexts:chooser()
--- Method
--- Display a hs.chooser with all contexts and apply selected.
---
--- Parameters:
--- * None
---
--- Returns:
--- * Nothing
function Contexts:chooser()
  -- Contexts instances don't convert into NSObjects so we can't include them
  -- in choices
  local choices = hs.fnutils.map(
    Contexts.contexts,
    function(c) return { text = c.config.title } end)
  table.sort(choices, function(a,b) return a.text:lower() < b.text:lower() end)

  local function callback(choice)
    if choice then
      self.log.df("Context %s chosen", choice.text)
      local context = hs.fnutils.find(
        Contexts.contexts,
        function(c) return c.config.title == choice.text end)
      if not context then
        self.log.ef("Could not find chosen context %s", choice.text)
        return
      end
      context:apply()
    else
      self.log.d("Choice is nil")
    end
  end

  local chooser = hs.chooser.new(callback)
  chooser:choices(choices)
  self.log.d("Launching chooser")
  chooser:show()
end
-- }}} chooser() --

return Contexts
-- vim:foldmethod=marker:
