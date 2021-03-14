package Type::Tiny::TypedDuck;
use 5.010001;
use strict;
use warnings;
use utf8;
use parent 'Type::Tiny';

use Sub::Meta;
use List::Util qw( all );
use Scalar::Util qw( blessed );
use Sub::WrapInType qw( install_sub );
use Types::Standard -types;
use Types::TypedCodeRef -types;
use Types::TypedCodeRef::Factory;
use namespace::autoclean;

sub _croak ($;@) {
  require Error::TypeTiny;
  goto \&Error::TypeTiny::croak;
}

my $TypeConstraint = HasMethods[qw( check get_message )];
my $ParamsTypes    = $TypeConstraint | ArrayRef[$TypeConstraint] | HashRef[$TypeConstraint];
my $ReturnTypes    = $TypeConstraint | ArrayRef[$TypeConstraint];
my $TypedMethods   = Tuple[$ParamsTypes, $ReturnTypes] | Dict[ params => $ParamsTypes, isa => $ReturnTypes ];
my $Callable       = Type::Tiny->new(
  name       => 'Callable',
  constraint => \&Types::TypedCodeRef::Factory::_is_callable,
);
my $SubMetaFinders = ArrayRef[ TypedCodeRef[ $Callable => Maybe[ InstanceOf['Sub::Meta'] ] ] ];

sub new {
  my $class = shift;

  my $opts = @_ == 1 ? $_[0] : +{ @_ };
  _croak 'Need to pass pair of method name and method type' unless exists $opts->{method_types};
  if ( my $error = HashRef([$TypedMethods])->validate($opts->{method_types}) ) {
    _croak($error);
  }

  $opts->{sub_meta_finders} = $class->build_sub_meta_finders($opts->{sub_meta_finders});

  my $method_types = delete $opts->{method_types};
  my %method_metas = map {
    my $method_type = $method_types->{$_};
    my $meta = do {
      if (ref $method_type eq 'ARRAY') {
        Sub::Meta->new(
          args      => $method_type->[0],
          returns   => $method_type->[1],
          is_method => 1,
        );
      }
      else {
        Sub::Meta->new(
          args      => $method_type->{params},
          returns   => $method_type->{isa},
          is_method => 1,
        );
      }
    };
    ( $_ => $meta );
  } keys %$method_types;
  $opts->{method_metas} = \%method_metas;

  $class->SUPER::new(%$opts);
}

sub method_metas { $_[0]{method_metas} }

sub sub_meta_finders { $_[0]{sub_meta_finders} }

sub build_sub_meta_finders {
  my ($self, $sub_meta_finders) = @_;
  $sub_meta_finders //= $self->_default_sub_meta_finders;

  my $error = $SubMetaFinders->validate($sub_meta_finders);
  return $sub_meta_finders unless defined $error;

  my $coerced = $SubMetaFinders->coerce($sub_meta_finders);
  return $coerced if $SubMetaFinders->check($coerced);

  _croak($error);
}

sub _default_sub_meta_finders { [\&Types::TypedCodeRef::get_sub_meta_from_sub_wrap_in_type] }

sub has_inlined { !!0 }

sub _is_null_constraint { !!0 }

sub find_sub_meta {
  my ($self, $method) = @_;
  for my $finder (@{ $self->sub_meta_finders }) {
    my $meta = $finder->($method);
    return $meta if defined $meta;
  }
  return undef;
}

sub _build_constraint {
  my $self = shift;

  my %method_metas = %{ $self->method_metas };

  sub {
    my $obj = shift;
    return !!0 unless blessed($obj);

    all {
      my $method_name = $_;
      my $method = $obj->can($method_name);

      if (defined $method) {
        my $meta = $self->find_sub_meta($method);
        defined $meta ? $meta->is_same_interface($method_metas{$method_name}) : !!0;
      }
      else {
        !!0;
      }
    } keys %method_metas;
  };
}

sub validate_explain {
}

push @Type::Tiny::CMP, sub {
  my ($A, $B) = map { $_->find_constraining_type } @_;
  return Type::Tiny::CMP_UNKNOWN unless $A->isa(__PACKAGE__) && $B->isa(__PACKAGE__);

};

1;

__END__

=encoding utf-8

=head1 NAME

Type::Tiny::TypedDuck - It's new $module

=head1 SYNOPSIS

    use Type::Tiny::TypedDuck;

    my $type = Type::Tiny::TypedDuck->new(method_types => +{
      add          => [ [Int, Int] => Int ],
      do_something => +{
        params => [Int, Int],
        isa    => Int,
      },
    });

=head1 DESCRIPTION

Type::Tiny::TypedDuck is ...

=head1 LICENSE

Copyright (C) ybrliiu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

mpoliiu E<lt>raian@reeshome.orgE<gt>

=cut

