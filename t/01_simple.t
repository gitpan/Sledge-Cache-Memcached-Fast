use strict;
use warnings;
use Test::More;
plan skip_all => 'please set $ENV{LIVE_TEST}' unless $ENV{LIVE_TEST};
plan tests => 29;
use Sledge::Cache::Memcached::Fast;

{
    package Proj::Config;
    sub new { bless {}, shift }
    sub cache_option { { servers => ['127.0.0.1:11211'], namespace => 'test' . rand() }  }
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

        $cache->add('cnt', 0);
        is $cache->get('cnt'), 4;
        $cache->add('asdf', 0);
        is $cache->get('asdf'), 0;

        $cache->add_multi(['add1', 3], ['add2', 4]);
        is_deeply $cache->get_multi(qw/add1 add2/), {add1 => 3, add2 => 4};

        $cache->incr_multi(qw/cnt asdf/);
        is_deeply $cache->get_multi(qw/cnt asdf/), {cnt => 5, asdf => 1}, 'incr_multi';

        $cache->decr_multi(qw/cnt asdf/);
        is_deeply $cache->get_multi(qw/cnt asdf/), {cnt => 4, asdf => 0};

        $cache->delete('asdf');
        is $cache->get('asdf'), undef;

        $cache->replace('asdf' => 9);
        is $cache->get('asdf'), undef;
        $cache->replace(cnt => 9);
        is $cache->get('cnt'), 9;

        $cache->replace_multi([asdf => 10], [cnt => 10]);
        is_deeply $cache->get_multi(qw/asdf cnt/), {cnt => 10};

        $cache->append('cnt' => 'foo');
        is $cache->get('cnt'), '10foo';

        $cache->prepend('cnt' => 'bar');
        is $cache->get('cnt'), 'bar10foo';

        $cache->set_multi([eee => 'ccc'], ['boo' => 'bae']);
        is_deeply $cache->get_multi(qw/eee boo/), {eee => 'ccc', boo => 'bae'}, 'set_multi';
        $cache->append_multi(['eee' => 'app'], ['boo' => 'app']);
        is_deeply $cache->get_multi(qw/eee boo/), {eee => 'cccapp', boo => 'baeapp'}, 'append_multi';
        $cache->prepend_multi(['eee' => 'pre'], ['boo' => 'pre']);
        is_deeply $cache->get_multi(qw/eee boo/), {eee => 'precccapp', boo => 'prebaeapp'}, 'prepend_multi';

        $cache->set(nkey => 3);
        my $cas = $cache->gets('nkey');
        ok $cas->[0];
        is $cas->[1], 3;
        $cas->[1] = 'new val';
        ok $cache->cas('nkey', @$cas);
        is $cache->get('nkey'), 'new val';
        
        do {
            $cache->set_multi([eee => 'ccc'], ['boo' => 'bae']);
            my $cas = $cache->gets_multi(qw/eee boo/);
            $cache->set('boo', 'YAY');
            $cas->{eee}->[1] = 'new val1';
            $cas->{boo}->[1] = 'new val2';
            $cache->cas_multi([eee => @{$cas->{eee}}], [boo => @{$cas->{boo}}]);
            is_deeply $cache->get_multi(qw/eee boo/), {'eee' => 'new val1', boo => 'YAY'};
        };

        $cache->flush_all();
        is $cache->get('cnt'), undef;
    }
}

my $page = Proj::Pages::Foo->new;
$page->dispatch('index');

