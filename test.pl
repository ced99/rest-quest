#!/usr/bin/env perl
use Log::Any::Adapter;
Log::Any::Adapter->set('Stdout');

use CED::RQ::Map;
use CED::RQ::TargetNavigator;

use TestMap;
my $fname = $ARGV[0];

my $tmap = TestMap->from_file('foobar', $fname);
my $map = CED::RQ::Map->new(name => 'foobar');
$map->init($tmap->current_data);

$map->up($tmap->up()) foreach(1..6);
$map->left($tmap->left()) foreach (1..6);
my $nav = CED::RQ::TargetNavigator->new(map => $map, target => $map->home);

print "Start navigating\n";

while ($map->current->key ne $map->home->key) {
    my $dir = $nav->calc_move();
    print "\t$dir\n";
    $map->$dir($tmap->$dir());
    $nav->consume($dir);
}

print "Done\n";
