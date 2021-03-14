[![Actions Status](https://github.com/ybrliiu/p5-Types-HasTypedMethods/workflows/test/badge.svg)](https://github.com/ybrliiu/p5-Types-HasTypedMethods/actions) [![Coverage Status](https://img.shields.io/coveralls/ybrliiu/p5-Types-HasTypedMethods/master.svg?style=flat)](https://coveralls.io/r/ybrliiu/p5-Types-HasTypedMethods?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/Types-HasTypedMethods.svg)](https://metacpan.org/release/Types-HasTypedMethods)
# NAME

Types::HasTypedMethods - It's new $module

# SYNOPSIS

    use Types::HasTypedMethods -types;
    
    my $type = HasTypedMethods[
      add          => [ [Int, Int] => Int ],
      do_something => +{
        params => [Int, Int],
        isa    => Int,
      },
    ];

    package HasMethodsClass {
      use Types::Standard -types;
      use Sub::WrapInType qw( install_method );
      sub new { bless +{}, shift }
      install_method add => [Int, Int] => Int, sub { $_[0] + $_[1] };
      install_method do_something => [Int, Int] => Int, sub { $_[0] - $_[1] };
    }

    $type->check(HasMethodsClass->new);

# DESCRIPTION

Types::HasTypedMethods is ...

# LICENSE

Copyright (C) ybrliiu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

mpoliiu <raian@reeshome.org>
