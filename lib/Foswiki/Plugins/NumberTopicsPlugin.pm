# See bottom of file for license and copyright information

package Foswiki::Plugins::NumberTopicsPlugin;

use strict;
use warnings;

use Foswiki::Func    ();    # The plugins API
use Foswiki::Plugins ();    # For the API version

our $VERSION = '1.0';
our $RELEASE = '1.0';

# One line description of the module
our $SHORTDESCRIPTION = 'Create a unique number in the document form for each topic.';

our $NO_PREFS_IN_TOPIC = 1;

sub initPlugin {
    my ( $topic, $web, $user, $installWeb ) = @_;

    # check for Plugins.pm versions
    if ( $Foswiki::Plugins::VERSION < 2.1 ) {
        Foswiki::Func::writeWarning( 'Version mismatch between ',
            __PACKAGE__, ' and Plugins.pm' );
        return 0;
    }

    return 1;
}

sub beforeEditHandler {
    my ( $text, $topic, $web, $meta ) = @_;

    my $query = Foswiki::Func::getCgiQuery();
    if($meta && $query->param('templatetopic')) {
        my $fieldname = $Foswiki::cfg{Plugins}{NumberTopicsPlugin}{FieldName} || 'Number';
        $meta->remove( 'FIELD', $fieldname );
    }
}

=begin TML

---++ beforeSaveHandler($text, $topic, $web, $meta )
   * =$text= - text _with embedded meta-data tags_
   * =$topic= - the name of the topic in the current CGI query
   * =$web= - the name of the web in the current CGI query
   * =$meta= - the metadata of the topic being saved, represented by a Foswiki::Meta object.

This handler will embed the number, if it is not already present.

=cut

sub beforeSaveHandler {
    my ( $text, $topic, $web, $meta ) = @_;

    my $fieldname = $Foswiki::cfg{Plugins}{NumberTopicsPlugin}{FieldName} || 'Number';
    my $formreg = $Foswiki::cfg{Plugins}{NumberTopicsPlugin}{Form} || '^DocumentForm$';
    my $query = Foswiki::Func::getCgiQuery();

    my $form = $meta->get( 'FORM' );
    return unless $form;
    return unless $form->{name} =~ m#$formreg#;

    # check if document already has a number;
    # do not use template number
    unless($query->param('templatetopic')) {
        my $number = $meta->get( 'FIELD', $fieldname );
        return if $number && $number->{value};
    }

    # get number from deamon
    my $response = Foswiki::Plugins::TaskDaemonPlugin::send('', 'get_new_number', 'NumberTopicsPlugin', 1);

    unless($response) {
        Foswiki::Func::writeWarning("Got no response from deamon!");
        return;
    }
    my $value = $response->{data};
    unless($value) {
        Foswiki::Func::writeWarning("Received no number for $web.$topic!");
        return;
    }
    # save number
    $meta->putKeyed( 'FIELD', { name=>$fieldname, title=>$fieldname, value=>$value } );
}


1;

__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2008-2013 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
