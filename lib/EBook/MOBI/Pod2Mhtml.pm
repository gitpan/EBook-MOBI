package EBook::MOBI::Pod2Mhtml;

use strict;
use warnings;

use Pod::Parser;
our @ISA = qw(Pod::Parser);

our $VERSION = 0.2;

use Text::Trim;
use HTML::Entities;
use Carp;

# This constants are used for internal replacement
# See interior_sequence() and _html_enc() for usage
use constant { GT  => '1_qpdhcn_thisStringShouldNeverOccurInInput',
               LT  => '2_udtcqk_thisStringShouldNeverOccurInInput',
               AMP => '3_pegjyq_thisStringShouldNeverOccurInInput',
               COL => '4_jdkmso_thisStringShouldNeverOccurInInput',
               QUO => '5_wuehlo_thisStringShouldNeverOccurInInput'};

# IMPORTANT
# This constant ist JUST a shortcut for readability.
# Because it is used in hases ($parser->{}) a + is used so that it is not
# interpreted as a string, so it looks like this: $parser->{+P . 'bla'}
# See http://perldoc.perl.org/constant.html for details
use constant { P   => 'EBook_MOBI_Pod2Mhtml_' };

# Overwrite sub of Pod::Parser
# At start of POD we print a html BODY tag
sub begin_input {
    my $parser = shift;
    my $out_fh = $parser->output_handle();       # handle for parsing output

    $parser->_debug('found POD, parsing...');

    # make sure that this variable is set to 0 at beginning
    $parser->{+P . 'listcontext'} = 0;
    $parser->{+P . 'listjustwentback'} = 0;

    if (exists $parser->{+P . 'body'} and $parser->{+P . 'body'}) {
        print $out_fh "<body>\n";
    }
}

# Overwrite sub of Pod::Parser
# At end of POD we print a html /BODY tag
sub end_input {
    my $parser = shift;
    my $out_fh = $parser->output_handle();

    $parser->_debug('...end of POD reached');

    # at the end of file we should not be in listcontext anymore
    #if($parser->{+P . 'listcontext'}) {
        #croak "POD parsing error. Did you forget '=back' at end of list?";
    #}

    if (exists $parser->{+P . 'body'} and $parser->{+P . 'body'}) {
        print $out_fh "</body>\n";
    }
}

# Overwrite sub of Pod::Parser
# Here all POD commands starting with '=' are handled
sub command { 
    my ($parser, $command, $paragraph, $line_num) = @_; 
    my $out_fh = $parser->output_handle();       # handle for parsing output

    # IMAGE is an unofficial command introduced by Renee, its very simple:
    # =image PATH_TO_IMAGE ANY TEXT FOLLOWING UNTIL END OF LINE
    if ($command eq 'image') {

        # With this regex we parse the content, coming with the command.
        # An example could look like this:
        # $paragraph = '/home/user/picture.jpg Pic1: A Camel'
        if ($paragraph =~ m/(\S*)\s*(.*)/g) {
            my $img_path = $1;  # e.g.: '/home/user/picture.jpg'
            my $img_desc = $2;  # e.g.: 'A Camel'

            # We convert special chars to HTML, but only in the
            # description, not in the path!
            $img_desc = _html_enc($img_desc);

            # We count the pictures, so that each has a number
            $parser->{'EBook::MOBI::Pod2Mhtml::img_count'} ++;

            # We print out an html image tag.
            # e.g.: <img src="/home/user/picture.jpg" recindex="1">
            # recindex is MOBI specific, its the number of the picture,
            # pointing into the picture records of the Mobi-format
            print $out_fh '<img src="' . $img_path . '"'
                        . ' recindex="' . $parser-> {
                                'EBook::MOBI::Pod2Mhtml::img_count'
                            }
                        .'" >'
                        . "\n";
            # Then we print out the image description
            print $out_fh '<p>' . $img_desc . '</p>' . "\n";
        }
    }
    # Lists are a bit complex. The commands 'over', 'back' and 'item'
    # are used. They exchange state over a global variable. This state
    # is the listcontext, which can be: 'begin', 'ul' or 'ol'.
    # OVER: starts the listcontext
    elsif ($command eq 'over') {

        # If we reach an 'over' command we can't do anything yet
        # because we don't know if it will be an ordered or an
        # unordered list! So we just set a global variable to 'begin',
        # the first item call can then know that it is the first item
        # and that it defines the rest of the list type.

        if (exists $parser->{+P . 'list'}) {
            # if we reach here, this means that this is a nested list
            $parser->{+P . 'listlvl'}++;
        }
        else {
            $parser->{+P . 'listlvl'} = 0;
        }


        push @{$parser->{+P . 'list'}}
             , {
                 type    => ''     ,
                 items   => 0      ,
                 state   => 'over' ,
                 contentInCmd => 1 ,
                 blockquotes  => 0 ,
               };
    }
    # BACK: ends the listcontext
    elsif ($command eq 'back') {

        my $lvl = $parser->{+P . 'listlvl'};

        # print end-tag according to the lists type
        if ($parser->{+P . 'list'}->[$lvl]->{type} eq 'ul') {
            print $out_fh '</li>' . "\n"; # close last item
            print $out_fh '</ul>' . "\n";
        }
        elsif ($parser->{+P . 'list'}->[$lvl]->{type} eq 'ol') {
            print $out_fh '</li>' . "\n"; # close last item
            print $out_fh '</ol>' . "\n";
        }
        elsif
          ($parser->{+P . 'list'}->[$lvl]->{type}
           eq 'blockquote') {
            # list is processed
            # there where no items...
        }
        else {
            croak 'POD parsing error. Undefined listcontext: '
                  . $parser->{+P . 'listcontext'};
        }

        # DELETE if list is finish
        if ($parser->{+P . 'listlvl'} == 0) {
            delete $parser->{+P . 'listlvl'};
            delete $parser->{+P . 'list'};
            delete $parser->{+P . 'listjustwentback'};
        }
        else {
            $parser->{+P . 'list'}->[$lvl]->{state} = 'back';
            $parser->{+P . 'listlvl'}--;
            $parser->{+P . 'listjustwentback'} = 1;
        }
    }
    # CUT: end of POD
    elsif ($command eq 'cut') {
        # We don't need to do anything here...
    }
    # if we reach this ELSE, this means that the command can only be
    # of type HEAD or ITEM (so they contain some text!)
    else {
        # first we remove all whitespace from begin and end of the title
        trim $paragraph;
        # then we call interpolate so that 'interior_sequence' is called.
        # this is replacing inline POD.
        my $expansion = $parser->interpolate($paragraph, $line_num);
        # then we replace special chars with HTML entities
        $expansion = _html_enc($expansion);

        # Now we just need to print the text with the matching HTML tag
        if ($command eq 'head0') {
            # head0 gets only printed if the option is set!
            # (head0 is not official POD standard)
            if (exists $parser->{+P . 'head0_mode'}
              and $parser->{+P . 'head0_mode'}) {
                # before every head1 we insert a "mobi-pagebreak"
                # but not before the first one!
                if (exists $parser->{+P . 'firstH1passed'}
                and exists $parser->{+P . 'pages'}
                and        $parser->{+P . 'pages'}
                ) {
                    print $out_fh '<mbp:pagebreak />'       . "\n";
                }
                else {
                    $parser->{+P . 'firstH1passed'} = 1;
                }

                print $out_fh '<h1>' . $expansion . '</h1>' . "\n"
            }
        }
        elsif ($command eq 'head1') {
            # we need to check to which level we translate the headings...
            if (exists $parser->{+P . 'head0_mode'}
                and $parser->{+P . 'head0_mode'}
                ) {
                print $out_fh '<h2>' . $expansion . '</h2>' . "\n"
            }
            else {
                # before every head1 we insert a "mobi-pagebreak"
                # but not before the first one!
                if (exists $parser->{+P . 'firstH1passed'}
                and exists $parser->{+P . 'pages'}
                and        $parser->{+P . 'pages'}
                ) {
                    print $out_fh '<mbp:pagebreak />'       . "\n";
                }
                else {
                    $parser->{+P . 'firstH1passed'} = 1;
                }

                print $out_fh '<h1>' . $expansion . '</h1>' . "\n"
            }
        }
        elsif ($command eq 'head2') {
            # we need to check to which level we translate the headings...
            if (exists $parser->{+P . 'head0_mode'}
                and $parser->{+P . 'head0_mode'}
                ) {
                print $out_fh '<h3>' . $expansion . '</h3>' . "\n"
            }
            else {
                print $out_fh '<h2>' . $expansion . '</h2>' . "\n"
            }
        }
        elsif ($command eq 'head3') {
            # we need to check to which level we translate the headings...
            if (exists $parser->{+P . 'head0_mode'}
                and $parser->{+P . 'head0_mode'}
                ) {
                print $out_fh '<h4>' . $expansion . '</h4>' . "\n"
            }
            else {
                print $out_fh '<h3>' . $expansion . '</h3>' . "\n"
            }
        }
        elsif ($command eq 'head4') {
            # we need to check to which level we translate the headings...
            if (exists $parser->{+P . 'head0_mode'}
                and $parser->{+P . 'head0_mode'}
                ) {
                print $out_fh '<h5>' . $expansion . '</h5>' . "\n"
            }
            else {
                print $out_fh '<h4>' . $expansion . '</h4>' . "\n"
            }
        }
        # ITEM: the lists items
        elsif ($command eq 'item') {

            # If we are still in listcontext 'begin' this means that this is
            # the first item of the list, which will be used to figure out
            # the type of the list.
            my $lvl = $parser->{+P . 'listlvl'};

            $parser->{+P . 'list'}->[$lvl]->{items}++;

            #print "DEBUG: item lvl $lvl no." .
                #$parser->{+P . 'list'}->[$lvl]->{items}
                #. "\n";

            if ($parser->{+P . 'list'}->[$lvl]->{items} == 1){

                # if we are already in a list...
                if ($parser->{+P . 'list'}->[$lvl]->{state}
                    eq 'over'
                    and $lvl > 0
                    and
                    $parser->{+P . 'list'}->[$lvl-1]->{items}
                    > 0
                    ) {
                    # we need to close the last item!
                    print $out_fh '</li>' . "\n";
                }

                # is there a digit at first, if yes this is an ordered list
                if ($expansion =~ /^\s*\d+\s*(.*)$/) {
                    $expansion = $1;
                    $parser->{+P . 'list'}->[$lvl]
                           ->{type} = 'ol';

                    if ($expansion =~ /[[:alnum:][:punct:]]+/) {
                        print $out_fh '<ol>' . "\n";
                    }
                    else {
                        $parser->{+P . 'list'}->[$lvl]->{contentInCmd} = 0;
                        print $out_fh "<ol>\n";
                    }
                }
                # is there a '*' at first, if yes this is an unordered list
                elsif ($expansion =~ /^\s*\*{1}\s*(.*)$/) {
                    $expansion = $1;
                    $parser->{+P . 'list'}->[$lvl]->{type} = 'ul';

                    if ($expansion =~ /[[:alnum:][:punct:]]+/) {
                        print $out_fh '<ul>' . "\n";
                    }
                    else {
                        $parser->{+P . 'list'}->[$lvl]->{contentInCmd} = 0;
                        print $out_fh "<ul>\n";
                        #<!-- no content in item -->\n";
                    }
                }
                # are there only prinable chars? We default to unordered
                elsif ($expansion =~ /[[:alnum:][:punct:]]+/) {
                    $parser->{+P . 'list'}->[$lvl]->{type} = 'ul';
                    print $out_fh '<ul>' . "\n";
                    # do nothing
                }
                # The lists text may be in a normal text section...
                # we default to unordered
                else {
                    $parser->{+P . 'list'}->[$lvl]->{type} = 'ul';
                    $parser->{+P . 'list'}->[$lvl]->{contentInCmd} = 0;
                    print $out_fh "<ul>\n";
                }
            }

            # if it is not the first item we save the checks for list-type
            else {

                # but first we need to close the last item!
                if ($parser->{+P . 'listjustwentback'}) {
                    $parser->{+P . 'listjustwentback'} = 0;
                }
                else {
                    # we need to close the last item!
                    print $out_fh '</li>' . "\n";
                }

                my $type =
                   $parser->{+P . 'list'}->[$lvl]->{type};

                # then we check the type and extract the content
                if ($type eq 'ol') {
                    if ($expansion =~ /^\s*\d+\s*(.*)$/) {
                        $expansion = $1;
                    }
                }
                if ($type eq 'ul') {
                    if ($expansion =~ /^\s*\*{1}\s*(.*)$/) {
                        $expansion = $1;
                    }
                }
            }

            # we print the item... but we don't close it!
            # it get's closed by the next item or the =back call
            print $out_fh '<li>' . $expansion;
        }
    }
}

# Overwrite sub of Pod::Parser
# Here all code parts of POD get parsed
sub verbatim { 
    my ($parser, $paragraph, $line_num) = @_; 
    my $out_fh = $parser->output_handle();       # handle for parsing output

    # We have to escape the case where there is only a newline, because
    # Pod::Parser calls verbatim() with $paragraph="\n" every time an empty
    # line is found in the Pod. But that is not what we are looking for!
    # We are looking for code-blocks here...
    if ($paragraph eq "\n") { return }

    # we look for POD inline commands
    my $expansion = $parser->interpolate($paragraph, $line_num);
    # then for special chars
    $expansion = _html_enc($expansion);
    # and last but not least we replace whitespace with a HTML tag.
    # this we do only for the verbatim command!
    # this is so, that code format (indenting) is keeped in html
    $expansion = _nbsp($expansion);

    # also only in verbatim we replace newline with the <br /> tag
    # this is so, that code format is keeped in html
    $expansion =~ s/\n/<br \/>\n/g;

    # trim must be last,
    # otherwise _nbsp() is not working for the first line
    trim $expansion;

    # ok, we are done and print out the result
    print $out_fh '<code>' . $expansion . '</code>' . "\n";
}

# Overwrite sub of Pod::Parser
# Here normal POD text paragraphs get parsed
sub textblock { 
    my ($parser, $paragraph, $line_num) = @_; 
    my $out_fh = $parser->output_handle();       # handle for parsing output

    # ok, this one is tricky...
    # textblock() can be called when the parser is actually parsing a list.
    # this happens if the list is written like that:
    # =over
    #
    # =item
    #
    # Text that appears in this sub as $paragraph
    #
    # =back
    # If the text is on the SAME LINE as the =item command, this will not
    # happen. It is only when the text is separated with newline.
    # Ok... we need to check here if we are in a list.. and then do some
    # stuffe to handle that case.

    # we translate the POD inline commands...
    my $expansion = $parser->interpolate($paragraph, $line_num);
    # remove leading and trailing whitespace...
    trim $expansion;
    # and translate special chars to HTML
    $expansion = _html_enc($expansion);

    # store the list-nesting in a local variable (just for readability)
    my $lvl = $parser->{+P . 'listlvl'};

    # if there is no list WE ARE LUCKY and just print the text as paragraph
    if (not exists $parser->{+P . 'list'}) {
        print $out_fh '<p>' . $expansion . '</p>' . "\n";
    }
    # NOOOOOOO... we have a list
    # ok... let's try to figure out what to do!

    # items and some content found already in the command...
    # ... so we add a <br /> before the following textblock.
    elsif ($parser->{+P . 'list'}->[$lvl]->{items} > 0
           and $parser->{+P . 'list'}->[$lvl]->{contentInCmd} == 1
           ) {
        print $out_fh '<br />' . $expansion;
    }
    # if there was not yet content found we just print what we have now
    elsif ($parser->{+P . 'list'}->[$lvl]->{items} > 0) {
        print $out_fh $expansion;
    }
    # if there where no items yet this can only mean that we are in a list
    # without any items but with pure text... so we do blockquotes for
    # each paragraph
    elsif ($parser->{+P . 'list'}->[$lvl]->{items} == 0) {

        # we set the listtype
        $parser->{+P . 'list'}->[$lvl]->{type} = 'blockquote';
        $parser->{+P . 'list'}->[$lvl]->{blockquotes}++;

        if ($parser->{+P . 'list'}->[$lvl]->{blockquotes} == 1
            and $lvl > 0
            and $parser->{+P . 'list'}->[$lvl-1]->{items} > 0
            ) {
            print $out_fh "</li>\n";
        }

        # we do some pseudo-indenting
        # TODO: more nice would be real nesting...
        for (0..$lvl) {
            print $out_fh '<blockquote>';
        }
        print $out_fh $expansion;
        for (0..$lvl) {
            print $out_fh '</blockquote>' ."\n";
        }
    }
    else {
        # we should not reach here...
        croak "POD parsing error. Found undefined textblock in a list.";
    }
}

# Overwrite sub of Pod::Parser
# This method is called for handling inline POD, like e.g. B<some text>
sub interior_sequence {
    my ($parser, $cmd, $arg) = @_;

    # IMPORTANT here we do some tricky stuff...
    # what we actually want is this:
    #     B<some text>   ->   <b>some text</b>
    # but this is not possible, because then the <> would be replaced by
    # HTML entities later on!
    # So that is why we replace like this:
    #     <   ->   constant: LT
    # and
    #     >   ->   constant: GT
    # So B<some text> becomes XLTXsome textXGTX
    # The function which is doing the HTML translation must then replace
    # this words again with < and > (this is what _html_enc() is doing)
    return LT . 'b'    . GT . $arg . LT . '/b'    . GT  if ($cmd eq 'B');
    return LT . 'code' . GT . $arg . LT . '/code' . GT  if ($cmd eq 'C');
    return LT . 'code' . GT . $arg . LT . '/code' . GT  if ($cmd eq 'F');
    return LT . 'i'    . GT . $arg . LT . '/i'    . GT  if ($cmd eq 'I');
    return              AMP . $arg . COL                if ($cmd eq 'E');
    return LT.'a href='.QUO.$arg.QUO.GT.$arg.LT.'/a'.GT if ($cmd eq 'L');

    # if nothing matches we return the content unformated 'as is'
    return $arg;
}

sub html_body {
    my ($self, $boolean) = @_;

    $self->{+P . 'body'} = $boolean;
}

sub pagemode {
    my ($self, $boolean) = @_;

    $self->{+P . 'pages'} = $boolean;
}

sub head0_mode {
    my ($self, $boolean) = @_;

    $self->{+P . 'head0_mode'} = $boolean;
}

sub debug_on {
    my ($self, $ref_to_debug_sub) = @_; 

    $self->{ref_to_debug_sub} = $ref_to_debug_sub;
    
    &$ref_to_debug_sub('DEBUG mode on');
}

sub debug_off {
    my ($self) = @_; 

    if ($self->{ref_to_debug_sub}) {
        &{$self->{ref_to_debug_sub}}('DEBUG mode off');
        $self->{ref_to_debug_sub} = 0;
    }
}

# Internal debug method
sub _debug {
    my ($self,$msg) = @_; 

    if ($self->{ref_to_debug_sub}) {
        &{$self->{ref_to_debug_sub}}($msg);
    }   
}

# encode_entities() from HTML::Entities does not translate it correctly
# this is why I make it here manually as a quick fix
# don't reall know where how to handle this utf8 problem for now...
sub _html_enc {
    my $string = shift;

    $string = encode_entities($string);
                            #    ^
    my $lt = LT;            #    |
    my $gt = GT;            #    |
    my $am = AMP;           #    |
    my $co = COL;           #    |-- don't change this order!
    my $qu = QUO;           #    |
    $string =~ s/$lt/</g;   #    |
    $string =~ s/$gt/>/g;   #    |
    $string =~ s/$am/&/g;   #    |
    $string =~ s/$co/;/g;   #    |
    $string =~ s/$qu/'/g;   #<---|

    return $string;
}

# replaces whitespace with html entitie
sub _nbsp {
    my $string = shift;

    $string =~ s/\ /&nbsp;/g;

    return $string;
}

1;

__END__

=encoding utf8

=head1 NAME

EBook::MOBI::Pod2Mhtml - Create HTML, flavoured for the MOBI format, out of POD.

This module extends L<Pod::Parser> for parsing capabilities. The module L<HTML::Entities> is used to translate chars to HTML entities.

=head1 SYNOPSIS

  use EBook::MOBI::Pod2Mhtml;
  my $p2h = new EBook::MOBI::Pod2Mhtml;

  # $pod_h and $html_out_h are file handles
  # or IO::String objects
  $p2h->parse_from_filehandle($pod_h, $html_out_h);

  # result is now in $html_out_h

=head1 METHODS

=head2 parse_from_filehandle

This is the method you need to call, if you want this module to be of any help for you. It will take your data in the POD format and return it in special flavoured HTML, which can be then further used for the MOBI format.

Hand over two file handles or Objects of L<IO::String>. The first handle points to your POD, the second waits to receive the result.

  # $pod_h and $html_out_h are file handles
  # or IO::String objects
  $p2h->parse_from_filehandle($pod_h, $html_out_h);

  # result is now in $html_out_h

=head2 pagemode

Pass any true value to enable 'pagemode'. The effect will be, that before every - but the first - '=head1' there will be a peagebreak inserted. This means: The resulting eBook will start each head1 chapter at a new page.

  $p2h->pagemode(1);

Default is to not add any pagebreak.

=head2 head0_mode

Pass any true value to enable 'head0_mode'. The effect will be, that you are allowed to use a '=head0' command in your POD.

  $p2h->head0_mode(1);

Pod can now look like this:

  =head0 Module EBook::MOBI
  
  =head1 NAME

  =head1 SYNOPSIS

  =head0 Module EBook::MOBI::Pod2Mhtml

  =head1 NAME

  =head1 SYNOPSIS

  =cut

This feature is useful if you want to have the documentation of several modules in Perl in one eBook. You then can add a higher level of titles, so that the TOC does not only contain several NAME and SYNOPSIS entries.

Default is to ignore any '=head0' command.

=head2 html_body

Pass any true value to enable 'html_body'. If set, parsed content will be encapsulated in a HTML body tag. You may want this if you parse all data at once. But if there is more to add, you should not use this mode, you then will just get HTML markup which is not encapsulated in a body tag.

  $p2h->html_body(1);

Default is to not encapsulate in a body tag.

=head2 debug_on

You can just ignore this method if you are not interested in debuging!

Pass a reference to a debug subroutine and enable debug messages.

=head2 debug_off

Stop debug messages and erease the reference to the subroutine.

=head2 INHERITED INTERNAL METHODS

=head3 begin_input

Inherited from L<Pod::Parser>. Gets called when POD-input starts.

=head3 command

Inherited from L<Pod::Parser>. Gets called when a command is found.

=head3 end_input

Inherited from L<Pod::Parser>. Gets called when POD-input ends.

=head3 interior_sequence

Inherited from L<Pod::Parser>. Gets called for inline replacements..

=head3 textblock

Inherited from L<Pod::Parser>. Gets called for text sections.

=head3 verbatim

Inherited from L<Pod::Parser>. Gets called for code sections..

=head1 COPYRIGHT & LICENSE

Copyright 2011 Boris Däppen, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms of Artistic License 2.0.

=head1 AUTHOR

Boris Däppen E<lt>boris_daeppen@bluewin.chE<gt>

=cut
