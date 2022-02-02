--- === Contexts ===
--- Allow defining Contexts and switching between them.
--- A Context is based on a list of applications, each with optional filter for window names,
--- and a set of actions to be called with the Context is applied (or a screen change
--- is detected), or a new window for the application is created. The same application
--- can appear multiple times with different filters for window names.
---
--- Actions can be any of the following:
--- * A string starting with "screen:": the remainder of the string is the name of a screen,
---   which the window will be moved to if a screen matching the name is found.
--- * A string matching one of the following, in which case the window will be resized
---   as descripbed:
---     * `"maximize"`: window will be maximized as `hs.window:maximize()`
---     * `"minimize"`: window will be minimized as `hs.window:minimize()`
---     * `"left50"`: window will fill the left 50% of the screen
---     * `"right50"`: window will fill the right 50% of the screen
--- * Any other string will be passed to hs.geometry.new() and, if successfully in creating
---   a new `hs.geomtry` instance, the window will be resized to that instance.
---   One enhancement over standard geometry instances, is that negative `x` and `y` values
---   will be treated as offsets from the right and bottom side of the screen respectively.
--- * An `hs.geometry` instance: the window will be resized to that instance.
--- * An `hs.screen` instance: the window will be moved to the screen
--- * A function: the function will be called with a single parameter, the `hs.window`
---   instance of the window.
---
--- Additionally a Context allows for the following:
--- * Allows for functions that are called when the layout is applied
---   and unapplied.
--- * Allows setting the default input and output audio device.
---
--- Additionally, to allow for interactive selection of Contexts:
--- * The chooser() method creates a hs.chooser() instance to choose created layouts
--- * The sealUserActions() method creates user actions for the Seal spoon for each
---   created Context.
--- * A specific application/window to receive focus with the Context is applied.
---
--- If a screen is added or removed, a Context will be re-applied. Note that a change
--- in screen size doesn't trigger a reapplication (because OSX tends to move the Dock
--- between screens fairly regularly.)

local Contexts = {}

-- Metadata {{{ --
Contexts.name="Contexts"
Contexts.version="0.20"
Contexts.author="Von Welch"
-- https://opensource.org/licenses/Apache-2.0
Contexts.license="Apache-2.0"
Contexts.homepage="https://github.com/von/Contexts.spoon"
-- }}} Metadata --

-- Constants {{{ --
-- Table of gemetries used by _applyActions() for apply and friends
local geometry = {
  maximize = hs.geometry.new(0,0,1,1),
  left50 = hs.geometry.new(0,0,.5,1),
  right50 = hs.geometry.new(.5,0,.5,1)
}
-- }}} Constants --

-- debug() {{{ --
--- Contexts:debug(enable)
--- Function
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
--- Function
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

  -- Set up screen watcher
  self.screenWatcher = hs.screen.watcher.new(hs.fnutils.partial(Contexts.screenWatcherCallback, self))
  -- Guard to prevent re-entry into callback
  self.inScreenWatcherCallback = false

  -- List of screens so we can detect changes. Set by apply() and then reset when
  -- changed by screenwatcherCallback()
  self.screens = nil
  
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

-- start() {{{ --
--- Contexts:start()
--- Function
--- Start background activity.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Contexts object
function Contexts:start()
  self.screenWatcher:start()
  return self
end
-- }}} start() --

-- stop() {{{ --
--- Contexts:stop()
--- Function
--- Stop background activity.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Contexts object
function Contexts:stop()
  self.screenWatcher:stop()
  if self.current then
    self.current:unapply()
  end
  return self
end
-- }}} stop() --

-- screenWatcherCallback() {{{ --
--- Contexts:screenWatcherCallback()
--- Method
--- Callback (class method) for `self.screenWatcher`.
--- Determines if a screen has been added or removed and, if so, calls `apply()`
--- for the current Context. Prevents rentrance in case `apply()` causes
--- a screen change.
---
--- Parameters:
--- * None
---
--- Returns:
--- * Nothing
function Contexts:screenWatcherCallback()
  -- Prevent the handling of a screen change from spawning another
  -- handling of a screen change.
  if self.inScreenWatcherCallback then
    self.log.d("Screen change detected while processing screen change. Ignoring.")
  elseif self.current then
    self.log.d("Screen watcher callback called.")
    if not self:changeInScreens() then
      self.log.d("No change in screens detected.")
      return
    end
    self.inScreenWatcherCallback = true
    -- Wrap apply() so that if it fails, we unset inScreenWatcherCallback
    local result, errormsg = xpcall(
      -- true argument -> reapply
      function() self.current:apply(true) end,
        debug.traceback)
    if not result then
      self.log.ef("Error handling re-apply: %s", errormsg)
    end
    self.inScreenWatcherCallback = false
  end
end
-- }}} screenWatcherCallback() --

-- changeInScreens() {{{ --
--- Contexts:changeInScreens()
--- Method
--- Class method to determine if there has been a addition or removal of a screen
--- since the last time `apply()` was called.
---
--- Parameters:
--- * None
---
--- Returns:
--- * Boolean: True if screens have been added or removed since last time `apply()` was called.
---
function Contexts:changeInScreens()
  -- I don't think this should ever happen, but guard for it anyways.
  if self.screens == nil then
    self.log.d("self.screens == nil")
    return true
  end
  local screens = hs.screen.allScreens()
  self.log.d(hs.inspect(self.screens)) -- DEBUG
  self.log.d(hs.inspect(screens)) -- DEBUG
  if #screens ~= #self.screens then
    self.log.df("Number of screens has changed from %d to %d", #self.screens, #screens)
    return true
  end
  -- Same length, just make sure every current screens appears in our saved list
  if hs.fnutils.every(screens,
      function(s) return hs.fnutils.contains(self.screens, s) end) then
    self.log.d("Screens have not changed.")
    return false
  end
  self.log.d("Screen list does not match.")
  return true
end
-- }}} changeInScreens() --

-- bindHotKeys() {{{ --
--- Contexts:bindHotKeys(table)
--- Function
--- The method accepts a single parameter, which is a table. The keys of the table
--- are strings that describe the action performed, and the values of the table are
--- tables containing modifiers and keynames/keycodes. E.g.
---   {
---     chooser = {{"cmd", "alt"}, "c"},
---     previous = {{"cmd", "alt"}, "p"},
---     reapply = {{"cmd", "alt"}, "r"}
---    }
---
---
--- Parameters:
---  * mapping - Table of action to key mappings
---
--- Returns:
---  * Contexts object

function Contexts:bindHotKeys(mapping)
  local spec = {
    chooser = hs.fnutils.partial(self.chooser, self),
    previous = hs.fnutils.partial(self.previous, self),
    reapply = hs.fnutils.partial(self.reapply, self)
  }
  hs.spoons.bindHotkeysToSpec(spec, mapping)
  return self
end
-- }}} bindHotKeys() --

-- new() {{{ --
--- Contexts.new()
--- Constructor
--- Create a new Contexts instance
---
--- Parameters:
--- * config: A table containing the following keys:
---   * title (string) [Required]: Title of context for display to user
---   * inherits (Contexts instance) [Optional]: Context instance that will be invokes
---     before this instance. A chain of inheritances may be arbitrarily deep.
---   * image (hs.image) [Optional]: chooser() will use this image
---   * apps (list) [Optional]: A list of tables, each containing:
---     * name (string): Application name
---     * windowNames (string) [Optional]: only allow windows whose title matches the
---       pattern(s) as per string.match
---     * apply (list) [Optional]: A list of actions to apply to the application's
---       windows when the Context is applied. These are also applied when a screen
---       change is detected. See module description for details on Actions.
---     * create (list) [Optional]: A list of actions to apply to a new window
---       created for the application (and matching `windowNames` if given).
---   * enterFunction (function) [Optional]: A function called when context is applied
---   * exitFunction (function) [Optional]: A function called when context is exited
---   * focused (dictionary) [Optional]: Window to focus on. First element is application,
---     second optional element is window name.
---   * defaultInputDevice (table) [Optional]: List of strings identifying input audio
---     devices.  First input device found, will be set to the default.
---   * defaultOutputDevice (table) [Optional]: List of strings identifying output
---     audio devices. First output device found, will be set to the default.
---
--- Returns:
--- * Contexts instance
function Contexts.new(config)
  if not config then
    Contexts.log.e("new() called with nil configuration")
    return nil
  end
  Contexts.log.df("new context %s created", config.title)
  local self = setmetatable({}, Contexts)
  self.config = config

  -- Create window filters for each entry in config.apps
  if self.config.apps then
    hs.fnutils.each(self.config.apps, function(a)
      local logName = a.name
      if a.windowNames then
        logName = logName .. string.format(" (Windows: %s)", a.windowNames)
      end
      self.log.df("Creating window.filter for %s", logName)
      local filter = hs.window.filter.new(false)
      -- Allow any subrole of window
      local filterTable = { allowRoles = "*" }
      if a.windowNames then
        filterTable.allowTitles = a.windowNames
      end
      filter:setAppFilter(a.name, filterTable)
      if a.create then
        self.log.df("Subscribing to filter for %s: %s", logName, hs.inspect(filterTable))
        filter:subscribe(hs.window.filter.windowCreated,
          function(w)
            self.log.df("Creation detected: %s", logName)
            self:_applyActions(a.create, w)
          end)
      end
      a.wfilter = filter
    end)
  end

  -- TODO: Add a delete() method that removes from contexts
  table.insert(Contexts.contexts, self)
  return self
end
-- }}} new() --

-- getByTitle() {{{ --
--- Contexts.getByTitle()
--- Constructor
--- Given the title of a previous created Context, return its instance.
---
--- Parameters:
--- * title: Context title
---
--- Returns:
--- * Context instance, or nil if not found
function Contexts.getByTitle(title)
  local context = hs.fnutils.find(
    Contexts.contexts,
    function(c) return c.config.title == title end)
  return context
end
-- }}} getByTitle() --

-- {{{ apply() --
--- Contexts:apply()
--- Method
--- Apply given context:
---
--- 1) Calls `unapply()` on the previously applied context (unless we are reapplying)
---
--- 2) If this Context inherits from another Context, calls `apply()` on that Context.
---
--- Following is handled by `_apply()`:
---
--- 3) Calls config.enterFunction() if present and not reapplying
---
--- 4) For each entry in `apps` that has an `apply` action list defined, apply
---    those actions to each relevant window. See module description for details.
---
--- 5) Focuses the window given in config.focused if not reapplying.
---
--- 6) Sets the default input device found in defaultInputDevice
---
--- 7) Sets the default output device found in defaultOutputDevice
---
--- Parameters:
--- * reapply [optional]: True if we are re-applying a context.
---
--- Returns:
--- * true on success, false on failure
function Contexts:apply(reapply)
  if not self.config then
    self.log.w("Context:apply() called with no configuation")
    return false
  end

  if not reapply then
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
  end

  -- Save list of current screens so screenWatcherCallback() can detect changes.
  Contexts.screens = hs.screen.allScreens()

  return self:_apply(reapply)
end
-- }}} apply() --

-- _apply() {{{ --
--- Context:_apply()
--- Internal Function
--- Handle the work of applying given Context. See apply() for details.
--- Can be called recursively to handle inherited Contexts. One-time
--- activities should be handled by apply()
---
--- Parameters:
--- * reapply [optional]: If true, we are reapplying a context.
---
--- Returns:
--- * true on success, false on failure
function Contexts:_apply(reapply)

  if self.config.inherits then
    self.log.df("Applying inherited context...")
    self.config.inherits:_apply(reapply)
  end

  local title = self.config.title
  if reapply then
    self.log.df("Re-applying context %s", title)
  else
    self.log.df("Applying context %s", title)
  end

  if not reapply and self.config.enterFunction then
    local ok, err = pcall(self.config.enterFunction, debug.traceback)
    if not ok then
      self.log.ef("Context %s: enterFunction() returned error: %s", title, err)
      return false
    end
  end

  if self.config.apps then
    hs.fnutils.each(self.config.apps, function(a)
      if a.apply then
        local windows = a.wfilter:getWindows()
        if #windows > 0 then
          self.log.df("%s: Calling %d apply elements for %d windows",
            a.name, #a.apply, #windows)
          hs.fnutils.each(windows, function(w) self:_applyActions(a.apply, w) end)
        end
      end
    end)
    if not reapply then
      self.log.df("Enabling window filter subscriptions")
      hs.fnutils.each(self.config.apps, function(a) a.wfilter:resume() end)
    end
  end

  if not reapply and self.config.focused then
    local appName = self.config.focused[1]
    local winName = self.config.focused[2]
    local app = hs.application.get(appName)
    if app then
      local win = winName and app:getWindow(winName) or app:mainWindow()
      if win then
        self.log.df("Focusing: %s", win:title())
        win:focus()
      else
        self.log.df("Cannot focus on %s/%s: window not found.", appName, winName)
      end
    else
      self.log.df("Cannot focus on %s/%s: app not found.", appName, winName)
    end
  end

  if self.config.defaultInputDevice then
    for i,device in pairs(self.config.defaultInputDevice) do
      local dev = hs.audiodevice.findInputByName(device)
      if dev and dev:setDefaultInputDevice() then
        self.log.df("Default input device set: %s", device)
        break
      end
    end
  end

  if self.config.defaultOutputDevice then
    for i,device in pairs(self.config.defaultOutputDevice) do
      local dev = hs.audiodevice.findOutputByName(device)
      if dev and dev:setDefaultOutputDevice() then
        self.log.df("Default output device set: %s", device)
        break
      end
    end
  end

  return true
end
-- }}} _apply() --

-- _applyActions() {{{ --
--- Contexts:_applyActions()
--- Internal Function
--- Given a list of actions as described in apply(), apply them in turn to given
--- window.
---
--- Parameters:
--- * list: List of actions as described in apply()
--- * window: hs.window instance
---
--- Returns:
--- * Nothing
function Contexts:_applyActions(list, window)
  hs.fnutils.each(list, function(action)
    local atype = type(action)
    if atype == "string" then
      self.log.df("Action string: %s", action)
      if action:sub(1, 7) == "screen:" then
        -- Preferred screens, comma-separated in order
        local screen = nil
        local screens = hs.screen.allScreens()
        for sname in string.gmatch(action:sub(8), '([^,]+)') do
          screen = hs.fnutils.find(screens, function(s) return s:name() == sname end)
          if screen then
            self:_applyScreen(screen, window)
            break
          end
        end
        if screen == nil then
          self.log.df("No matching screen found: %s", action:sub(8))
        end
      elseif action == "minimize" then
        self.log.d("Minimzing window")
        window:minimize()
      else
        -- Geometry
        local geometry = geometry[action] or hs.geometry.new(action)
        if geometry then
          self:_applyGeometry(geometry, window)
        else
          self.log.ef("Failed to parse action: %s", action)
        end
      end
    elseif atype == "hs.geometry" then
      self:_applyGeometry(action, action)
    elseif atype == "hs.screen" then
      self:_applyScreen(window, action)
    elseif atype == "function" then
      -- Will print a unique address of function
      self.log.df("Calling %s on window %s", action, window:title())
      action(window)
    elseif atype == "nil" then
      self.log.e("Nil action")
    else
      self.log.ef("Unrecognized action: %s", hs.inspect(action))
    end
    end)
end
-- }}} _applyActions() --

-- _applyGeometry() {{{ --
--- Contexts:_applyGeometry()
--- Internal Function
--- Resize given window with given geometry. Handles different types of geometries.
--- If a geometry instance has a negative `x` or `y` value, that value is treated
--- as an offset from the right or bottom of the screen respectively.
---
--- Parameters:
--- * geometry: hs.geometry instance
--- * window: hs.window instance
---
--- Returns:
--- * Nothing
function Contexts:_applyGeometry(geometry, window)
  local type = geometry:type()
  local screenFrame = window:screen():frame()
  -- hs.geometry seems to do a good job of providing a string
  self.log.df("Applying geometry: %s", geometry)
  if type == "point" or type == "rect" then
    -- Make negative x and y coordinates relative from lower right corner
    if geometry.x < 0 then
      geometry.x = screenFrame.w + geometry.x
    end
    if geometry.y < 0 then
      geometry.y = screenFrame.h + geometry.y
    end
    window:move(geometry)
  elseif type =="unitrect" then
    window:move(geometry)
  elseif type == "size" then
    window:setSize(geometry)
  else
    self.log.ef("Unknown geometry type: %s", type)
  end
end
-- }}} _applyGeometry() --

-- _applyScreen() {{{ --
--- Contexts:_applyScreen()
--- Method
--- Move given window to given screen.
---
--- Parameters:
--- * geometry: hs.screen instance
--- * window: hs.window instance
---
--- Returns:
--- * Nothing
function Contexts:_applyScreen(screen, window)
  self.log.df("Moving window \"%s\" to screen %s", window:title(), screen:name())
  -- DEBUG
  self.log.df("DEBUG: window:frame() == %s", screen:frame())
  -- keep relative size, keep in bounds
  window:moveToScreen(screen, false, true)
end
-- }}} _applyScreen() --

-- reapply() {{{ --
--- Contexts:reapply()
--- Method
--- Reapply the current Context. This is equivalent to calling apply(true) fur
--- the current context.
---
--- Parameters:
--- * None
---
--- Returns:
--- * True on success, false on error
function Contexts:reapply()
  if not Contexts.current then
    Contexts.log.e("reapply() called without active context")
    return false
  end

  Contexts.log.df("Re-applying context %s", Contexts.current.config.title)
  return Contexts.current:apply(true)
end
-- }}} reapply() --

-- unapply() {{{ --
--- Contexts:unapply()
--- Method
--- Unapply context:
---
--- 1) Calls config.exitFunction() if present.
---
--- 2) Saves context in Contet.previous for a subsequent call to Contexts.
---
---
--- Parameters:
--- * None
---
--- Returns:
--- * true on success, false on error
function Contexts:unapply()
  local status = self:_unapply()
  Contexts.previous = self
  Contexts.current = nil
  return status
end
-- }}} unapply() --

-- _unapply() {{{ --
--- Contexts:_unapply()
--- Method
--- Handle the work of unapplying the given context. Can be called recursively
--- to handle inheritance.
---
--- Parameters:
--- * None
---
--- Returns:
--- * true on success, false on error
function Contexts:_unapply()
  if self.config.apps then
    self.log.d("Pausing window filter subscriptions")
    hs.fnutils.each(self.config.apps, function(a) a.wfilter:pause() end)
  end

  if self.config.exitFunction then
    local ok, err = pcall(self.config.exitFunction, debug.traceback)
    if not ok then
      self.log.ef("Context %s: exitFunction() returned error: %s", self.config.title, err)
      return false
    end
  end

  if self.config.inherits then
    return self.config.inherits:_unapply()
  end
  return true
end
-- }}} _unapply() --

-- applyPrevious() {{{ --
--- Contexts:applyPrevious()
--- Function
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
--- Function
--- Display a hs.chooser with all contexts and apply selected.
--- If the Context has an 'image' attribute, it will be used next
--- to the title
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
    function(c)
      return {
        text = c.config.title,
        image = c.config.image
      }
    end)
  table.sort(choices, function(a,b) return a.text:lower() < b.text:lower() end)

  local function callback(choice)
    if choice then
      self.log.df("Context %s chosen", choice.text)
      local context = Contexts.getByTitle(choice.text)
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

-- sealUserActions() {{{ --
--- Contexts:sealUserActions()
--- Function
--- Return a table suitable for Seal.plugins.useractions.actions
--- Table includes an action for each context, plus an action to
--- reload the current context.
--- See http://www.hammerspoon.org/Spoons/Seal.plugins.useractions.html
---
--- Parameters:
--- * actions (option): Table of Seal user actions. If provided, Context
---   actions will be added to this table and returned.
---
--- Returns:
--- * Table of Seal user actions, nil on error
function Contexts:sealUserActions(actions)
  actions = actions or {}
  if not Contexts.contexts then
    self.log.e("sealUserActions() called but Contexts not initialized")
    return nil
  end
  hs.fnutils.each(
    Contexts.contexts,
    function(c)
      actions[c.config.title] = {
        fn = hs.fnutils.partial(Contexts.apply, c),
        icon = c.config.image
      }
    end)
  actions["Reapply Context"] = {
      fn = hs.fnutils.partial(Contexts.reapply, Contexts)
    }
  actions["Unapply Context"] = {
      fn = function() Contexts.current:unapply() end
    }
  return actions
end
-- }}} sealUserActions() --

return Contexts
-- vim:foldmethod=marker:
