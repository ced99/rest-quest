package CED::RQ::SearchNavigator;

use Moose;
use List::Util qw(max);

use namespace::autoclean;

extends 'CED::RQ::Navigator';

sub _calc_score {
    my ( $self, $edge, $vision ) = @_;

    my $tile = $edge->target;

    return ( -10000, $vision ) if $tile->deadly;
    return ( -100,   $vision ) if $tile->visited;

    my $result      = 0;
    my $vision_size = keys %$vision;
    my $new_vision =
        $self->map->possible_vision( $tile->x, $tile->y, $vision );
    my $new_vision_size = keys %$new_vision;
    $result += ( $new_vision_size - $vision_size ) * 100;
    $result -= 50 * ( $edge->steps - 1 );

    return ( $result, $new_vision );
}

sub _calc_move {
    my ( $self, $tile, $vision, $lookahead ) = @_;

    my %scores;
    foreach (qw/up down left right/) {
        my $edge = $tile->$_;
        next unless $edge;
        my ( $score, $new_vision ) = $self->_calc_score( $edge, $vision );
        push( @{ $scores{$score} }, [ $_, $new_vision ] ) if defined $score;
    }
    my $max_score = max keys %scores;
    return ( 0, 'up' ) unless defined $max_score;
    my $dirs_n_visions = $scores{$max_score};
    my $dir_to_go      = $dirs_n_visions->[0]->[0];
    if ( $lookahead && ( @$dirs_n_visions > 1 ) ) {
        my $max_next_score = -1000000;
        foreach (@$dirs_n_visions) {
            my ( $dir, $next_vision ) = @$_;
            my $next_edge = $tile->$dir;
            next unless $next_edge;
            my $next_tile = $next_edge->target;
            my ( $next_score, undef ) =
                $self->_calc_move( $next_tile, $next_vision, $lookahead - 1 );
            if ( $next_score > $max_next_score ) {
                $max_next_score = $next_score;
                $dir_to_go      = $dir;
            }
        }
    }
    return $max_score, $dir_to_go;
}

sub calc_move {
    my ($self) = @_;

    my ( undef, $result ) =
        $self->_calc_move( $self->map->current, $self->map->vision, 3 );
    return $result;
}

__PACKAGE__->meta->make_immutable();

1
