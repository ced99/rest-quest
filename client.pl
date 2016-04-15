#!/usr/bin/env perl

use Acme::MetaSyntactic;
use Getopt::Long;
use Log::Any::Adapter;
Log::Any::Adapter->set('Stdout');

use CED::RQ::Client;

my $name;
my $baseurl;
my $replay;

GetOptions (
    'name=s' => \$name,
    'url=s'  => \$baseurl,
    'replay=i' => \$replay
    );

$baseurl ||= 'http://localhost:3000';
$name ||= Acme::MetaSyntactic->new('legomarvelsuperheroes')->name;
$replay ||= 1;

my %results;
$baseurl =~ s{/$}{};

while ($replay--) {
    my $client = CED::RQ::Client->new(
        name => $name, baseurl => $baseurl
        );

    $client->play();
    $results{$client->final_state}++;
    $client->reset();
    print "Current results for $name:\n";
    foreach (sort keys %results) {
        print "\t$_: " . $results{$_} . "\n"
    }
}

exit 0;
