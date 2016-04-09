#!/usr/bin/env perl

use Acme::MetaSyntactic;
use Getopt::Long;
use Log::Any::Adapter;
Log::Any::Adapter->set('Stdout');

use CED::RQ::Client;

my $name;
my $baseurl;
my $mode;

GetOptions (
    'name=s' => \$name,
    'url=s'  => \$baseurl,
    'mode=s' => \$mode
    );

$baseurl ||= 'http://localhost:3000';
$name ||= Acme::MetaSyntactic->new('legomarvelsuperheroes')->name;
$mode ||= 'auto';

$baseurl =~ s{/$}{};
my $client = CED::RQ::Client->new(
    name => $name, baseurl => $baseurl, mode => lc $mode
    );

$client->play();

exit 0;
