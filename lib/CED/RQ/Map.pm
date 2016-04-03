package CED::RQ::Map;

use Geometry::AffineTransform;
use Moose;
use Log::Any qw($log);

use CED::RQ::Tile;

use namespace::autoclean;

has 'name', is => 'ro', isa => 'Str', required => 1;
has 'tiles', is => 'ro', isa => 'HashRef[CED::RQ::Tile]',
    default => sub { {} };
has 'current', is => 'rw', isa => 'CED::RQ::Tile';
has 'home', is => 'rw', isa => 'CED::RQ::Tile';

has 'treasures', is => 'ro', isa => 'HashRef[CED::RQ::Tile]',
    default => sub { {} };

my %_rev_directions = (
    up => 'down',
    down => 'up',
    left => 'right',
    right => 'left',
    );

sub _add_tile {
    my ($self, $x, $y, $raw) = @_;

    my $tile = CED::RQ::Tile->new(
        x => $x,
        y => $y,
        type => $raw->{type},
        castle => (
            $raw->{castle}
            ? (($raw->{castle} eq $self->name)
               ? 'own'
               : 'enemy'
            )
            : ''
        ),
        treasure => ($raw->{treasure} ? 1 : 0)
        );
    $self->tiles->{$tile->key} = $tile;
    if ($tile->treasure) {
        $log->infof(
            '%s: spotted treasure at %d/%d', $self->name, $tile->x, $tile->y
            );
        $self->treasures->{$tile->key} = $tile;
    }
    return $tile;
}

sub _link_edge {
    my ($self, $tile, $other_key, $direction) = @_;

    if (my $other = $self->tiles->{$other_key}) {
        my $edge = CED::RQ::Edge->new(source => $tile, target => $other);
        $tile->$direction($edge);
        my $rev_direction = $_rev_directions{$direction};
        my $rev_edge = CED::RQ::Edge->new(source => $other, target => $tile);
        $other->$rev_direction($rev_edge);
    }

    return;
}

sub _link_edges {
    my ($self, $tile) = @_;

    my $up_key = CED::RQ::Tile->calc_key($tile->x, $tile->y - 1);
    $self->_link_edge($tile, $up_key, 'up');

    my $down_key = CED::RQ::Tile->calc_key($tile->x, $tile->y + 1);
    $self->_link_edge($tile, $down_key, 'down');

    my $left_key = CED::RQ::Tile->calc_key($tile->x - 1, $tile->y);
    $self->_link_edge($tile, $left_key, 'left');

    my $right_key = CED::RQ::Tile->calc_key($tile->x + 1, $tile->y);
    $self->_link_edge($tile, $right_key, 'right');

    return;
}

sub _tile_coordinates {
    my ($self, $x, $y, $diameter) = @_;

    my $radius = int($diameter / 2);
    my $t = Geometry::AffineTransform->new();
    $t->translate($x - $radius, $y - $radius);

    my @result;
    foreach my $view_y (0 .. ($diameter - 1)) {
        foreach my $view_x (0 .. ($diameter - 1)) {
            push @result, [$t->transform($view_x, $view_y)];
        }
    }
    return $t, @result;
}

sub _view_changed {
    my ($self, $x_center, $y_center, $data) = @_;

    my @new_tiles;
    my ($trans, @coords) =
        $self->_tile_coordinates($x_center, $y_center, scalar(@$data));

    $trans->invert();
    foreach (@coords) {
        my ($x, $y) = @$_;
        my $key = CED::RQ::Tile->calc_key($x, $y);
        my ($view_x, $view_y) = $trans->transform($x, $y);
        my $view_tile = $data->[$view_y]->[$view_x];

        unless ($self->tiles->{$key}) {
            my ($view_x, $view_y) = $trans->transform($x, $y);
            my $view_tile = $data->[$view_y]->[$view_x];
            push @new_tiles, $self->_add_tile($x, $y, $view_tile);
        }
        if ($self->treasures->{$key} && !$view_tile->{treasure}) {
            $log->infof(
                '%s: treasure at %d/%d taken by enemy',
                $self->name, $x, $y
                );
            $self->treasures->{$key}->treasure(0);
            delete $self->treasures->{$key};
        }
    }

    $self->current(
        $self->tiles->{CED::RQ::Tile->calc_key($x_center, $y_center)}
        );
    $self->current->visited(1);
    $self->_link_edges($_) foreach @new_tiles;

    ### XXX fold map if castle spotted?

    return scalar(@new_tiles);
}

sub init {
    my ($self, $data) = @_;

    $self->_view_changed(0, 0, $data);
    $self->home($self->current);

    return;
}

sub up {
    my ($self, $data) = @_;

    $self->_view_changed( $self->current->x, $self->current->y - 1, $data);
    return;
}

sub down {
    my ($self, $data) = @_;

    $self->_view_changed( $self->current->x, $self->current->y + 1, $data);
    return;
}

sub left {
    my ($self, $data) = @_;

    $self->_view_changed( $self->current->x - 1, $self->current->y, $data);
    return;
}

sub right {
    my ($self, $data) = @_;

    $self->_view_changed( $self->current->x + 1, $self->current->y, $data);
    return;
}

sub vision_size {
    my ($self) = @_;

    return scalar(keys %{$self->tiles});
}

sub possible_vision_size {
    my ($self, $x, $y) = @_;

    my %result = map {$_ => 1} keys %{$self->tiles};
    my $key = CED::RQ::Tile->calc_key($x, $y);
    my $tile = $self->tiles->{$key};

    my (undef, @coords) = $self->_tile_coordinates(
        $x, $y, $tile->vision_diameter
        );
    foreach (@coords) {
        my ($x, $y) = @$_;
        my $key = CED::RQ::Tile->calc_key($x, $y);
        $result{$key} = 1;
    }
    return scalar(keys %result);
}

__PACKAGE__->meta->make_immutable();

1
