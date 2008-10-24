use strict;
use warnings;
use Test::More;
plan skip_all => 'please set $ENV{LIVE_TEST}' unless $ENV{LIVE_TEST};
plan tests => 2;
use Sledge::Cache::Memcached::Fast;

{
    package Proj::Config;
    sub new { bless {}, shift }
    sub cache_option { { servers => ['127.0.0.1:11211'], namespace => 'test' }  }
}

{
    package Proj::Pages::Foo;
    use Test::More;
    sub new { bless {}, shift }
    sub create_cache { Sledge::Cache::Memcached::Fast->new(@_) }
    sub create_config { Proj::Config->new() }
    sub dispatch {
        my ($self, $page) = @_;
        my $cache = $self->create_cache();
        $cache->param('foo' => 'bar');
        is $cache->param('foo'), 'bar';
        $cache->remove('foo');
        is $cache->param('foo'), undef;
    }
}

my $page = Proj::Pages::Foo->new;
$page->dispatch('index');

