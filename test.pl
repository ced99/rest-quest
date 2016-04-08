#!/usr/bin/env perl

use Log::Any::Adapter;
Log::Any::Adapter->set('Stdout');

use CED::RQ::Map;
use CED::RQ::TargetNavigator;

my $map = CED::RQ::Map->new(name => 'foobar');

my $view = [];
foreach my $y (-2..2) {
    my $row = [];
    foreach my $x (-2..2) {
        my $castle = '';
        my $type = 'grass';
        if ($x == 0 && $y == 0) {
            $castle = 'foobar';
        }
        my $tile = {type => $type, castle => $castle};
        push @$row, $tile;
    }
    push @$view, $row;
}

$map->init($view);
$map->left([]) foreach (1..2);
$map->up([]) foreach (1..2);

$view->[2]->[2]->{castle} = '';

$map->left($view) foreach (1..3);
$map->up($view) foreach (1..3);

$view->[0]->[2]->{castle} = 'foobar';
$map->up($view);

my $nav = CED::RQ::TargetNavigator->new(map => $map, target => $map->home);

print "Start navigating\n";

while ($map->current->key ne $map->home->key) {
    my $dir = $nav->calc_move();
    print "\t$dir\n";
    $map->$dir([]);
}

print "Done\n";
