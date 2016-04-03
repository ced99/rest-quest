package CED::RQ::SearchNavigator;

use Moose;

use namespace::autoclean;

extends 'CED::RQ::Navigator';

sub _calc_score {
    my ($self, $direction) = @_;

    my $edge = $self->map->current->$direction();
    my $tile = $edge->target;

    return -10000 if $tile->deadly;

    my $result = 0;
    my $vision_size = $self->map->vision_size;
    my $new_vision_size = $self->map->possible_vision_size($tile->x, $tile->y);
    $result += ($new_vision_size - $vision_size) * 100;

    $result -= 50 if ($tile->visited);
    ### XXX mountain delay
    ### XXX further view gain by surrounding tiles
    ### XXX amount of water

    return $result;
}

sub calc_move {
    my ($self) = @_;

    my %scores;
    foreach (qw/up down left right/) {
        $scores{$_} = $self->_calc_score($_);
    }

    my @cands = sort {$scores{$b} <=> $scores{$a}} keys %scores;
    return $cands[0];
}

__PACKAGE__->meta->make_immutable();

1
