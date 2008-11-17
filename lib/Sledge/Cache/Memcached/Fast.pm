package Sledge::Cache::Memcached::Fast;
use strict;
use warnings;
require Sledge::Cache;
use base 'Sledge::Cache';
use 5.00800;
our $VERSION = '0.04';
use Cache::Memcached::Fast;

our $Expires = 24 * 60 * 60; # 24hour

sub _get_key {
    my ( $self, $key ) = @_;
    $key;    # no mangle. this module uses namespace =)
}

sub _init {
    my ( $self, $page ) = @_;
    my $options = $page->create_config->cache_option;
    $self->{_memd} = Cache::Memcached::Fast->new( $options );
}

sub _get {
    my ( $self, $key ) = @_;
    return $self->{_memd}->get($key);
}

sub _set {
    my ( $self, $key, $val, $exptime ) = @_;
    $exptime ||= $Expires;
    $self->{_memd}->set( $key, $val, $exptime );
}

sub _remove {
    my $self = shift;
    my $key  = shift;
    $self->{_memd}->delete($key);
}

{
    no strict 'refs';
    for my $method (qw/
        set set_multi cas cas_multi add add_multi replace replace_multi append append_multi prepend prepend_multi get get_multi gets gets_multi incr incr_multi decr decr_multi delete flush_all
    /) {
        *{__PACKAGE__ . "::${method}"} = sub {
            my $self = shift;
            $self->{_memd}->$method(@_);
        };
    }
}


1;
__END__

=encoding utf8

=head1 NAME

Sledge::Cache::Memcached::Fast - Cache::Memcached::Fast bindings for Sledge::Cache

=head1 SYNOPSIS

    package Your::Pages;
    use Sledge::Plugin::Cache;
    use Sledge::Cache::Memcached;
    sub create_cache { Sledge::Cache::Memcached->new(shift) }

=head1 DESCRIPTION

Sledge::Cache::Memcached::Fast is memcached subclass for Sledge::Cache.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

L<Sledge::Cache>, L<Cache::Memcached::Fast>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
