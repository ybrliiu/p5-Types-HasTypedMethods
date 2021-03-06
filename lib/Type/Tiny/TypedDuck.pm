package Type::Tiny::TypedDuck;
use 5.010001;
use strict;
use warnings;
use utf8;
use parent 'Type::Tiny';

use Sub::Meta;
use Sub::Meta::Creator;
use Sub::Meta::Finder::SubWrapInType;
use List::Util qw( all );
use Scalar::Util qw( blessed );
use Type::Utils ();
use Types::Standard -types;
use namespace::autoclean;

sub _croak ($;@) {
  require Error::TypeTiny;
  goto \&Error::TypeTiny::croak;
}

my $TypeConstraint = HasMethods[qw( check get_message )];
my $ParamsTypes    = $TypeConstraint | ArrayRef[$TypeConstraint] | HashRef[$TypeConstraint];
my $ReturnTypes    = $TypeConstraint | ArrayRef[$TypeConstraint];
my $TypedMethods   = Tuple[$ParamsTypes, $ReturnTypes] | Dict[ params => $ParamsTypes, isa => $ReturnTypes ];

my $meta_creator = Sub::Meta::Creator->new(
  finders => [ \&Sub::Meta::Finder::SubWrapInType::find_materials ]
);

sub new {
  my $class = shift;

  my $opts = @_ == 1 ? $_[0] : +{ @_ };
  _croak 'Need to pass pair of method name and method type' unless exists $opts->{method_types};
  if ( my $error = HashRef([$TypedMethods])->validate($opts->{method_types}) ) {
    _croak($error);
  }

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

sub has_inlined { !!0 }

sub _is_null_constraint { !!0 }

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
        my $meta = $meta_creator->create($method);
        if (defined $meta) {
          # Not needed for comparison
          $meta->set_subinfo([]);
          $meta->is_same_interface($method_metas{$method_name});
        }
        else {
          !!0;
        }
      }
      else {
        !!0;
      }
    } keys %method_metas;
  };
}

sub validate_explain {
  my ($self, $value) = @_;

  return undef if $self->check($value);
  return ['Not a blessed reference'] unless blessed($value);

  my $missing_methods_error = sprintf(
    '"%s" requires that the reference can %s',
    $self,
    Type::Utils::english_list(map qq{"$_"}, @{ $self->methods }),
  );
  my @missing_methods_errors =
    map { qq{The reference cannot "$_"} }
    grep { !$value->can($_) }
    keys @{ $self->method_metas };

  my @wrong_method_metas =
    map { $_->[0] }
    grep { $_->[0]->is_same_interface($_->[1]) }
    grep defined $_->[1], map { [ $_->[0], $meta_creator->create($_->[1]) ] }
    grep defined $_->[1], map { [ $self->method_metas->{$_}, $value->can($_) ] }
    keys @{ $self->method_metas };

  #TODO: TypedMethods[] ?????? ??????????????????????????????????????????????????????
}

push @Type::Tiny::CMP, sub {
  my ($A, $B) = map { $_->find_constraining_type } @_;
  return Type::Tiny::CMP_UNKNOWN unless $A->isa(__PACKAGE__) && $B->isa(__PACKAGE__);

  my $intersection = grep {
    exists $B->method_metas->{$_}
      ? $A->method_metas->{$_}->is_same_interface($B->method_metas->{$_} )
      : !!0;
  } keys %{ $A->method_metas };

  my ($a_size, $b_size) = (scalar keys %{ $A->method_metas }, scalar keys %{ $B->method_metas });
  return Type::Tiny::CMP_EQUIVALENT if $a_size == $b_size && $b_size == $intersection;
  return Type::Tiny::CMP_SUPERTYPE  if $a_size == $intersection;
  return Type::Tiny::CMP_SUBTYPE    if $b_size == $intersection;

  Type::Tiny::CMP_UNKNOWN;
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

