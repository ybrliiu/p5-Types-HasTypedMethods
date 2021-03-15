package Types::HasTypedMethods;
use 5.010001;
use strict;
use warnings;
use utf8;

our $VERSION = '0.01';

use Type::Library -base;
use Types::Standard qw( Object );
use Type::Tiny::TypedDuck;

sub _method_type_to_name {
  my $method_type = shift;
  my ($params_types, $returns_types) =
    ref $method_type eq 'ARRAY' ? @$method_type : @$method_type{qw( params isa )};

  my $params_types_name =
      ref $params_types eq 'HASH' ? '{' . join( ',', map { "$_ => $params_types->{$_}" } sort keys %$params_types ) . '}'
    : ref $params_types eq 'ARRAY' ? '[' . join( ',', @$params_types ) . ']'
    : $params_types;
  my $returns_types_name = ref $returns_types eq 'ARRAY'
    ? '[' . join( ',', @$returns_types ) . ']'
    : $returns_types;

  ref $method_type eq 'ARRAY'
    ? "[$params_types_name => $returns_types]"
    : "{params => $params_types_name, isa => $returns_types_name}";
}

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
        my $method_type = $method_types{$_};
        my @method_type_names =
          map { $_ . ' => ' . _method_type_to_name($method_types{$_}) } sort keys %method_types;
        'HasTypedMethods[' . join(',', @method_type_names) . ']';
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

