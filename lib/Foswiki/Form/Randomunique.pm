# See bottom of file for license and copyright information
package Foswiki::Form::Randomunique;

use strict;
use warnings;

use Foswiki::Form::FieldDefinition ();
use Foswiki::Plugins ();
use Foswiki::Plugins::NumberTopicsPlugin ();
our @ISA = ('Foswiki::Form::FieldDefinition');

# TODO: Do not die on error, throw exception

sub new {
  my $class = shift;
  my $this = $class->SUPER::new(@_);

  return $this;
}

sub finish {
  my $this = shift;
  $this->SUPER::finish();
}

sub isEditable {
  return Foswiki::Plugins::NumberTopicsPlugin::isEditable();
}

# Will automatically filled in, so not mandatory.
sub isMandatory { 0 }

# Return an empty default value, this will only be shown when condition is not met.
sub getDefaultValue {
    return '';
}

sub renderForEdit {
  my ($this, $topicObject, $value) = @_;

  my $request = Foswiki::Func::getRequestObject();
  if($request->param('templatetopic')) {
      undef $value;
  }

  if(isEditable) {
      # We are in NumberAdminGroup
      $value ||= '';
      $value = "<span class='randomuniqueForm'><input class='randomuniqueEditable' type='text' value='$value' name='$this->{name}' readonly='readonly' /><span class='randomuniqueEditableLock'><img src='%PUBURLPATH%/%SYSTEMWEB%/FamFamFamSilkIcons/key.png' /></span>";
    Foswiki::Func::addToZone('script', 'Form::Autoincrement::script', <<SCRIPT, 'JQUERYPLUGIN::FOSWIKI,jsi18nCore');
<script type="text/javascript" src="%PUBURLPATH%/%SYSTEMWEB%/NumberTopicsPlugin/autoincrementedit.js"></script>
SCRIPT
  } else {
      if ( (not defined $value) || $value eq '' ) {
          if ( $this->{value} =~ m#EmptyFieldMessage="((?:\\"|[^"])*)"# ) {
              $value = $1;
              $value =~ s#\\"#"#g;
          } else {
              $value = $Foswiki::cfg{Plugins}{NumberTopicsPlugin}{EmptyFieldMessage} || '<i>%MAKETEXT{"(will be automatically assigned)"}%</i>';
          }
      }
  }

  return (
    '',
    "<span class='randomuniqueField'>$value</span>"
  );
}

sub beforeSaveHandler {
    my ($this, $topicObject) = @_;

    return if $Foswiki::cfg{Plugins}{NumberTopicsPlugin}{Disabled};

    my $thisTopic = $topicObject->topic;
    my $thisWeb = $topicObject->web;

    my $thisField = $topicObject->get('FIELD', $this->{name});
    my $enteredValue;
    $enteredValue = $thisField->{value} if $thisField;

    my $request = Foswiki::Func::getRequestObject();
    if($request->param('templatetopic')) {
        undef $enteredValue;
    }

    if($enteredValue) {
        if( !isEditable() ) {
            if( Foswiki::Func::topicExists( $thisWeb, $thisTopic ) ) {
                my ($oldMeta, $oldText) = Foswiki::Func::readTopic( $thisWeb, $thisTopic );
                my $oldNumber = $oldMeta->get( 'FIELD', $this->{name} );
                die "Number changed from ".(($oldNumber)?$oldNumber->{value}:"''")." to $enteredValue" unless ($oldNumber && $oldNumber->{value} eq $enteredValue);
            }
        }
        my $duplicates = Foswiki::Plugins::NumberTopicsPlugin::_checkDuplicates($this, $topicObject);
        die $duplicates if $duplicates;
    } else {
        $topicObject->remove('FIELD', $this->{name});

        # get condition
        my $condition;
        if($this->{value} =~ m#condition\s*=\s*"((?:\\"|[^"])*)"#) {
            $condition = $1;
            $condition =~ s#\\"#"#g;
            $condition = Foswiki::Func::decodeFormatTokens($condition);
        } else {
            $condition = $Foswiki::cfg{Plugins}{NumberTopicsPlugin}{Condition};
        }
        # evaluate condition
        if(defined $condition) {
            $condition = Foswiki::Func::expandCommonVariables($condition, $thisTopic, $thisWeb);
            if($condition eq '') {
                $condition = 1; # pass non-set condition as 'do it'
            } else {
                $condition = Foswiki::Func::isTrue($condition);
            }
        } else {
            $condition = 1; # pass non-set condition as 'do it'
        }

        if($condition) {
            # generate number

            # padding
            my $padding;
            if($this->{value} =~ m#\bpadding\s*=\s*(\d*)\b#) {
                $padding = $1;
            } else {
                $padding = $Foswiki::cfg{Plugins}{NumberTopicsPlugin}{padding};
            }

            # min/max values
            my $max;
            my $min;
            if($this->{value} =~ m#\bdigits\s*=\s*(\d*)\b#) {
                $max = $1;
            } else {
                $max = $padding || 6;
            }
            if($this->{value} =~ m#\bmindigits\s*=\s*(\d*)\b#) {
                $min = $1;
            } else {
                $min = $max;
            }
            $min = (10 ** $min);
            $max = 10 ** ($max + 1) - $min - 1;

            my $value;
            do {
                $value = $min + int(rand($max));
                if($padding) {
                    $value = sprintf("%0${padding}d", $value);
                }
            } while (Foswiki::Plugins::NumberTopicsPlugin::_checkDuplicates($this, $topicObject));

            # save number
            $thisField = {
                name => $this->{name},
                title => $this->{name},
                value => $value,
            };
            $topicObject->putKeyed('FIELD', $thisField);
        }
    }

    # remove it from the request so that it doesn't override things here
    $request->delete($this->{name});
}

1;
__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2013-2014 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

Additional copyrights apply to some or all of the code in this
file as follows:

Copyright (C) 2001-2007 TWiki Contributors. All Rights Reserved.
TWiki Contributors are listed in the AUTHORS file in the root
of this distribution. NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.

