#!/usr/bin/env perl
use common::sense;
use Enigma;
use JSON;
use Encode;
use URI;
use LWP::Simple qw();
use Devel::KYTProf;
use Furl;

my $UA = Furl->new;
my %DEFAULT_QUERIES = (
    country => 'JP',
    lang    => 'ja_JP',
);

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

    return $c->render_json([
        map {
            +{
                name    => $_->{artistName},
                id      => $_->{artistId},
                linkUrl => $_->{artistLinkUrl},
            };
        }
        _fetch_json($uri->as_string)
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
        _fetch_json($uri->as_string)
    ]);
};

sub _fetch_json {
    my $url = shift;
    say $url;
    my $json = LWP::Simple::get($url);
    say $json;
    $json = encode_utf8 $json;
    say $json;

    return @{
        decode_json($json)->{results}
    };
}

__PACKAGE__->to_app;
