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
   $self->setFormat($format);

   $debug = 0 unless defined $debug;
   $self->{'debug'} = $debug;

   $self->{'lwp'} = LWP::UserAgent->new;
   $self->{'csv'} = Text::CSV_XS->new({binary => 1});

   return $self;    
}

sub getQuotes {
   my $self = shift;
   my ($symbols) = @{{@_}}{qw/symbols/};

   my $symbolUrl = $self->_toUrlCode($symbols);

   my $req = GET 'http://finance.yahoo.com/d/quotes.csv?s=' . $symbolUrl . '&f=snb2b3poyght8kjva2erv1s6';

   my $res = $self->{'lwp'}->request($req);

   return 0 unless ($res->is_success);

   my $quotes = {};

   foreach ( split ("\r\n", $res->content) )
   {
      $self->{'csv'}->parse($_);

      my ($symbol,$name,$ask,$bid,$close,$open,$yield,$low,$high,$target,$high52,$low52,$volume,$avgVol,$eps,$pe,$holdings,$revenue) = $self->{'csv'}->fields();

      $quotes->{$symbol} = {
         name     => $name,
         ask      => $ask,
         bid      => $bid,
         close    => $close,
         open     => $open,
         yield    => $yield,
         low      => $low,
         high     => $high,
         target   => $target,
         low52    => $low52,
         high52   => $high52,
         volume   => $volume,
         volAvg   => $avgVol,
         pe       => $pe,
         holdings => $holdings,
         revenue  => $revenue,
      };
   }

   return $self->_toXML($quotes) if ( $self->{'format'} eq 'xml' );
   return $self->_toJSON($quotes) if ( $self->{'format'} eq 'json' );
   return $res->content if ( $self->{'format'} eq 'csv' );

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
   elsif ($format eq 'csv')
   {
      $self->{'format'} = 'csv';
   }
   else
   {
      $self->{'format'} = 'default';
   }

   return 1;
}

sub _toUrlCode {
   my $self = shift;
   my $symbols = $_[0];

   if ( ref $symbols eq 'ARRAY' )
   {
      return join('+',@{ $symbols });
   }
   elsif ( ref $symbols eq '' ) 
   {
      return $symbols;
   }

   return 'DOW';
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
      <close>} . $quotes->{$_}->{'close'} . q{</close>
      <open>} . $quotes->{$_}->{'open'} . q{</open>
      <yield>} . $quotes->{$_}->{'yield'} . q{</yield>
      <target>} . $quotes->{$_}->{'target'} . q{</target>
      <low>} . $quotes->{$_}->{'low'} . q{</low>
      <high>} . $quotes->{$_}->{'high'} . q{</high>
      <low52>} . $quotes->{$_}->{'low52'} . q{</low52>
      <high52>} . $quotes->{$_}->{'high52'} . q{</high52>
      <volume>} . $quotes->{$_}->{'volume'} . q{</volume>
      <volAvg>} . $quotes->{$_}->{'volAvg'} . q{</volAvg>
      <pe>} . $quotes->{$_}->{'pe'} . q{</pe>
      <holdings>} . $quotes->{$_}->{'holdings'} . q{</holdings>
      <revenue>} . $quotes->{$_}->{'revenue'} . q{</revenue>
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
