package Aspect::Library::TestClass;

use 5.006;
use strict;
use warnings;
use Test::Class       0.33 ();
use Params::Util      1.00 ();
use Aspect::Modular   0.36 ();
use Aspect::Advice::Before ();
use Aspect::Pointcut::Call ();
use Aspect::Pointcut::And  ();

our $VERSION = '0.37';
our @ISA     = 'Aspect::Modular';

sub Test::Class::make_subject {
	shift->subject_class->new(@_);
}

sub get_advice {
	my $self     = shift;
	my $pointcut = shift;
	Aspect::Advice::Before->new(
		lexical => $self->lexical,
		pointcut => Aspect::Pointcut::And->new(
			Aspect::Pointcut::Call->new(qr/::[a-z][^:]*$/),
			$pointcut,
		),
		code => sub {
			my $context = shift;
			my $self    = $context->self; # the Test::Class object
			return unless is_test_method_with_subject($context);
			my (@params) = $self->subject_params if $self->can('subject_params');
			my $subject = $self->make_subject(@params);
			$self->init_subject_state($subject) if $self->can('init_subject_state');
			$context->params( $context->params, $subject );
		},
	);
}

# true if we are in a test class, in a test method, and we can get a
# subject_class from the test class
# would be nice if we could somehow check for existence of test attribute
# on method
sub is_test_method_with_subject {
	my $context = shift;
	my $self    = $context->self; # the Test::Class object
	my @method  = ($context->package_name, $context->short_sub_name);
	return Params::Util::_INSTANCE($self, 'Test::Class')
	    && $self->_method_info(@method)
	    && $self->can('subject_class');
}

1;

__END__

=pod

=head1 NAME

Aspect::Library::TestClass - give Test::Class test methods an IUT
(implementation under test)

=head1 SYNOPSIS

  # append IUT to params of all test methods in matching packages
  # place this in your test script
  aspect TestClass => call qr/::tests::/;

=head1 SUPER

L<Aspect::Modular>

=head1 DESCRIPTION

Frequently my C<Test::Class> test methods look like this:

  sub some_test: Test {
     my $self = shift;
     my $subject = IUT->new;
     # send $subject messages and verify expected results
     ...
  }

After installing this aspect, they look like this:

  sub some_test: Test {
     my ($self, $subject) = @_;
     # send $subject messages and verify expected results
     ...
  }

In the test class you must add one I<template method> to provide the
class of the IUT:

  sub subject_class { 'MyApp::Person' }

=head1 REQUIRES

Only works with C<Test::Class> above version C<0.06_05>.
  
=head1 SEE ALSO

See the L<Aspect|::Aspect> pods for a guide to the Aspect module.

C<XUL-Node> tests use this aspect extensively.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Aspect-Library-TestClass>

For other issues, contact the author.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit <http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see <http://www.perl.com/CPAN/authors/id/M/MA/MARCEL/>.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Marcel GrE<uuml>nauer E<lt>marcel@cpan.orgE<gt>

Ran Eilam E<lt>eilara@cpan.orgE<gt>

=head1 SEE ALSO

You can find AOP examples in the C<examples/> directory of the
distribution.

=head1 COPYRIGHT AND LICENSE

Copyright 2001 by Marcel GrE<uuml>nauer

Some parts copyright 2009 - 2011 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
