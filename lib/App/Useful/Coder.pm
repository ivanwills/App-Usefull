package App::Useful::Coder;

# Created on: 2019-03-20 15:40:34
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use MIME::Base64 qw/encode_base64 decode_base64/;
use MIME::QuotedPrint qw/encode_qp decode_qp/;
use JSON::XS qw/decode_json encode_json/;
use base qw/Exporter/;

our $VERSION     = version->new('0.0.1');
our @EXPORT_OK   = qw/html_codes coder get_coders/;
our %EXPORT_TAGS = ();
our @EXPORT      = qw/get_coders/;

sub coder {
    my ($type, $dir, $data, $option) = @_;

    return {get_coders($option || {})}->{$type}{$dir}($data);
}

sub get_coders {
    my ($option) = @_;
    return (
        bash => {
            encode    => sub { chomp $_[0]; $_[0] =~ s/'/'\\''/g; return "'$_[0]'\n" },
            encode_on => 'line',
            decode    => sub {},
            decode_on => 'line',
        },
        base64 => {
            encode    => \&encode_base64,
            encode_on => 'whole',
            decode    => \&decode_base64,
            decode_on => 'line',
        },
        quoted_printable => {
            encode    => \&encode_qp,
            encode_on => 'whole',
            decode    => \&decode_qp,
            decode_on => 'line',
        },
        html => {
            encode    => sub {
                $option->{quote} ||= '"';
                my $matcher =
                      $option->{level} == 3 ? qr{ .       }xms
                    : $option->{level} == 2 ? qr{ \W      }xms
                    : $option->{level} == 1 ? qr{ [<!$option->{quote}=>] }xms
                    : $option->{level} == 0 ? qr{ [<$option->{quote}>]   }xms
                    :                         qr{ [<$option->{quote}>]   }xms;
                my %codes = html_codes();
                $_[0] =~ s/($matcher)/$codes{$1} || sprintf "&#%d;", ord $1/egxms;
                return $_[0]
            },
            encode_on => 'line',
            decode    => sub {
                my %codes = reverse html_codes();
                $_[0] =~ s/(\&[a-z]\w+;)/$codes{$1} || $1/egxms;
                $_[0] =~ s/\&\#([\da-fA-F]+);/chr $1/egxms;
                return $_[0]
            },
            decode_on => 'line',
        },
        http => {
            encode    => sub { $_[0] =~ s/([^\w])/sprintf "%%%x", ord $1/egxms; return $_[0] },
            encode_on => 'word',
            decode    => sub { $_[0] =~ s/%([\da-fA-F]{2})/chr hex $1/egxms; return $_[0] },
            decode_on => 'word',
        },
        url => {
            encode    => sub {
                my $matcher =
                      $option->{level} == 3 ? qr{  .     }xms
                    : $option->{level} == 2 ? qr{  \W    }xms
                    : $option->{level} == 1 ? qr{ [\W/:] }xms
                    : $option->{level} == 0 ? qr{ [\W]   }xms
                    :                         qr{ [\W]   }xms;
                s/($matcher)/sprintf('%%%x',ord($1))/eg;
                $_;
            },
            encode_on => 'word',
            decode    => sub {
                my $count = 0;
                while ( /%/ && $count++ < 10 ) {
                    s/%([\da-fA-F][\da-fA-F])/sprintf('%c',(hex($1)))/eg;
                }
                $_;
            },
            decode_on => 'word',
        },
        hex => {
            # hex => dec
            encode => sub {
                sprintf "%x\n", $_ if defined $_ && $_ =~ /^\d+$/;
            },
            encode_on => 'word',
            # dec => hex
            decode    => sub {
                sprintf "%i\n", hex $_ if defined $_ && $_ =~ /^\d+$/;
            },
        },
        colour => {
            encode    => \&colour,
            encode_on => 'whole',
            decode    => \&colour,
            decode_on => 'whole',
        },
        json => {
            encode => \&encode_json,
            encode_on => 'whole',
            decode => \&decode_json,
            decode_on => 'whole',
        }
    );
}

sub colour {
    my ($r, $g, $b, $a);
    chomp;
    my $hex = qr/[A-Fa-f0-9]/;
    my $num = qr/(?: \s* (\d+) \s* (?: , \s* )? )/xms;

    if ( ($r, $g, $b, $a) = /^#($hex{2})($hex{2})($hex{2})($hex{2})?$/ ) {
        return $a
            ? sprintf "rgb(%i, %i, %i, %i)", hex $r, hex $g, hex $b, hex $a
            : sprintf "rgb(%i, %i, %i)",     hex $r, hex $g, hex $b;
    }
    elsif ( ($r, $g, $b, $a) = /^#($hex)($hex)($hex)($hex)?$/ ) {
        return $a
            ? sprintf "rgb(%i, %i, %i, %i)", hex "$r$r", hex "$g$g", hex "$b$b", hex "$a$a"
            : sprintf "rgb(%i, %i, %i)",     hex "$r$r", hex "$g$g", hex "$b$b";
    }
    elsif ( ($r, $g, $b) = /^rgb \s* [(] $num $num $num [)] $/ixms ) {
        return  sprintf "#%02X%02X%02X",     $r, $g, $b;
    }
    elsif ( ($r, $g, $b, $a) = /^rgba \s* [(] \s* $num $num $num $num [)] $/ixms ) {
        return sprintf "#%02X%02X%02X%02X", $r, $g, $b, $a;
    }
    return "unknown $_";
}

sub html_codes {
    return (
        '"' => '&quot;', #	quotation mark
        '\''=> '&apos;', #	apostrophe
        '&' => '&amp;', #	ampersand
        '<' => '&lt;', #	less-than
        '>' => '&gt;', #	greater-than
        ' ' => '&nbsp;', #	non-breaking space
        '¡' => '&iexcl;', #	inverted exclamation mark
        '¢' => '&cent;', #	cent
        '£' => '&pound;', #	pound
        '¤' => '&curren;', #	currency
        '¥' => '&yen;', #	yen
        '¦' => '&brvbar;', #	broken vertical bar
        '§' => '&sect;', #	section
        '¨' => '&uml;', #	spacing diaeresis
        '©' => '&copy;', #	copyright
        'ª' => '&ordf;', #	feminine ordinal indicator
        '«' => '&laquo;', #	angle quotation mark (left)
        '¬' => '&not;', #	negation
        '­' => '&shy;', #	soft hyphen
        '®' => '&reg;', #	registered trademark
        '¯' => '&macr;', #	spacing macron
        '°' => '&deg;', #	degree
        '±' => '&plusmn;', #	plus-or-minus
        '²' => '&sup2;', #	superscript 2
        '³' => '&sup3;', #	superscript 3
        '´' => '&acute;', #	spacing acute
        'µ' => '&micro;', #	micro
        '¶' => '&para;', #	paragraph
        '·' => '&middot;', #	middle dot
        '¸' => '&cedil;', #	spacing cedilla
        '¹' => '&sup1;', #	superscript 1
        'º' => '&ordm;', #	masculine ordinal indicator
        '»' => '&raquo;', #	angle quotation mark (right)
        '¼' => '&frac14;', #	fraction 1/4
        '½' => '&frac12;', #	fraction 1/2
        '¾' => '&frac34;', #	fraction 3/4
        '¿' => '&iquest;', #	inverted question mark
        '×' => '&times;', #	multiplication
        '÷' => '&divide;', #	division
        'À' => '&Agrave;', #	capital a, grave accent
        'Á' => '&Aacute;', #	capital a, acute accent
        'Â' => '&Acirc;', #	capital a, circumflex accent
        'Ã' => '&Atilde;', #	capital a, tilde
        'Ä' => '&Auml;', #	capital a, umlaut mark
        'Å' => '&Aring;', #	capital a, ring
        'Æ' => '&AElig;', #	capital ae
        'Ç' => '&Ccedil;', #	capital c, cedilla
        'È' => '&Egrave;', #	capital e, grave accent
        'É' => '&Eacute;', #	capital e, acute accent
        'Ê' => '&Ecirc;', #	capital e, circumflex accent
        'Ë' => '&Euml;', #	capital e, umlaut mark
        'Ì' => '&Igrave;', #	capital i, grave accent
        'Í' => '&Iacute;', #	capital i, acute accent
        'Î' => '&Icirc;', #	capital i, circumflex accent
        'Ï' => '&Iuml;', #	capital i, umlaut mark
        'Ð' => '&ETH;', #	capital eth, Icelandic
        'Ñ' => '&Ntilde;', #	capital n, tilde
        'Ò' => '&Ograve;', #	capital o, grave accent
        'Ó' => '&Oacute;', #	capital o, acute accent
        'Ô' => '&Ocirc;', #	capital o, circumflex accent
        'Õ' => '&Otilde;', #	capital o, tilde
        'Ö' => '&Ouml;', #	capital o, umlaut mark
        'Ø' => '&Oslash;', #	capital o, slash
        'Ù' => '&Ugrave;', #	capital u, grave accent
        'Ú' => '&Uacute;', #	capital u, acute accent
        'Û' => '&Ucirc;', #	capital u, circumflex accent
        'Ü' => '&Uuml;', #	capital u, umlaut mark
        'Ý' => '&Yacute;', #	capital y, acute accent
        'Þ' => '&THORN;', #	capital THORN, Icelandic
        'ß' => '&szlig;', #	small sharp s, German
        'à' => '&agrave;', #	small a, grave accent
        'á' => '&aacute;', #	small a, acute accent
        'â' => '&acirc;', #	small a, circumflex accent
        'ã' => '&atilde;', #	small a, tilde
        'ä' => '&auml;', #	small a, umlaut mark
        'å' => '&aring;', #	small a, ring
        'æ' => '&aelig;', #	small ae
        'ç' => '&ccedil;', #	small c, cedilla
        'è' => '&egrave;', #	small e, grave accent
        'é' => '&eacute;', #	small e, acute accent
        'ê' => '&ecirc;', #	small e, circumflex accent
        'ë' => '&euml;', #	small e, umlaut mark
        'ì' => '&igrave;', #	small i, grave accent
        'í' => '&iacute;', #	small i, acute accent
        'î' => '&icirc;', #	small i, circumflex accent
        'ï' => '&iuml;', #	small i, umlaut mark
        'ð' => '&eth;', #	small eth, Icelandic
        'ñ' => '&ntilde;', #	small n, tilde
        'ò' => '&ograve;', #	small o, grave accent
        'ó' => '&oacute;', #	small o, acute accent
        'ô' => '&ocirc;', #	small o, circumflex accent
        'õ' => '&otilde;', #	small o, tilde
        'ö' => '&ouml;', #	small o, umlaut mark
        'ø' => '&oslash;', #	small o, slash
        'ù' => '&ugrave;', #	small u, grave accent
        'ú' => '&uacute;', #	small u, acute accent
        'û' => '&ucirc;', #	small u, circumflex accent
        'ü' => '&uuml;', #	small u, umlaut mark
        'ý' => '&yacute;', #	small y, acute accent
        'þ' => '&thorn;', #	small thorn, Icelandic
        'ÿ' => '&yuml;', #	small y, umlaut mark
    );
}

1;

__END__

=head1 NAME

App::Useful::Coder - <One-line description of module's purpose>

=head1 VERSION

This documentation refers to App::Useful::Coder version 0.0.1


=head1 SYNOPSIS

   use App::Useful::Coder;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

A full description of the module and its features.

May include numerous subsections (i.e., =head2, =head3, etc.).


=head1 SUBROUTINES/METHODS

A separate section listing the public components of the module's interface.

These normally consist of either subroutines that may be exported, or methods
that may be called on objects belonging to the classes that the module
provides.

Name the section accordingly.

In an object-oriented module, this section should begin with a sentence (of the
form "An object of this class represents ...") to give the reader a high-level
context to help them understand the methods that are subsequently described.


=head3 C<new ( $search, )>

Param: C<$search> - type (detail) - description

Return: App::Useful::Coder -

Description:

=cut


=head1 DIAGNOSTICS

A list of every error and warning message that the module can generate (even
the ones that will "never happen"), with a full explanation of each problem,
one or more likely causes, and any suggested remedies.

=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the module, including
the names and locations of any configuration files, and the meaning of any
environment variables or properties that can be set. These descriptions must
also include details of any configuration language used.

=head1 DEPENDENCIES

A list of all of the other modules that this module relies upon, including any
restrictions on versions, and an indication of whether these required modules
are part of the standard Perl distribution, part of the module's distribution,
or must be installed separately.

=head1 INCOMPATIBILITIES

A list of any modules that this module cannot be used in conjunction with.
This may be due to name conflicts in the interface, or competition for system
or program resources, or due to internal limitations of Perl (for example, many
modules that use source code filters are mutually incompatible).

=head1 BUGS AND LIMITATIONS

A list of known problems with the module, together with some indication of
whether they are likely to be fixed in an upcoming release.

Also, a list of restrictions on the features the module does provide: data types
that cannot be handled, performance issues and the circumstances in which they
may arise, practical limitations on the size of data sets, special cases that
are not (yet) handled, etc.

The initial template usually just has:

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2019 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
