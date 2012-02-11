
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "create an eBook in the MOBI format - out of POD formatted content.",
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
    "File::Spec" => "3.30",
    "File::Temp" => "0.22",
    "HTML::Entities" => "3.64",
    "IO::String" => "1.08",
    "Image::Resize" => "0.5",
    "Pod::Parser" => "1.37",
    "Text::Trim" => "1.02"
  },
  "VERSION" => "0.1",
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



