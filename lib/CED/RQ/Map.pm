package CED::RQ::Map;

use Carp;
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
has 'enemy', is => 'rw', isa => 'CED::RQ::Tile';

has 'size_x', is => 'rw', isa => 'Int';
has 'size_y', is => 'rw', isa => 'Int';

has 'treasures', is => 'ro', isa => 'HashRef[CED::RQ::Tile]',
    default => sub { {} };

my %_rev_directions = (
    up => 'down',
    down => 'up',
    left => 'right',
    right => 'left',
    );

sub reversed {
    my ($self, $direction) = @_;

    return $_rev_directions{$direction};
}

sub _fold_x {
    my ($self, $size) = @_;

    croak "Folding x again by $size - this should not happen"
        if (defined $self->size_x);

    $log->info("Map seems to be $size tiles wide -> folding");
    $self->size_x($size);

    ### XXX implement me
    return;
}

sub _fold_y {
    my ($self, $size) = @_;

    croak "Folding y again by $size - this should not happen"
        if (defined $self->size_y);

    $log->info("Map seems to be $size tiles high -> folding");
    $self->size_y($size);

    ### XXX implement me
    return;
}

sub _fold {
    my ($self, @tiles_to_fold) = @_;

    my $x_size;
    my $y_size;
    foreach (@tiles_to_fold) {
        my ($orig, $alias) = @$_;
        if (!$x_size && ($orig->x != $alias->x)) {
            $x_size = abs($orig->x - $alias->x);
        }
        if (!$y_size && ($orig->y != $alias->y)) {
            $y_size = abs($orig->y - $alias->y);
        }
    }
    $self->_fold_x($x_size) if $x_size;
    $self->_fold_y($y_size) if $y_size;
    return;
}

sub _add_tile {
    my ($self, $x, $y, $raw) = @_;

    my @to_fold;
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
    if ($tile->castle eq 'home'){
        if ($self->home->key ne $tile->key) {
            push @to_fold, [$tile, $self->home];
        }
    }
    if ($tile->castle eq 'enemy ') {
        if ($self->enemy && ($self->enemy->key ne $tile->key)) {
            push @to_fold, [$tile, $self->enemy];
        } else {
            $self->enemy($tile);
        }
    }
    return $tile, @to_fold;
}

sub _link_edge {
    my ($self, $tile, $other_key, $direction) = @_;

    if (my $other = $self->tiles->{$other_key}) {
        my $edge = CED::RQ::Edge->new(source => $tile, target => $other);
        $tile->$direction($edge);
        my $rev_direction = $self->reversed($direction);
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
    my @tiles_to_fold;
    foreach (@coords) {
        my ($x, $y) = @$_;
        my $key = CED::RQ::Tile->calc_key($x, $y);
        my ($view_x, $view_y) = $trans->transform($x, $y);
        my $view_tile = $data->[$view_y]->[$view_x];

        unless ($self->tiles->{$key}) {
            my ($view_x, $view_y) = $trans->transform($x, $y);
            my $view_tile = $data->[$view_y]->[$view_x];
            my ($new_tile, @to_fold) = $self->_add_tile($x, $y, $view_tile);
            push @new_tiles, $new_tile;
            push @tiles_to_fold, @to_fold;
        }
        if ($self->treasures->{$key} && !$view_tile->{treasure}) {
            ### XXX don't go in here if I have taken the treasure
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

    $self->_fold(@tiles_to_fold);
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
