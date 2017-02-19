#!/usr/bin/env perl
use common::sense;
use Enigma;
use JSON;
use Encode;
use URI;
use Devel::KYTProf;
use LWP::UserAgent;

my %DEFAULT_QUERIES = (
    country => 'JP',
    lang    => 'ja_JP',
);
my $UA = LWP::UserAgent->new(timeout => 5);

get '/artists' => sub {
    my ($c) = @_;

    my $params = $c->validate(
        term => 'Str',
    ) or return $c->error_res;

    my $uri = URI->new('https://itunes.apple.com/search');
    $uri->query_form(
        %DEFAULT_QUERIES,
        entity => 'musicArtist',
        term   => $params->{term},
    );

    my @results = eval { _fetch($uri->as_string) };
    if ($@) {
        return $c->render_json_with_code(500);
    }
    return $c->render_json([
        map {
            +{
                name    => $_->{artistName},
                id      => $_->{artistId},
                linkUrl => $_->{artistLinkUrl},
            };
        }
        @results,
    ]);
};

get '/artists/{id}/songs' => sub {
    my ($c) = @_;

    my $params = $c->validate(
        id => 'Int',
    ) or return $c->error_res;

    my $uri = URI->new('https://itunes.apple.com/lookup');
    $uri->query_form(
        %DEFAULT_QUERIES,
        entity      => 'song',
        wrapperType => 'track',
        id          => $params->{id},
    );

    my @results = eval { _fetch($uri->as_string) };
    if ($@) {
        return $c->render_json_with_code(500);
    }
    return $c->render_json([
        map { 
            +{
                id      => $_->{trackId},
                name    => $_->{trackName},
                viewUrl => $_->{trackViewUrl},
                previewUrl => $_->{previewUrl},
                artworkUrls => {
                    100 => $_->{artworkUrl100},
                    60  => $_->{artworkUrl60},
                    30  => $_->{artworkUrl30},
                },
            };
        }
        grep { $_->{wrapperType} eq 'track' }
        @results
    ]);
};

sub _fetch {
    my $url = shift;
    my $json = $UA->get($url)->decoded_content;
    $json = encode_utf8 $json;

    return @{
        decode_json($json)->{results}
    };
}

__PACKAGE__->to_app;
