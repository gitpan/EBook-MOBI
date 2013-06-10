
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "create an ebook in the MOBI format.",
  "AUTHOR" => "Boris D\303\244ppen <bdaeppen.perl\@gmail.com>",
  "BUILD_REQUIRES" => {
    "File::Slurp" => 0,
    "Test::More" => 0,
    "utf8" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "EBook-MOBI",
  "EXE_FILES" => [],
  "LICENSE" => "artistic_2",
  "NAME" => "EBook::MOBI",
  "PREREQ_PM" => {
    "Carp" => 0,
    "File::Basename" => 0,
    "File::Copy" => 0,
    "File::Spec" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "GD" => 0,
    "HTML::Entities" => 0,
    "HTML::TreeBuilder" => 0,
    "IO::String" => 0,
    "Image::BMP" => 0,
    "Image::Size" => 0,
    "Pod::Parser" => 0,
    "Text::Trim" => 0,
    "constant" => 0,
    "feature" => 0,
    "strict" => 0,
    "vars" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.61",
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



