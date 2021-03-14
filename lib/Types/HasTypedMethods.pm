package Types::HasTypedMethods;
use 5.010001;
use strict;
use warnings;
use utf8;

our $VERSION = '0.01';

use Type::Library -base;
use Types::Standard qw( Object );
use Type::Tiny::TypedDuck;

my $meta = __PACKAGE__->meta;
$meta->add_type(+{
  name                 => 'HasTypedMethods',
  parent               => Object,
  constraint_generator => sub {
    return $meta->get_type('HasTypedMethods') unless @_;

    my %method_types = @_;
    Type::Tiny::TypedDuck->new(
      method_types => \%method_types,
      display_name => do {
        '{' . join(',', map { "$_ => $method_types{$_}" } keys %method_types) . '}'
      },
    );
  },
});

$meta->make_immutable;

1;

__END__

=encoding utf-8

=head1 NAME

Types::HasTypedMethods - It's new $module

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Types::HasTypedMethods is ...

=head1 LICENSE

Copyright (C) ybrliiu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

mpoliiu E<lt>raian@reeshome.orgE<gt>

=cut

