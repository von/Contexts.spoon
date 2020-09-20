# [docs](index.md) » Contexts
---

A context is based on a hs.layout configuration of
a set of applications and windows and their layout
and adds the following:
* Automatically launches applications that are not running in the layout.
* Automatically unminimizes windows in the layout.
* Allows for functions that are called when the layout is applied
  and unapplied.
* Creates a set of hs.window.filter subscriptions for windows in the
  layout and applies the relevant portion of the layout for any relevant
  new windows that are created.
* Allows setting the default input and output audio device.
* Re-applies the layout on screen layout changes.

Additionally, to allow for interactive selection of Contextsr:
* The chooser() method creates a hs.chooser() instance to choose created layouts
* The sealUserActions() method creates user actions for the Seal spoon for each
  created Context.

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
| **Parameters**                              | <ul><li>* None</li></ul> |
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

| [new](#new)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `Contexts.new()`                                                                    |
| **Type**                                    | Constructor                                                                     |
| **Description**                             | Create a new Contexts instance                                                                     |
| **Parameters**                              | <ul><li>* config: A table containing the following keys:</li><li> title (string) [Required]: Title of context for display to user</li><li> image (hs.image) [Optional]: chooser() will use this image</li><li> layout (table) [Optional]: A table suitable for use with hs.layout.apply</li><li> enterFunction (function) [Optional]: A function called when context is applied</li><li> exitFunction (function) [Optional]: A function called when context is exited</li><li> focused (dictionary) [Optional]: Window to focus on. First element is application,</li><li>    second optional element is window name.</li><li> defaultInputDevice (table) [Optional]: List of strings identifying input audio</li><li>    devices.  First input device found, will be set to the default.</li><li> defaultOutputDevice (table) [Optional]: List of strings identifying output</li><li>    audio devices. First output device found, will be set to the default.</li></ul> |
| **Returns**                                 | <ul><li>* Contexts instance</li></ul>          |

### Methods

| [apply](#apply)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `Contexts:apply()`                                                                    |
| **Type**                                    | Method                                                                     |
| **Description**                             | Apply given context:                                                                     |
| **Parameters**                              | <ul><li>* reapply [options]: True if we are re-applying a context.</li></ul> |
| **Returns**                                 | <ul><li>* true on success, false on failure</li></ul>          |

| [unapply](#unapply)         |                                                                                     |
| --------------------------------------------|-------------------------------------------------------------------------------------|
| **Signature**                               | `Contexts:unapply()`                                                                    |
| **Type**                                    | Method                                                                     |
| **Description**                             | Unapply context:                                                                     |
| **Parameters**                              | <ul><li>* None</li></ul> |
| **Returns**                                 | <ul><li>* true on success, false on error</li></ul>          |

