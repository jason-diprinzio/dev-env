#!/usr/bin/perl -w
#
# Use a google repo manifest to create Git submodules
#
$argc = $#ARGV + 1;
if( $argc < 1 ) {
    print "specify a manifest file\n";
    exit;
}

my $file = $ARGV[0];
print "processing $file\n";

open(my $manifest_file, '<', $file) or die $!;

my %remotes;
my @projects;

# TODO create entry for default repo
while(my $line = <$manifest_file>) {
    chomp $line;
    if( $line =~ /^\s*<remote/) {
        my @fields = split(" ", $line);
        my $name;
        my $fetch;
        for(@fields) {
            if($_ =~ /name="/) {
                my @a = split("\"", $_);
                $name = $a[1];
            } elsif ($_ =~ /fetch="/) {
                my @a = split("\"", $_);
                $fetch = $a[1];
            }
        }

        $remotes{$name} = $fetch;

    } elsif ( $line =~ /^\s*<project/){
        my @fields = split(" ", $line);
        my $project = {};
        for(@fields) {
            if($_ =~ /name="/) {
                my @a = split("\"", $_);
                $project->{name} = $a[1];
            } elsif ($_ =~ /revision="/) {
                my @a = split("\"", $_);
                $project->{revision} = $a[1];
            } elsif ($_ =~ /path="/) {
                my @a = split("\"", $_);
                $project->{path} = $a[1];
            } elsif ($_ =~ /remote="/) {
                my @a = split("\"", $_);
                $project->{remote} = $a[1];
            }
        }
        push(@projects, $project);
    }
}
close($manifest_file);

for(@projects) {
    my $cmd = "git submodule add $remotes{$_->{remote}}/$_->{name} $_->{path}";
    system("$cmd");
    if($_->{revision}) {
        $cmd = "\$(cd $_->{path} && git checkout $_->{revision})";
        system("$cmd");
    }
}

