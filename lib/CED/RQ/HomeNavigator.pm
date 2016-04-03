package CED::RQ::HomeNavigator;

use Moose;
use Hash::PriorityQueue;

use CED::RQ::PathItem;

use namespace::autoclean;

extends 'CED::RQ::Navigator';

has '_current_path', is => 'rw', isa => 'ArrayRef[Str]', default => sub {[]};

sub _find_path {
    my ($self) = @_;

    my $q = Hash::PriorityQueue->new();

    my %seen;

    my $home = $self->map->home;

    printf ("Current: %s, Home: %s\n", $self->map->current->key, $home->key);
    $q->insert(
        CED::RQ::PathItem->new(tile => $self->map->current, path_len => 0), 0
        );
    while (1) {
        my $item = $q->pop();
        printf ("%s\n", $item->tile->key);
        return $item->path if ($item->tile->key eq $home->key);

        $seen{$item->tile->key} = 1;
        foreach (qw/up down left right/) {
            my $edge = $item->tile->$_;
            next unless $edge;
            next if ($edge->target->deadly);
            next if ($seen{$edge->target->key});
            my $new_item = CED::RQ::PathItem->new(
                path_len => $item->path_len + $edge->steps,
                tile => $edge->target,
                path => [@{$item->path}, $_]
                );
            $q->insert($new_item, $new_item->path_len);
        }
    }

}

sub calc_move {
    my ($self) = @_;

    ### XXX recalc path if map has changed

    $self->_find_path() unless (@{$self->_current_path});

    return shift @{$self->_current_path};
}

__PACKAGE__->meta->make_immutable();

1
