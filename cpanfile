requires "Class::Tiny" => "0";
requires "HTTP::Tiny" => "0.036";
requires "perl" => "v5.10.0";
requires "strict" => "0";
requires "superclass" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Data::Dumper" => "0";
  requires "Exporter" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Basename" => "0";
  requires "File::Spec" => "0";
  requires "File::Spec::Functions" => "0";
  requires "File::Temp" => "0";
  requires "IO::Dir" => "0";
  requires "IO::File" => "0";
  requires "IO::Handle" => "0";
  requires "IO::Socket::INET" => "0";
  requires "IPC::Open3" => "0";
  requires "List::Util" => "0";
  requires "Test::More" => "0.88";
  requires "lib" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.17";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Meta" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
};
