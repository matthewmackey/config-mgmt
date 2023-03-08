Role: `common`
==============

This is probably a role that should be Deprecated.  Its functionality could
likely be moved to the `base` role.  Currently it is confusing having both
the base and common roles.

I think this is only currently included by the `base` role which sets up
common base packages, etc. that we want applied to all hosts.  If it is included
elsewhere then those uses are from the old pattern of doing things when this was
the main "common" role.
