#!/usr/bin/perl 

use strict;

my $bypass = "<!--mark--><set-property name=\"user.agent\" value=\"gecko1_8\"/><!--eom-->";

# more gwt bullshit
my $asfile = "gwt/ui/src/main/java/com/boomi/gwt/AtomSphere.gwt.xml";
my $wsfile = "gwt/ui/src/main/java/com/boomi/gwt/WidgetSphere.gwt.xml";
my $mdmfile = "gwt/ui/src/main/java/com/boomi/gwt/MdmSphere.gwt.xml";

my $op = @ARGV[0];
if($op eq "")
{
    print "Usage: prepare-scm.pl [ci|co] \n";
    exit 1;
}

my $chkin = "ci";
my $chkout = "co";

fix_gwt_useragent($asfile);
fix_gwt_useragent($wsfile);
fix_gwt_useragent($mdmfile);

sub fix_gwt_useragent
{
    my $file = @_[0];
    my $lines = get_file_contents($file);

    if($op eq $chkin)
    {
        $lines =~ s/\n^$bypass$//m;
    } else {
        # a little dirty, but avoid overdoing it.
        if( $lines !~ /$bypass/m ) {
            $lines =~ s/([\s]*<!--[\s]*<set-property.*name=\"user\.agent.*)/$1\n$bypass/;
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

