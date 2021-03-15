requires 'perl', '5.010001';
requires 'Sub::Meta', '0.08';
requires 'List::Util';
requires 'Scalar::Util';
requires 'Type::Tiny', '1.010004';
requires 'Sub::WrapInType', '0.07';
requires 'namespace::autoclean', '0.29';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test2::Suite', '0.000138';
};

