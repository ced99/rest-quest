package TestMap;

use Carp;
use File::Slurp;
use Moose;

use namespace::autoclean;

has 'tiles', is => 'ro', isa => 'HashRef[CED::RQ::Tile]', default => sub { {} };

sub from_file {
    my ($cls, $fname) = @_;
    my @lines = read_file($fname) or croak "Could not read $fname";

    my $tiles = {};
    my $x = 0;
    my $y = 0;
    foreach my $line (@lines) {
        $line =~ s/\s+$//;
        next unless $line;
        foreach my $char (split '', $line) {
            my ($type, $castle, $treasure) = ('grass', '', 0);

            if ($char eq 'g') {
                $type = 'grass';
            } elsif ($char eq 'f') {
                $type = 'forrest';
            } elsif ($char eq 'm') {
                $type = 'mountain';
            } elsif ($char eq 'w') {
                $type = 'water';
            } elsif ($char eq 'h') {
                $castle = 'own';
            } elsif ($char eq 'e') {
                $castle = 'enemy';
            } elsif ($char eq 't') {
                $treasure = 1;
            } else {
                croak "Can not read tile of type $char";
            }
            my $tile = CED::RQ::Tile->new(
                x => $x, y => $y,
                type => $type, castle => $castle, treasure => $treasure
                );
            $tiles->{$tile->key} = $tile;
            $x++;
        }
        $y++;
    }
    return $cls->new(tiles => $tiles);
}
__PACKAGE__->meta->make_immutable;

1;
