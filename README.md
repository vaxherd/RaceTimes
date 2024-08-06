RaceTimes - World of Warcraft skyriding race records viewer
===========================================================

Author: vaxherd  
Source: https://github.com/vaxherd/RaceTimes  
License: Public domain


Overview
--------
RaceTimes is a simple World of Warcraft addon which provides a dialog
window listing the player's best recorded time in each of the game's
skyriding races.  The window also includes map links for each race,
making it easier to locate a particular race.


Installation
------------
Just copy the source tree into a `RaceTimes` (or otherwise appropriately
named) folder under `Interface/AddOns` in your World of Warcraft
installation.  RaceTimes has no external dependencies.


Usage
-----
Type the `/racetimes` (or `/rt`) command into the chat window to open
the race list.  The list shows the player's best time for each race in
the selected category (Normal, Advanced, etc.), colored according to
whether it is a bronze, silver, or gold time.  The category can be
changed by clicking the buttons at the top of the list.

Click the map link next to each name (or the name itself) to open the
world map with a pin on the race's location.  The map will not open if
you are in combat, though the pin will still be set.

If there are any races in your current zone, the race list will
automatically scroll to that zone when opened.

The race list can also be opened with the macro command
`/run RaceTimes.Show()`, for integration with custom buttons or other
addons.


Reporting bugs
--------------
Report any bugs via the GitHub issues interface:
https://github.com/vaxherd/RaceTimes/issues
