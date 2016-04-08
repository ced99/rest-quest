package TestMap;

use Carp;
use File::Slurp;
use Geometry::AffineTransform;
use Moose;

use CED::RQ::Tile;

use namespace::autoclean;

has 'name', is => 'ro', isa => 'Str', required => 1;
has 'tiles', is => 'ro', isa => 'HashRef[CED::RQ::Tile]',
    default => sub { {} };
has 'current', is => 'rw', isa => 'CED::RQ::Tile', required => 1;
has 'size_x', is => 'rw', isa => 'Int';
has 'size_y', is => 'rw', isa => 'Int';

sub from_file {
    my ($cls, $name, $fname) = @_;
    my @lines = read_file($fname) or croak "Could not read $fname";
    my $tiles = {};
    my $x = 0;
    my $y = 0;
    my $home;
    my $home_x;
    my $home_y;
    foreach my $line (@lines) {
        $x = 0;
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
                $home_x = $x;
                $home_y = $y;
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
            $home = $tile if ($castle eq 'own');
            $x++;
        }
        $y++;
    }
    return $cls->new(
        name => $name,
        tiles => $tiles,
        current => $home,
        size_x => $x,
        size_y => $y
        );
}

sub current_data {
    my ($self) = @_;

    my $result = [];
    my $tile = $self->current;
    my $limit = int($tile->vision_diameter / 2);
    foreach my $i (-$limit..$limit) {
        my $row = [];
        foreach my $j (-$limit..$limit) {
            my $x = $tile->x + $j;
            my $y = $tile->y + $i;
            $x %= $self->size_x;
            $y %= $self->size_y;
            my $key = CED::RQ::Tile->calc_key($x, $y);
            my $view_tile = $self->tiles->{$key};
            push @$row, {
                type => $view_tile->type,
                castle => (($view_tile->castle eq 'own')
                           ? $self->name
                           : $view_tile->castle),
                treasure => $view_tile->treasure
            };
        }
        push @$result, $row;
    }
    return $result;
}

sub up {
    my ($self) = @_;

    my $up_y = $self->current->y - 1;
    $up_y %= $self->size_y;
    my $key = CED::RQ::Tile->calc_key($self->current->x, $up_y);
    $self->current($self->tiles->{$key});
    return $self->current_data();
}

sub down {
    my ($self) = @_;

    my $down_y = $self->current->y + 1;
    $down_y %= $self->size_y;
    my $key = CED::RQ::Tile->calc_key($self->current->x, $down_y);
    $self->current($self->tiles->{$key});
    return $self->current_data();
}

sub left {
    my ($self) = @_;

    my $left_x = $self->current->x - 1;
    $left_x %= $self->size_x;
    my $key = CED::RQ::Tile->calc_key($left_x, $self->current->y);
    $self->current($self->tiles->{$key});
    return $self->current_data();
}

sub right {
    my ($self) = @_;

    my $right_x = $self->current->x + 1;
    $right_x %= $self->size_x;
    my $key = CED::RQ::Tile->calc_key($right_x, $self->current->y);
    $self->current($self->tiles->{$key});
    return $self->current_data();
}

__PACKAGE__->meta->make_immutable;

1;
