use Test2::V0;
use Types::Standard -types;
use Type::Tiny::TypedDuck;

my @types = (
  Type::Tiny::TypedDuck->new(
    method_types => +{
      add => [ [Int, Int] => Int ],
      sub => [ [Int, Int] => Int ],
    },
  ),
  Type::Tiny::TypedDuck->new(
    method_types => +{
      add => [ [Int, Int] => Int ],
    },
  ),
  Type::Tiny::TypedDuck->new(
    method_types => +{
      sub => [ [Int, Int] => Int ],
    },
  ),
  Type::Tiny::TypedDuck->new(
    method_types => +{
      sub => [ [Str, Int] => Str ],
    },
  ),
  Type::Tiny::TypedDuck->new(
    method_types => +{
      foo => [ CodeRef ,=> Str ],
      bar => [ Tuple[Int, Int] => Enum[qw( A B C )] ],
    },
  ),
  Type::Tiny::TypedDuck->new(
    method_types => +{},
  ),
);

ok $types[0]->equals($types[0]);
ok $types[0]->is_subtype_of($types[1]);
ok $types[0]->is_subtype_of($types[2]);
ok $types[1]->is_supertype_of($types[0]);
ok $types[2]->is_supertype_of($types[0]);
ok !$types[2]->equals($types[3]);
ok !$types[0]->equals($types[4]);
ok $types[4]->is_subtype_of($types[5]);
ok $types[5]->is_supertype_of($types[4]);

done_testing;
