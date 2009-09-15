#!/usr/bin/perl
use strict;
use warnings;

my $total_tests = 0;
my $passed = 0;

sub compile {
  my $source = shift;
  print "Compiling $source...\n";
  print "g++ -O2 -o $source.out $source\n";
  system "g++ -O2 -o $source.out $source";
  
  return 0;
}

sub parse_config {
  open my $fh, shift or die "Cannot open $_: $!";
  my $params = <$fh>;
  my $result = <$fh>;
  chomp $result;
  chomp $params;
  close($fh);
  
  return ($params, $result);
}

while (my $dir = <test/*>) {
  next unless -d $dir && -r $dir;
  # Find a cpp file inside
  my @source = glob("$dir/*.cpp");
  my $config = "$dir/params";
  my $input = "$dir/input";
  my $output = "$dir/output";
  
  next unless @source && -f $config && -f $input && -f $output;
  my $source = pop @source;
  
  $total_tests++;
  print "Testing $dir\n";
  compile($source);
  my ($params, $result) = parse_config($config);
  
  # Run the code
  my $run_cmd = "./runner.pl $params ./$source.out < $input > $dir/result";
  print $run_cmd."\n";
  my $stat = system $run_cmd;
  
  if ($stat == 0) {
    $stat = system "diff $output $dir/result";
    if ($stat != 0) {
      $stat = "wa"
    }
    else {
      $stat = "ok"
    }
  } else {
    $stat = "re";
  }
  
  if ($stat eq $result) {
    print "PASSED!\n";
    $passed++;
  } else {
    print "FAILED! Expected $result, got $stat\n"
  }
  print $!;
}

print "Total tests: $total_tests\nPassed: $passed\n";