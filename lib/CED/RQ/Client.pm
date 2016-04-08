package CED::RQ::Client;

use HTTP::Request;
use JSON;
use LWP::UserAgent;
use Carp;
use Moose;
use Log::Any qw($log);

use CED::RQ::Map;
use CED::RQ::DummyNavigator;
use CED::RQ::SearchNavigator;
use CED::RQ::TargetNavigator;

use namespace::autoclean;

has 'name', is => 'ro', isa => 'Str', required => 1;
has 'baseurl', is => 'ro', isa => 'Str', required => 1;
has 'mode', is => 'ro', isa => 'Str', default => 'auto';

has 'map', is => 'ro', isa => 'CED::RQ::Map', lazy => 1,
    builder => '_build_map';

has 'has_treasure', is => 'rw', isa => 'Bool', default => 0;

has '_moves', is => 'rw', isa => 'Int', default => 0;

has '_ua', is => 'ro', isa => 'LWP::UserAgent', lazy => 1,
    builder => '_build__ua';

has '_navigators', is => 'ro', isa => 'HashRef[CED::RQ::TargetNavigator]',
    default => sub { {} };

sub _build_map {
    my ($self) = @_;
    return CED::RQ::Map->new(name => $self->name);
}

sub _build__ua {
    return LWP::UserAgent->new()
}

sub _post {
    my ($self, $endpoint, %data) = @_;
    my $url = join('/', $self->baseurl, "$endpoint/");
    my $res = $self->_ua->post(
        $url,
        Content_Type => 'application/x-www-form-urlencoded',
        Content => [%data]
        );
    unless ($res->is_success) {
        die sprintf("Got status %d from server: %s",
                    $res->code, $res->content || '???'
            );
    }
    return decode_json($res->content);
}

sub _register {
    my ($self) = @_;

    return $self->_post('register', name => $self->name);
}

sub _move {
    my ($self, $direction) = @_;

    $self->_moves($self->_moves + 1);
    return $self->_post('move', player => $self->name, direction => $direction);
}

sub _search_navigator {
    my ($self) = @_;

    unless ($self->_navigators->{search}) {
        $self->_navigators->{search} =
            CED::RQ::SearchNavigator->new(map => $self->map);
    }
    return $self->_navigators->{search};
}

sub _target_navigator {
    my ($self, $target) = @_;

    my $key = join(':', 'target', $target->key);

    unless ($self->_navigators->{$key}) {
        $log->infof('%s: heading for %s', $self->name, $target->key);
        $self->_navigators->{$key} = CED::RQ::TargetNavigator->new(
            map => $self->map, target => $target
            );
    }
    return $self->_navigators->{$key};
}

sub _dummy_navigator {
    my ($self) = @_;

    unless ($self->_navigators->{dummy}) {
        $self->_navigators->{dummy} =
            CED::RQ::DummyNavigator->new(map => $self->map);
    }
    return $self->_navigators->{dummy};
}

sub _select_navigator {
    my ($self) = @_;

    if ($self->mode eq 'auto') {
        if ($self->has_treasure) {
            return $self->_target_navigator($self->map->home);
        }

        my $min_treasure_dist = 100000;
        my $target_treasure;
        foreach (values %{$self->map->treasures}) {
            my $dist = $self->_target_navigator($_)->distance_to_target;
            if (defined $dist && $dist < $min_treasure_dist) {
                $target_treasure = $_;
            }
        }

        if ($target_treasure) {
            return $self->_target_navigator($target_treasure);
        }

        return $self->_search_navigator();
    } elsif ($self->mode eq 'dummy') {
        return $self->_dummy_navigator();
    } else {
        croak sprintf('%s: mode %s unsupported', $self->name, $self->mode);
    }
    return;
}


sub is_over {
    my ($self, $reply) = @_;

    my $final_state;
    if (($reply->{game} || '') eq 'over') {
        $final_state = $reply->{result};
    } elsif ($reply->{error}) {
        $final_state = sprintf('aborted (%s)', $reply->{error});
    } elsif (!$reply->{view}) {
        $final_state = 'undefined (no view returned)';
    }
    if ($final_state) {
        $log->infof(
            '%s: game %s - %d moves taken',
            $self->name, $final_state, $self->_moves
            );
        return 1;
    }
    return 0;
}

sub play {
    my ($self) = @_;

    my $data = $self->_register();
    return if $self->is_over($data);
    $self->map->init($data->{view});

    while (1) {
        my $data;
        my $navi = $self->_select_navigator;
        my $direction = $navi->calc_move();
        my $steps = $self->map->current->$direction->steps;
        foreach (1..$steps) {
            $data = $self->_move($direction);
            return if $self->is_over($data);
        }
        $self->has_treasure($data->{treasure} ? 1 : 0);
        $self->map->$direction($data->{view});
        $navi->consume($direction);
    }
    return;
}

__PACKAGE__->meta->make_immutable();

1;
