#!/usr/bin/perl 

use strict;

# more gwt bullshit
my $gwtpom = "gwt/pom.xml";
my $asfile = "gwt/ui/src/main/java/com/boomi/gwt/AtomSphere.gwt.xml";
my $wsfile = "gwt/ui/src/main/java/com/boomi/gwt/WidgetSphere.gwt.xml";
my $mdmfile = "gwt/ui/src/main/java/com/boomi/gwt/MdmSphere.gwt.xml";

my $op = @ARGV[0];
if($op eq "")
{
    print "Usage: prepare-scm.pl [ci|co] [--fix]\n";
    exit 1;
}

my $chkin = "ci";
my $chkout = "co";

my $fixbuild = @ARGV[1];
chomp($fixbuild);
if( ($op eq $chkin) || ($fixbuild eq "--fix") ) {
    fix_gwt_build($gwtpom);
}

fix_gwt_useragent($asfile);
fix_gwt_useragent($wsfile);
fix_gwt_useragent($mdmfile);

sub fix_gwt_useragent
{
    my $file = @_[0];
    my $lines = get_file_contents($file);

    if($op eq $chkin)
    {
        $lines =~ s/<set-property (\s?)name=\"user\.agent\" value=\"gecko1_8\"(\s?)\/>/<!--$1set-property name=\"user\.agent\" value=\"gecko1_8\"$2\/-->/;
    } else {
        $lines =~ s/<!--(\s)?set-property name=\"user\.agent\" value=\"gecko1_8\"(\s?)\/-->/<set-property$1 name=\"user\.agent\" value=\"gecko1_8\"$2\/>/;
    }
    rewrite_file($file, $lines);
}

# unfuck ui build
sub fix_gwt_build
{
    my $file = @_[0];
    my $lines = get_file_contents($file);

    if($op eq $chkout)
    {
        $lines =~ s/<module>ui<\/module>/<!--module>ui<\/module-->/; 
    }

    if($op eq $chkin)
    {
        $lines =~ s/<!--module>ui<\/module-->/<module>ui<\/module>/; 
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

