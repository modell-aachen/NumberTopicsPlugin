# ---+ Extensions
# ---++ NumberTopicsPlugin
#** STRING **
# Only apply numbers if the form matches this regex.
$Foswiki::cfg{Plugins}{NumberTopicsPlugin}{Form} = '';
#** STRING **
# Write numbers to this formfield.
$Foswiki::cfg{Plugins}{NumberTopicsPlugin}{FormField} = 'Number';
#** STRING **
# This file controls the currently highest used number; an _id_ might be suffixed.
# <p>Must be writeable by the worker.</p>
$Foswiki::cfg{Plugins}{NumberTopicsPlugin}{NumberFile} = '';
#** STRING **
# Administrators and members of this group are allowed to manipulate numbers.
# <p>Only one group allowed.</p>
$Foswiki::cfg{Plugins}{NumberTopicsPlugin}{NumberAdminGroup} = 'AdminGroup';
#** STRING **
# Only Generate a number if this condition is empty (disabled) or expands to perl-true.
$Foswiki::cfg{Plugins}{NumberTopicsPlugin}{Condition} = '';
#** NUMBER **
# The number will be padded with zeros up to this many places.
$Foswiki::cfg{Plugins}{NumberTopicsPlugin}{padding} = 0;
#** BOOLEAN **
# This will cause this plugin to do nothing.
$Foswiki::cfg{Plugins}{NumberTopicsPlugin}{Disabled} = 0;
#** STRING **
# default message that will be displayed, when a UniqueNumber field is not filled out.
# <p> Defaults to <i>(will be automatically assigned)</i></p>
$Foswiki::cfg{Plugins}{NumberTopicsPlugin}{EmptyFieldMessage} = '';
#** STRING **
# These words will be skipped for unique/randomuniqe fields.
$Foswiki::cfg{Plugins}{NumberTopicsPlugin}{UniqueSkip} = '';
