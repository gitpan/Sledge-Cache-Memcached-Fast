use strict;
use warnings;
use Test::More;
plan skip_all => 'please set $ENV{LIVE_TEST}' unless $ENV{LIVE_TEST};
plan tests => 9;
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
        $cache->param('foo' => 'boe');

        $cache->set(cnt => 0);
        is $cache->incr('cnt'), 1;
        is $cache->incr('cnt'), 2;
        is $cache->incr('cnt'), 3;
        is $cache->incr('cnt', 2), 5;
        is $cache->decr('cnt'), 4;

        is_deeply $cache->get_multi(qw/foo cnt/), {foo => 'boe', cnt => 4};

        $cache->set_multi([eee => 'ccc'], ['boo' => 'bae']);
        is_deeply $cache->get_multi(qw/eee boo/), {eee => 'ccc', boo => 'bae'};
    }
}

my $page = Proj::Pages::Foo->new;
$page->dispatch('index');

