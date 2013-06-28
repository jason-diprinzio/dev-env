#!/usr/bin/perl
#
# TODO use svn lib to call this directly
# vs parsing haphazard output.
#
# TODO TODO use git
#

use strict;
use Getopt::Long;

my $keyword = "";
my $user = "";
my $help = 0;
my $sep = -1;

GetOptions( 'user=s' => \$user, 'tag=s' => \$keyword, 'help' => \$help );

if($help) {
    print(STDERR "$0 [options]\n");
    print(STDERR "  --user <user>   filter by username\n");
    print(STDERR "  --tag <keyword> filter by keyword (e.g. keyword tag)");
    print(STDERR "\n");
    exit 1;
}

# Get the separator from svn's output
# just in case they ever change it.
my $svnformat = `svn log --limit 1`;
if( $svnformat =~ /(-{5,})/ ) {
    $sep=$1
}

if($sep == -1) {
    die "Cannot read svn output"
}

my $old = $/;
$/ = $sep;

while(<STDIN>) {
    my $line = $_;
    chomp($line);
    if( $line =~ m/^\nr[0-9]{1,7}.*$user.*\n\n$keyword/im ) {
        $line =~ s/^\n//;
        $line =~ s/\n+/|/g;
        print( $line."\n" );
    }
}

$/=$old;

