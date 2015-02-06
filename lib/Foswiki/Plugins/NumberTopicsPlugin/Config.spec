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
