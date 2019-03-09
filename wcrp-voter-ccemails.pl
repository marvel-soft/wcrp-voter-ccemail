#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# wcrp-emails from constant contact
#
#
#
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#use strict;
use warnings;
$| = 1;
use File::Basename;
use DBI;
use Data::Dumper;
use Getopt::Long qw(GetOptions);
use Time::Piece;
use Math::Round;

no warnings "uninitialized";


=head1 Function
=over
=head2 Overview
	This program will prepare a cc email exports file
		a) file is not sorted
		b)
	Input: export from constant contact
	       
	Output: a csv file containing the extracted fields 
=cut

my $records;
my $inputFile = "contact_export-mar08.csv";    


my $fileName         = "";
my $emailFile         = "base.csv";
my $emailFileh;
my %baseLine         = ();
my $printFile        = "print-.txt";
my $printFileh;
my $votingFile       = "voting.csv";
my $votingFileh;
my %votingLine       = ();
my $csvHeadings        = "";
my @csvHeadings;
my $line1Read       = '';
my $linesRead       = 0;
my $linesIncRead    = 0;
my $printData;
my $linesWritten    = 0;

my $selParty;
my $skipRecords     = 0;
my $skippedRecords  = 0;

my $generalCount;
my $party;

my @csvRowHash;
my %csvRowHash = ();
my @partyHash;
my %partyHash  = ();
my %schRowHash = ();
my @schRowHash;
my @values1;
my @values2;
my @date;
my $voterRank;

my @baseLine;
my $baseLine;
my @baseProfile;
my $baseHeading = "";
my @baseHeading = (
  "Last",           "First",          
	"Middle",  
	"Phone",         	"email",
	"Address",     
	"City",           "State",
	"Zip", 		    		"Contact Points",
);

#
# main program controller
#
sub main {
	#Open file for messages and errors
	open( $printFileh, ">$printFile" )
	  or die "Unable to open PRINT: $printFile Reason: $!";

	# Parse any parameters
	GetOptions(
		'infile=s'  => \$inputFile,
		'outile=s'  => \$emailFile,
		'skip=i'    => \$skipRecords,
		'help!'     => \$helpReq,
	) or die "Incorrect usage!\n";
	if ($helpReq) {
		print "Come on, it's really not that hard.\n";
	}
	else {
		printLine ("My inputfile is: $inputFile.\n");
	}
	unless ( open( INPUT, $inputFile ) ) {
		printLine ("Unable to open INPUT: $inputFile Reason: $!\n");
		die;
	}

	# pick out the heading line and hold it and remove end character
	$csvHeadings = <INPUT>;
	chomp $csvHeadings;

	# @csvHeadings will be used to create the files
	@csvHeadings = split( /\s*,\s*/, $csvHeadings );

	# Build heading for new email record
	$baseHeading = join( ",", @baseHeading );
	$baseHeading = $baseHeading . "\n";

	#
	# Initialize process loop and open files
	printLine ("email table file: $emailFile\n");
	open( $emailFileh, ">$emailFile" )
	  or die "Unable to open emailFile: $emailFile Reason: $!";
	print $emailFileh $baseHeading;

	# initialize the voter stats array
	#voterStatsLoad(@voterStatsArray);

	# Process loop
	# Read the entire input and
	# 1) edit the input lines
	# 2) transform the data
	# 3) write out transformed line
  NEW:
	while ( $line1Read = <INPUT> ) {
		$linesRead++;
		$linesIncRead++;
		if ($linesIncRead == 1000) {
			printLine ("$linesRead lines processed\n");
			$linesIncRead = 0;
		}
		#
		# Get the data into an array that matches the headers array
		chomp $line1Read;

		# replace commas from in between double quotes with a space
		$line1Read =~ s/(?:\G(?!\A)|[^"]*")[^",]*\K(?:,|"(*SKIP)(*FAIL))/ /g;

		# then create the values array
		@values1 = split( /\s*,\s*/, $line1Read, -1 );

		# Create hash of line for transformation
		@csvRowHash{@csvHeadings} = @values1;

		#- - - - - - - - - - - - - - - - - - - - - - - - - - 
		# Assemble database load  for base segment
		#- - - - - - - - - - - - - - - - - - - - - - - - - - 
		%baseLine = ();
    my $UCword                = $csvRowHash{"first"};
		$UCword  =~ s/(\w+)/\u\L$1/g;
	  $baseLine{"First"}        = $UCword; 
    $UCword                = $csvRowHash{"middle"};
		$UCword  =~ s/(\w+)/\u\L$1/g;
		$baseLine{"Middle"}       = $UCword;;
    $UCword                = $csvRowHash{"last"};
		$UCword  =~ s/(\w+)/\u\L$1/g;
		$baseLine{"Last"}         = $UCword;
		$UCword  =~ s/(\w+)/\u\L$1/g;
		$baseLine{"Phone"}        = $csvRowHash{"phone"};
		$UCword                   = $csvRowHash{"address"};
		$UCword  =~ s/(\w+)/\u\L$1/g;
		$baseLine{"Address 1"}    = $UCword;
		$UCword                   = $csvRowHash{"city"};
		$UCword  =~ s/(\w+)/\u\L$1/g;
		$baseLine{"City"}         = $csvRowHash{"city"};
		$baseLine{"State"}        = $csvRowHash{"state"};
		$baseLine{"Zip"}          = $csvRowHash{"zip"};

		
		@baseProfile = ();
		foreach (@baseHeading) {
			push( @baseProfile, $baseLine{$_} );
		}
		print $emailFileh join( ',', @baseProfile ), "\n";
#
#	here are the political segments.
#
	
		$linesWritten++;
		#
		# For now this is the in-elegant way I detect completion
		if ( eof(INPUT) ) {
			goto EXIT;
		}
		next;
	}
	#
	goto NEW;
}
#
# call main program controller
main();
#
# Common Exit
EXIT:

printLine ("<===> Completed transformation of: $inputFile \n");
printLine ("<===> BASE      SEGMENTS available in file: $emailFile \n");
printLine ("<===> VOTING    SEGMENTS available in file: $votingFile \n");
printLine ("<===> Total Records Read: $linesRead \n");
printLine ("<===> Total Records written: $linesWritten \n");

close(INPUT);
close($emailFileh);
close($printFileh);
exit;


#
# Print report line
#
sub printLine  {
	my $datestring = localtime();
	($printData) = @_;
	print $printFileh $datestring . ' ' . $printData;
	print $datestring . ' ' . $printData;
}

# $index = binary_search( \@array, $word )
#   @array is a list of lowercase strings in alphabetical order.
#   $word is the target word that might be in the list.
#   binary_search() returns the array index such that $array[$index]
#   is $word.	
sub binary_search {
	  my ($try, $var);
    my ($array, $word) = @_;
    my ($low, $high) = ( 0, @$array - 1 );
    while ( $low <= $high ) {              # While the window is open
        $try = int( ($low+$high)/2 );      # Try the middle element
				$var = $array->[$try][0];
        $low  = $try+1, next if $array->[$try][0] < $word; # Raise bottom
        $high = $try-1, next if $array->[$try][0] > $word; # Lower top
        return $try;     # We've found the word!
    }
		$try = -1;
    return;              # The word isn't there.
}


#
# create the voterstat binary search array
#
sub voterStatsLoad() {
	$voterStatHeadings = "";
	open( $voterStatFileh, $voterStatFile )
	  or die "Unable to open INPUT: $voterStatFile Reason: $!";
	$voterStatHeadings = <$voterStatFileh>;
	chomp $voterStatHeadings;
	chop $voterStatHeadings;

	# headings in an array to modify
	@voterStatHeadings = split( /\s*,\s*/, $voterStatHeadings );

	# Build the UID->survey hash
	while ( $line1Read = <$voterStatFileh> ) {
		chomp $line1Read;
		my @values1 = split( /\s*,\s*/, $line1Read, -1 );
		push @voterStatsArray , \@values1;
	}
	close $voterStatFileh;
	return @voterStatsArray;
}