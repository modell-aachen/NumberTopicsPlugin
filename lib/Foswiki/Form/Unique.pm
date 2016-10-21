# See bottom of file for license and copyright information
package Foswiki::Form::Unique;

use strict;
use warnings;

use Foswiki::Form::FieldDefinition ();
use Foswiki::Plugins ();
use Foswiki::Plugins::NumberTopicsPlugin ();
our @ISA = ('Foswiki::Form::FieldDefinition');

sub new {
  my $class = shift;
  my $this = $class->SUPER::new(@_);

  return $this;
}

sub finish {
  my $this = shift;
  $this->SUPER::finish();
}

sub getDefaultValue {
    return '';
}

sub renderForEdit {
  my ($this, $topicObject, $value) = @_;

  my $request = Foswiki::Func::getRequestObject();
  if($request->param('templatetopic')) {
      undef $value;
  }

  if($this->isEditable()) {
      $value ||= '';
      $value = "<input type='text' value='$value' name='$this->{name}' />";
  } else {
      $value = "<input type='text' value='$value' name='$this->{name}' readonly='readonly' />";
  }

  return (
    '',
    "<span class='uniqueField'>$value</span>"
  );
}

sub beforeSaveHandler {
    my ($this, $topicObject) = @_;

    return if $Foswiki::cfg{Plugins}{NumberTopicsPlugin}{Disabled};

    my $duplicates = Foswiki::Plugins::NumberTopicsPlugin::_checkDuplicates($this, $topicObject);
    die $duplicates if $duplicates;
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

