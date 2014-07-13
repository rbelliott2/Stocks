#!/usr/bin/perl

package Stocks::Quote;
use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request::Common;
use Text::CSV_XS;
use JSON;

sub new {
   my $this = shift;
   my $class = ref($this) || $this;
   my ($format, $debug) = @{{@_}}{qw/format debug/};
   my $self = {};

   bless($self,$class);

   $format = 'default' unless defined $format;
   $self->{'format'} = $format;

   $debug = 0 unless defined $debug;
   $self->{'debug'} = $debug;

   $self->{'lwp'} = LWP::UserAgent->new;
   $self->{'csv'} = Text::CSV_XS->new({binary => 1});

   return $self;    
}

sub getQuotes {
   my $self = shift;
   my ($symbols) = @{{@_}}{qw/symbols/};

   my $symbolUrl;

   if ( ref $symbols eq 'ARRAY' )
   {
      $symbolUrl = join('+',@{ $symbols });
   }
   elsif (ref $symbols ne 'HASH' and defined $symbols) 
   {
      $symbolUrl = $symbols;
   }
   else
   {
      return {success => 0, message => 'Invalid company symbol(s) provided'};
   }

   my $req = GET 'http://finance.yahoo.com/d/quotes.csv?s=' . $symbolUrl . '&f=snb2b3';

   my $res = $self->{'lwp'}->request($req);

   unless ($res->is_success)
   {
      return {success => 0, message => $res->status_line};
   }

   my $raw_csv = $res->content;

   my $quotes = {};

   foreach ( split ("\r\n", $raw_csv) )
   {
      $self->{'csv'}->parse($_);

      my ($symbol,$name,$ask,$bid) = $self->{'csv'}->fields();

      $quotes->{$symbol} = {
         name  => $name,
         ask   => $ask,
         bid   => $bid,
      };
   }

   return $self->_toXML($quotes) if ( $self->{'format'} eq 'xml' );
   return $self->_toJSON($quotes) if ( $self->{'format'} eq 'json' );

   return $quotes;
}

sub setFormat {
   my $self = shift;
   my $format = $_[0];

   if ($format eq 'xml')
   {
      $self->{'format'} = 'xml';
   }
   elsif ($format eq 'json')
   {
      $self->{'format'} = 'json';
   }
   else
   {
      $self->{'format'} = 'default';
   }

   return 1;
}

sub _toXML {
   my $self = shift;
   my $quotes = $_[0];

   my $xml = q{
<?xml version="1.0" encoding="UTF-8"?>
<quotes>};

   foreach ( sort keys %{ $quotes } )
   {
      $xml .= q{
   <quote>
      <symbol>} . $_ . q{</symbol>
      <name>} . $quotes->{$_}->{'name'} . q{</name>
      <ask>} . $quotes->{$_}->{'ask'} . q{</ask>
      <bid>} . $quotes->{$_}->{'bid'} . q{</bid>
   </quote>}
   }

   $xml .= q{
</quotes>};

   return $xml;
}

sub _toJSON {
   my $self = shift;
   my $quotes = $_[0];

   return to_json($quotes);
}

1;
