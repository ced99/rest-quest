#!/usr/bin/env perl
use Log::Any::Adapter;
Log::Any::Adapter->set('Stdout');

use CED::RQ::Map;
use CED::RQ::TargetNavigator;

use TestMap;
my $fname = $ARGV[0];

my $tmap = TestMap->from_file($fname);
my $map = CED::RQ::Map->new(name => 'foobar');

my $nav = CED::RQ::TargetNavigator->new(map => $map, target => $map->home);

print "Start navigating\n";

while ($map->current->key ne $map->home->key) {
    my $dir = $nav->calc_move();
    print "\t$dir\n";
    $map->$dir([]);
}

print "Done\n";
