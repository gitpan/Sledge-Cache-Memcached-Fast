use inc::Module::Install;
name 'Sledge-Cache-Memcached-Fast';
all_from 'lib/Sledge/Cache/Memcached/Fast.pm';

requires 'Sledge::Cache' => 0.04;
requires 'Cache::Memcached::Fast' => 0.10;

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More';
test_requires 'YAML';
author_tests 'xt';
use_test_base;
auto_include;
WriteAll;
