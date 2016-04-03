#!/usr/bin/env perl

use CED::RQ::Map;
use CED::RQ::HomeNavigator;

my $map = CED::RQ::Map->new(name => 'foobar');

my $view = [];
foreach my $y (-6..6) {
    my $row = [];
    foreach my $x (-6..6) {
        my $type = 'grass';
        if (($x >= -1) && ($x <= 1) && ($y == -1)) {
            $type = 'water';
        } elsif (($x == -1) && ($y >= -1) && ($y <= 1)) {
            $type = 'water';
        } elsif ($x == -5) {
            $type = 'mountain';
        } elsif ($x == -4 && $y == -3) {
            $type = 'mountain';
        }
        my $tile = {type => $type};
        push @$row, $tile;
    }
    push @$view, $row;
}

$map->init($view);
$map->left([]) foreach (1..5);
$map->up([]) foreach (1..6);


my $nav = CED::RQ::HomeNavigator->new(map => $map);

print "Start navigating\n";

while ($map->current->key ne $map->home->key) {
    my $dir = $nav->calc_move();
    print "\t$dir\n";
    $map->$dir([]);
}

print "Done\n";
