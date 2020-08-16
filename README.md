# Contexts.spoon
Hammerspoon spoon for switching contexts

Basically a wrapper around [hs.layout](https://www.hammerspoon.org/docs/hs.layout.html) with
the following additions:

 * Allows for an optional function to be called when a context is applied

 * Starts any applications listed in the layout if they are not running.

 * Unminimizes any windows listed in the layout if needed.

 * Allows for an optional function to be called with a context is unapplied (typically
   when another context is applied.
