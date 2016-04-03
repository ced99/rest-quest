#!/usr/bin/env perl

use CED::RQ::Map;
use CED::RQ::HomeNavigator;

my $map = CED::RQ::Map->new(name => 'foobar');

my $view = [];
foreach my $y (1..13) {
    my $row = [];
    foreach my $x (1..13) {
        my $type = 'grass';
        if (($x > 5) && (8 > $x)) {
            if (($y > 5) && (8 > $y)) {
                $type = 'water';
            }
        } elsif ($x == 4) {
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
    $map->$dir();
}

print "Done\n";
