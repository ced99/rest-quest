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
    'replay!' => \$replay
    );

$baseurl ||= 'http://localhost:3000';
$name ||= Acme::MetaSyntactic->new('legomarvelsuperheroes')->name;

my %results;
$baseurl =~ s{/$}{};

$SIG{INT} = $SIG{TERM} = sub {$replay = 0};

do {
    my $client = CED::RQ::Client->new(
        name => $name, baseurl => $baseurl
        );

    $client->play();
    $results{$client->final_state}++;
    $client->reset();
    if ($replay) {
        print "Current results for $name:\n";
        foreach (sort keys %results) {
            print "\t$_: " . $results{$_} . "\n"
        }
    }
} while ($replay);

exit 0;
