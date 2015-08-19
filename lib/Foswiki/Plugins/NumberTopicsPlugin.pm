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

our $lastIndexedMeta;

sub initPlugin {
    my ( $topic, $web, $user, $installWeb ) = @_;

    # check for Plugins.pm versions
    if ( $Foswiki::Plugins::VERSION < 2.1 ) {
        Foswiki::Func::writeWarning( 'Version mismatch between ',
            __PACKAGE__, ' and Plugins.pm' );
        return 0;
    }

    # Copy/Paste/Modify from MetaCommentPlugin
    # SMELL: this is not reliable as it depends on plugin order
    # if (Foswiki::Func::getContext()->{SolrPluginEnabled}) {
    if ($Foswiki::cfg{Plugins}{SolrPlugin}{Enabled}) {
      require Foswiki::Plugins::SolrPlugin;
      Foswiki::Plugins::SolrPlugin::registerIndexAttachmentHandler(
        \&indexAttachmentHandler
      );
      Foswiki::Plugins::SolrPlugin::registerIndexTopicHandler(
        \&indexTopicHandler
      );
    }

    undef $lastIndexedMeta;

    return 1;
}

sub beforeEditHandler {
    my ( $text, $topic, $web, $meta ) = @_;

    return if $Foswiki::cfg{Plugins}{NumberTopicsPlugin}{Disabled};

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

    return if $Foswiki::cfg{Plugins}{NumberTopicsPlugin}{Disabled};

    my $fieldname = $Foswiki::cfg{Plugins}{NumberTopicsPlugin}{FieldName} || 'Number';
    my $formreg = $Foswiki::cfg{Plugins}{NumberTopicsPlugin}{Form} || '^DocumentForm$';
    my $condition = $Foswiki::cfg{Plugins}{NumberTopicsPlugin}{Condition};
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
        unless( isEditable() ) {
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

    # get number from -deamon- me, its ME who gets the number! Me ME MEEEEE!
    my $response = _getNumber();

    my $value = $response;
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

sub isEditable {
    my $admins = $Foswiki::cfg{Plugins}{NumberTopicsPlugin}{NumberAdminGroup} || 'AdminGroup';

    return ((Foswiki::Func::isGroupMember( $admins ) || Foswiki::Func::isAnAdmin()) ? 1 : 0);
}

sub _getNumber {
    my $suffix = shift || '';
    my $file = $Foswiki::cfg{Plugins}{NumberTopicsPlugin}{NumberFile} . $suffix;
    unless ($file) {
        Foswiki::Func::writeWarning("No NumberFile configured");
        return undef;
    }
    my $returnValue;
    my $exist = (( -e $file ) ? 1 : 0 );
    open FILE, ($exist ? "+<" : ">" ), $file;
    flock(FILE, 2);
    unless( $exist ) {
        $returnValue = '0';
    } else {
        my @lines = <FILE>;
        if(scalar @lines) {
            $returnValue = $lines[0];
        } else {
            $returnValue = '0';
        }
        seek FILE, 0, 0;
        truncate(FILE, 0);
    }

    $returnValue++;

    print FILE $returnValue;
    close(FILE);

    return $returnValue;
}

# XXX This works only for the implicit numbering
sub _index {
    my ($meta, $doc) = @_;

    my $fieldname = $Foswiki::cfg{Plugins}{NumberTopicsPlugin}{FieldName} || 'Number';
    my $formreg = $Foswiki::cfg{Plugins}{NumberTopicsPlugin}{Form} || '^DocumentForm$';

    my $form = $meta->get( 'FORM' );
    return unless $form;
    return unless $form->{name} =~ m#$formreg#;

    my $number = $meta->get( 'FIELD', $fieldname );
    return unless defined $number;
    $number = $number->{value};
    return unless $number && $number =~ m#(\d+)#;
    $number = $1;
    my $solrfield = "field_${fieldname}_short_lst";
    $doc->add_fields( $solrfield => $number );

    while($number =~ s#^0##) {
        $doc->add_fields( $solrfield => $number ) unless $number eq '';
    }
}

sub indexTopicHandler {
    my ($indexer, $doc, $web, $topic, $meta, $text) = @_;

    _index($meta, $doc);
    $lastIndexedMeta = $meta;
}

sub indexAttachmentHandler {
    my ($indexer, $doc, $web, $topic, $attachment) = @_;

    my $meta;
    if($lastIndexedMeta && $lastIndexedMeta->web() eq $web && $lastIndexedMeta->topic() eq $topic) {
        $meta = $lastIndexedMeta;
    } else {
        my $text;
        ($meta, $text) = Foswiki::Func::readTopic($web, $topic);
    }

    _index($meta, $doc);
}

sub _checkDuplicates {
    my ($field, $topicObject) = @_;

    my $thisTopic = $topicObject->topic;
    my $thisWeb = $topicObject->web;

    my $request = Foswiki::Func::getRequestObject();

    my $thisField = $topicObject->get('FIELD', $field->{name});
    my $enteredValue;
    if($request->param('templatetopic')) {
        $topicObject->remove($field->{name}) if $thisField;
    } else {
        $enteredValue = $thisField->{value} if $thisField;
    }

    return unless defined $enteredValue;
    return if $enteredValue eq '';

    # Skipword ('none' etc.)
    my @skip;
    my $list;
    if($field->{value} =~ m#skip\s*=\s*"((?:\\"|[^"])*)"#) {
        $list = $1;
    } else {
        $list = $Foswiki::cfg{Plugins}{NumberTopicsPlugin}{UniqueSkip};
    }
    if(defined $list) {
        $list =~ s#\\"#"#g;
        $list = Foswiki::Func::decodeFormatTokens($list);
        $list =~ s#^\s*##;
        $list =~ s#\s*$##;
        @skip = split(/\s*,\s*/, $list) if $list ne '';
        foreach my $item ( @skip ) {
            return if($enteredValue eq $item);
        }
    }

    # value is always ok if it didn't change, assuming it was unique before
    if( Foswiki::Func::topicExists( $thisWeb, $thisTopic ) ) {
        my ($oldMeta, $oldText) = Foswiki::Func::readTopic( $thisWeb, $thisTopic );
        my $oldValue = $oldMeta->get( 'FIELD', $field->{name} );
        return if defined $oldValue && $enteredValue eq $oldValue->{value};
    }

    # check if value is unique
    my $results = Foswiki::Func::query("(META:FORM.name='$field->{topic}' OR META:FORM.name='$field->{web}.$field->{topic}') AND META:FIELD.name='$field->{name}' AND META:FIELD.value='$enteredValue'", undef, { web => $thisWeb, type => 'query', excludetopic => $thisTopic });
    if($results->hasNext()) {
        my $found = '';
        while($results->hasNext()) {
            $found .= $results->next;
            $found .= ', ' if($results->hasNext());
        }
        return "Number $enteredValue for field $field->{name} already in use here: $found";
    }

    return undef;
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
