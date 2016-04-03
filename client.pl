#!/usr/bin/env perl

use Acme::MetaSyntactic;
use Getopt::Long;

use CED::RQ::Client;


my $name;
my $baseurl;

GetOptions (
    'name=s' => \$name,
    'url=s'   => \$baseurl
    );

$baseurl ||= 'http://localhost:3000';
$name ||= Acme::MetaSyntactic->new('legomarvelsuperheroes')->name;

$baseurl =~ s{/$}{};
my $client = CED::RQ::Client->new(name => $name, baseurl => $baseurl);

$client->play();

exit 0;
