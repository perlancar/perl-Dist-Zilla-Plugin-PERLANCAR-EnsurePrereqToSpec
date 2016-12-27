package Dist::Zilla::Plugin::PERLANCAR::EnsurePrereqToSpec;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
use namespace::autoclean;

with (
    'Dist::Zilla::Role::InstallTool',
    'Dist::Zilla::Role::Rinci::CheckDefinesMeta',
);

sub _prereq_check {
    my ($self, $prereqs_hash, $mod, $wanted_phase, $wanted_rel) = @_;

    #use DD; dd $prereqs_hash;

    my $num_any = 0;
    my $num_wanted = 0;
    for my $phase (keys %$prereqs_hash) {
        for my $rel (keys %{ $prereqs_hash->{$phase} }) {
            if (exists $prereqs_hash->{$phase}{$rel}{$mod}) {
                $num_any++;
                $num_wanted++ if $phase eq $wanted_phase && $rel eq $wanted_rel;
            }
        }
    }
    ($num_any, $num_wanted);
}

sub _prereq_only_in {
    my ($self, $prereqs_hash, $mod, $wanted_phase, $wanted_rel) = @_;

    my ($num_any, $num_wanted) = $self->_prereq_check(
        $prereqs_hash, $mod, $wanted_phase, $wanted_rel,
    );
    $num_wanted == 1 && $num_any == 1;
}

sub _prereq_none {
    my ($self, $prereqs_hash, $mod) = @_;

    my ($num_any, $num_wanted) = $self->_prereq_check(
        $prereqs_hash, $mod, 'whatever', 'whatever',
    );
    $num_any == 0;
}

# actually we use InstallTool phase just so we are run after all the
# PrereqSources plugins
sub setup_installer {
    my $self = shift;

    my $prereqs_hash = $self->zilla->prereqs->as_string_hash;

    # Rinci
    if ($self->check_dist_defines_rinci_meta || -f ".tag-implements-Rinci") {
        $self->log_fatal(["Dist defines Rinci metadata or implements Rinci, but there is no DevelopSuggests prereq to _SPEC::Rinci"])
            unless $self->_prereq_only_in($prereqs_hash, "_SPEC::Rinci", "develop", "suggests");
    } else {
        $self->log_fatal(["Dist does not define Rinci metadata, but there is a prereq to Rinci or _SPEC::Rinci"])
            unless $self->_prereq_none($prereqs_hash, "Rinci") &&
                $self->_prereq_none($prereqs_hash, "_SPEC::Rinci");
    }
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Ensure prereq to spec modules

=for Pod::Coverage .+

=head1 SYNOPSIS

In C<dist.ini>:

 [PERLANCAR::EnsurePrereqToSpec]


=head1 DESCRIPTION

I like to specify prerequisite to spec modules such as L<Rinci>, L<Riap>,
L<Sah>, L<Setup>, etc as DevelopRecommends, to express that a distribution
conforms to such specification(s).

Currently only L<Rinci> is checked.
