#!/bin/sh
# Emacs like specification -*- Tcl script -*-
# the next line restarts using wish \
exec wish "$0" "$@"

# hello -- example
# Simple Tk script to create a button that prints "Hello, world".
# Click on the button to terminate the program.
#
# The first line below creates the button, and the second line
# asks the packer to shrink-wrap the application's main window
# around the button.

button .hello -text "Hello, world" -command {
    puts stdout "Hello, world"; destroy .
}
pack .hello

$myvar

# Local Variables:
# mode: tcl
# End:
