#!/usr/bin/perl 

use strict;

my $bypass = "<!--mark--><set-property name=\"user.agent\" value=\"gecko1_8\"/><!--eom-->";
my @files;

# more gwt bullshit
my $asfile = "gwt/ui/src/main/java/com/boomi/gwt/AtomSphere.gwt.xml";
@files = check_file($asfile, @files);

my $apfile = "gwt/ui/src/main/java/com/boomi/gwt/ApiSphere.gwt.xml";
@files = check_file($apfile, @files);

my $wsfile = "gwt/ui/src/main/java/com/boomi/gwt/WidgetSphere.gwt.xml";
@files = check_file($wsfile, @files);

my $mdmfile = "gwt/ui/src/main/java/com/boomi/gwt/MdmSphere.gwt.xml";
@files = check_file($mdmfile, @files);

my $length = @files;
if(0 == $length) {
    exit 1;
}

my $op = @ARGV[0];
if($op eq "")
{
    print "Usage: prepare-scm.pl [ci|co] \n";
    exit 1;
}

my $chkin = "ci";
my $chkout = "co";

foreach my $file(@files) {
    fix_gwt_useragent($file);
}

exit 0;

sub fix_gwt_useragent
{
    my $file = @_[0];
    my $lines = get_file_contents($file);

    if($op eq $chkin) {
        $lines =~ s/\n^$bypass$//m;
    } else {
        # a little dirty, but avoid overdoing it.
        if( $lines !~ /$bypass/m ) {
            $lines =~ s/(.*set-property.*name=\"user\.agent\".*value=\"gecko1_8\".*)/$1\n$bypass/;
        }
    }
    rewrite_file($file, $lines);
}

# slurp file
sub get_file_contents
{
    my $file = @_[0];
    my $tmpTerm = $/;
    undef $/;

    open(FILE, "<", $file) or die $!;
    my $lines  = <FILE>;
    close(FILE);

    $/ = $tmpTerm;
    return $lines;
}

# write back the mods
sub rewrite_file
{
    my $file = @_[0];
    my $lines = @_[1];

    open(FILE, ">", $file) or die $!;
    print FILE "$lines";
    close(FILE);
}

sub check_file
{
    my ($file, @files) = @_;

    if(-e $file) {
        push(@files, $file);
    } else {
        printf "WARNING:  $file not found\n";
    } 
    return @files;
}

