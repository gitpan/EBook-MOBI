
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "create an ebook in the MOBI format, out of POD formatted content.",
  "AUTHOR" => "Boris D\303\244ppen <boris_daeppen\@bluewin.ch>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "EBook-MOBI",
  "EXE_FILES" => [],
  "LICENSE" => "artistic_2",
  "NAME" => "EBook::MOBI",
  "PREREQ_PM" => {
    "Carp" => "1.11",
    "Data::Random" => "0.05",
    "File::Basename" => "2.77",
    "File::Copy" => "2.14",
    "File::Find" => "1.14",
    "File::Spec" => "3.30",
    "File::Temp" => "0.22",
    "FindBin" => "1.5",
    "GD" => "2.39",
    "HTML::Entities" => "3.64",
    "HTML::TreeBuilder" => "3.23",
    "IO::String" => "1.08",
    "Image::BMP" => "1.01",
    "Image::Resize" => "0.5",
    "Image::Size" => "3.221",
    "Pod::Coverage" => "0.21",
    "Pod::Parser" => "1.37",
    "Test::More" => "0.98",
    "Test::Pod" => "1.00",
    "Test::Pod::Coverage" => "1.08",
    "Text::Trim" => "1.02"
  },
  "VERSION" => "0.48",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



