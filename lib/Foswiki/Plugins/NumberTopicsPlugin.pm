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
    my $condition = $Foswiki::cfg{Plugins}{NumberTopicsPlugin}{Condition};
    my $admins = $Foswiki::cfg{Plugins}{NumberTopicsPlugin}{NumberAdminGroup} || 'AdminGroup';
    my $query = Foswiki::Func::getCgiQuery();

    my $form = $meta->get( 'FORM' );
    return unless $form;
    return unless $form->{name} =~ m#$formreg#;

    # check if document already has a number;
    # do not use template number
    my $number = $meta->get( 'FIELD', $fieldname );
    my $numberValue;
    if ( $number && ($numberValue = $number->{value}) ) {
        if($query->param('templatetopic')) {
            $meta->remove( 'FIELD', $fieldname );
            $numberValue = '';
        }
        unless( Foswiki::Func::isGroupMember( $admins ) || Foswiki::Func::isAnAdmin() ) {
            if( Foswiki::Func::topicExists( $web, $topic ) ) {
                my ($oldMeta, $oldText) = Foswiki::Func::readTopic( $web, $topic );
                my $oldNumber = $oldMeta->get( 'FIELD', $fieldname );
                die "Number changed from ".(($oldNumber)?$oldNumber->{value}:"''")." to $numberValue" unless ($oldNumber && $oldNumber->{value} eq $numberValue);
            }
        }
        return if $numberValue; # false if templatetopic
    }

    # check if condition is met
    if(defined $condition && $condition !~ m#^\s*$#) {
        my $evalueated = Foswiki::Func::expandCommonVariables($condition, $topic, $web, $meta);
        return unless $evalueated;
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

    # padding
    my $padding = $Foswiki::cfg{Plugins}{NumberTopicsPlugin}{padding};
    if($padding) {
        $value = sprintf("%0${padding}d", $value);
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