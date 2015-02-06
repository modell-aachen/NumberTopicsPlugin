# ---+ Extensions
# ---++ NumberTopicsPlugin
#** STRING **
# Only apply numbers if the form matches this regex.
$Foswiki::cfg{Plugins}{NumberTopicsPlugin}{Form} = '';
#** STRING **
# Write numbers to this formfield.
$Foswiki::cfg{Plugins}{NumberTopicsPlugin}{FormField} = 'Number';
#** STRING **
# This file controls the currently highest used number.
# <p>Must be writeable by the worker.</p>
$Foswiki::cfg{Plugins}{NumberTopicsPlugin}{NumberFile} = '';
#** STRING **
# Administrators and members of this group are allowed to manipulate numbers.
# <p>Only one group allowed.</p>
$Foswiki::cfg{Plugins}{NumberTopicsPlugin}{NumberAdminGroup} = 'AdminGroup';
#** STRING **
# Only Generate a number if this condition is empty (disabled) or expands to perl-true.
$Foswiki::cfg{Plugins}{NumberTopicsPlugin}{Condition} = '';
