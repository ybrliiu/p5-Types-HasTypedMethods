use Test2::V0;
use Types::Standard -types;
use Types::HasTypedMethods -types;

{
  package NoMethodsClass;
  sub new { bless +{}, shift }
}

{
  package HasNotTypedMethodsClass;
  sub new { bless +{}, shift }
  sub add {
    my $class = shift;
    $_[0] + $_[1]
  }
  sub do_something {
    my $class = shift;
    $_[0] - $_[1];
  }
}

{
  package MissingMethodsClass;
  use Types::Standard -types;
  use Sub::WrapInType qw( install_method );
  sub new { bless +{}, shift }
  install_method add => [Int, Int] => Int, sub { $_[0] + $_[1] };
}

{
  package HasMethodsClass;
  use Types::Standard -types;
  use Sub::WrapInType qw( install_method );
  sub new { bless +{}, shift }
  install_method add => [Int, Int] => Int, sub { $_[0] + $_[1] };
  install_method do_something => [Int, Int] => Int, sub { $_[0] - $_[1] };
}

my $type = HasTypedMethods[
  add          => [ [Int, Int] => Int ],
  do_something => +{
    params => [Int, Int],
    isa    => Int,
  },
];
diag $type;

ok !$type->check(NoMethodsClass->new);
ok !$type->check(HasNotTypedMethodsClass->new);
ok !$type->check(MissingMethodsClass->new);
ok $type->check(HasMethodsClass->new);

done_testing;
