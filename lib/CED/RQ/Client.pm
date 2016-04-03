package CED::RQ::Client;

use HTTP::Request;
use JSON;
use LWP::UserAgent;
use Moose;
use Log::Any qw($log);
use Log::Any::Adapter;
Log::Any::Adapter->set('Stdout');

use CED::RQ::Map;
use CED::RQ::SearchNavigator;
use CED::RQ::HomeNavigator;

use namespace::autoclean;

has 'name', is => 'ro', isa => 'Str', required => 1;
has 'baseurl', is => 'ro', isa => 'Str', required => 1;

has 'map', is => 'ro', isa => 'CED::RQ::Map', lazy => 1,
    builder => '_build_map';

has 'has_treasure', is => 'rw', isa => 'Bool', default => 0;

has '_moves', is => 'rw', isa => 'Int', default => 0;

has '_ua', is => 'ro', isa => 'LWP::UserAgent', lazy => 1,
    builder => '_build__ua';

has '_search_navigator', is => 'ro', isa => 'CED::RQ::SearchNavigator',
    lazy => 1, builder => '_build__search_navigator';

has '_home_navigator', is => 'ro', isa => 'CED::RQ::HomeNavigator',
    lazy => 1, builder => '_build__home_navigator';

sub _build_map {
    my ($self) = @_;
    return CED::RQ::Map->new(name => $self->name);
}

sub _build__ua {
    return LWP::UserAgent->new()
}

sub _build__search_navigator {
    my ($self) = @_;
    return CED::RQ::SearchNavigator->new(map => $self->map);
}

sub _build__home_navigator {
    my ($self) = @_;
    return CED::RQ::HomeNavigator->new(map => $self->map);
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

sub _select_navigator {
    my ($self) = @_;

    if ($self->has_treasure) {
        $log->infof('%s: picked up treasure - heading home', $self->name);
        return $self->_home_navigator;
    }

    return $self->_search_navigator;
}


sub play {
    my ($self) = @_;

    my $data = $self->_register();
    $self->map->init($data->{view});

    my $result;

    while (!$result) {
        my $data;
        my $direction = $self->_select_navigator->calc_move();
        my $steps = $self->map->current->$direction->steps;
        $data = $self->_move($direction) foreach (1..$steps);

        if (($data->{game} || '') eq 'over') {
            $result = $data->{result};
        } else {
            $self->has_treasure($data->{treasure} ? 1 : 0);
            $self->map->$direction($data->{view});
        }
    }

    $log->infof('Game %s - %d moves taken', $result, $self->_moves);
    return;
}

__PACKAGE__->meta->make_immutable();

1;
