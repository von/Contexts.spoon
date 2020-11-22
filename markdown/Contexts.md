# [docs](index.md) » Contexts
---

A Context is based on a list of applications, each with optional filter for window names,
and a set of actions to be called with the Context is applied (or a screen change
is detected), or a new window for the application is created. The same application
can appear multiple times with different filters for window names.

Actions can be any of the following:
* A string starting with "screen:": the remainder of the string is the name of a screen,
  which the window will be moved to if a screen matching the name is found.
* A string matching one of the following, in which case the window will be resized
  as descripbed:
    * `"maximize"`: window will be maximized as `hs.window:maximize()`
    * `"left50"`: window will fill the left 50% of the screen
    * `"right50"`: window will fill the right 50% of the screen
* Any other string will be passed to hs.geometry.new() and, if successfully in creating
  a new `hs.geomtry` instance, the window will be resized to that instance.
* An `hs.geomtry` instance: the window will be resized to that instance.
* An `hs.screen` instance: the window will be moved to the screen
* A function: the function will be called with a single parameter, the `hs.window`
  instance of the window.

Additionally a Context allows for the following:
* Allows for functions that are called when the layout is applied
  and unapplied.
* Allows setting the default input and output audio device.

Additionally, to allow for interactive selection of Contexts:
* The chooser() method creates a hs.chooser() instance to choose created layouts
* The sealUserActions() method creates user actions for the Seal spoon for each
  created Context.
* A specific application/window to receive focus with the Context is applied.

## API Overview
* Functions - API calls offered directly by the extension
 * [applyPrevious](#applyPrevious)
 * [bindHotKeys](#bindHotKeys)
 * [chooser](#chooser)
 * [debug](#debug)
 * [init](#init)
 * [reapply](#reapply)
 * [sealUserActions](#sealUserActions)
 * [start](#start)
 * [stop](#stop)
* Constructors - API calls which return an object, typically one that offers API methods
 * [getByTitle](#getByTitle)
 * [new](#new)
* Methods - API calls which can only be made on an object returned by a constructor
 * [apply](#apply)
 * [unapply](#unapply)

## API Documentation

### Functions

| [applyPrevious](#applyPrevious)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `Contexts:applyPrevious()`                                                                    |
| **Type**                                    | Function                                                                     |
| **Description**                             | Switch to previous context stored in Contexts.previous by unapply()                                                                     |
| **Parameters**                              | <ul><li>* None</li></ul> |
| **Returns**                                 | <ul><li>* true on success, false on error</li></ul>          |

| [bindHotKeys](#bindHotKeys)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `Contexts:bindHotKeys(table)`                                                                    |
| **Type**                                    | Function                                                                     |
| **Description**                             | The method accepts a single parameter, which is a table. The keys of the table                                                                     |
| **Parameters**                              | <ul><li>mapping - Table of action to key mappings</li></ul> |
| **Returns**                                 | <ul><li>Contexts object</li></ul>          |

| [chooser](#chooser)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `Contexts:chooser()`                                                                    |
| **Type**                                    | Function                                                                     |
| **Description**                             | Display a hs.chooser with all contexts and apply selected.                                                                     |
| **Parameters**                              | <ul><li>* None</li></ul> |
| **Returns**                                 | <ul><li>* Nothing</li></ul>          |

| [debug](#debug)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `Contexts:debug(enable)`                                                                    |
| **Type**                                    | Function                                                                     |
| **Description**                             | Enable or disable debugging                                                                     |
| **Parameters**                              | <ul><li>enable - Boolean indicating whether debugging should be on</li></ul> |
| **Returns**                                 | <ul><li>Nothing</li></ul>          |

| [init](#init)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `Contexts:init()`                                                                    |
| **Type**                                    | Function                                                                     |
| **Description**                             | Initializes a Contexts                                                                     |
| **Parameters**                              | <ul><li>None</li></ul> |
| **Returns**                                 | <ul><li>Contexts object</li></ul>          |

| [reapply](#reapply)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `Contexts:reapply()`                                                                    |
| **Type**                                    | Function                                                                     |
| **Description**                             | Reapply the current Context. This is equivalent to calling apply(true) fur                                                                     |
| **Parameters**                              | <ul><li>* None</li></ul> |
| **Returns**                                 | <ul><li>* True on success, false on error</li></ul>          |

| [sealUserActions](#sealUserActions)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `Contexts:sealUserActions()`                                                                    |
| **Type**                                    | Function                                                                     |
| **Description**                             | Return a table suitable for Seal.plugins.useractions.actions                                                                     |
| **Parameters**                              | <ul><li>* actions (option): Table of Seal user actions. If provided, Context</li><li>  actions will be added to this table and returned.</li></ul> |
| **Returns**                                 | <ul><li>* Table of Seal user actions, nil on error</li></ul>          |

| [start](#start)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `Contexts:start()`                                                                    |
| **Type**                                    | Function                                                                     |
| **Description**                             | Start background activity.                                                                     |
| **Parameters**                              | <ul><li>None</li></ul> |
| **Returns**                                 | <ul><li>Contexts object</li></ul>          |

| [stop](#stop)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `Contexts:stop()`                                                                    |
| **Type**                                    | Function                                                                     |
| **Description**                             | Stop background activity.                                                                     |
| **Parameters**                              | <ul><li>None</li></ul> |
| **Returns**                                 | <ul><li>Contexts object</li></ul>          |

### Constructors

| [getByTitle](#getByTitle)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `Contexts.getByTitle()`                                                                    |
| **Type**                                    | Constructor                                                                     |
| **Description**                             | Given the title of a previous created Context, return its instance.                                                                     |
| **Parameters**                              | <ul><li>* title: Context title</li></ul> |
| **Returns**                                 | <ul><li>* Context instance, or nil if not found</li></ul>          |

| [new](#new)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `Contexts.new()`                                                                    |
| **Type**                                    | Constructor                                                                     |
| **Description**                             | Create a new Contexts instance                                                                     |
| **Parameters**                              | <ul><li>* config: A table containing the following keys:</li><li> title (string) [Required]: Title of context for display to user</li><li> image (hs.image) [Optional]: chooser() will use this image</li><li> apps (table) [Optional]: A list of tables, each containing:</li><li>   name (string): Application name</li><li>   windowNames (string) [Optional]: only allow windows whose title matches the</li><li>      pattern(s) as per string.match</li><li>   apply (list) [Optional]: A list of actions to apply to the application's</li><li>      windows when the Context is applied. These are also applied when a screen</li><li>      change is detected. See module description for details on Actions.</li><li>   create (list) [Optional]: A list of actions to apply to a new window</li><li>      created for the application (and matching `windowNames` if given).</li><li> enterFunction (function) [Optional]: A function called when context is applied</li><li> exitFunction (function) [Optional]: A function called when context is exited</li><li> focused (dictionary) [Optional]: Window to focus on. First element is application,</li><li>    second optional element is window name.</li><li> defaultInputDevice (table) [Optional]: List of strings identifying input audio</li><li>    devices.  First input device found, will be set to the default.</li><li> defaultOutputDevice (table) [Optional]: List of strings identifying output</li><li>    audio devices. First output device found, will be set to the default.</li></ul> |
| **Returns**                                 | <ul><li>* Contexts instance</li></ul>          |

### Methods

| [apply](#apply)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `Contexts:apply()`                                                                    |
| **Type**                                    | Method                                                                     |
| **Description**                             | Apply given context:                                                                     |
| **Parameters**                              | <ul><li>* reapply [optional]: True if we are re-applying a context.</li></ul> |
| **Returns**                                 | <ul><li>* true on success, false on failure</li></ul>          |

| [unapply](#unapply)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `Contexts:unapply()`                                                                    |
| **Type**                                    | Method                                                                     |
| **Description**                             | Unapply context:                                                                     |
| **Parameters**                              | <ul><li>* None</li></ul> |
| **Returns**                                 | <ul><li>* true on success, false on error</li></ul>          |

