package PerlSpeak;
use 5.008008;
use strict;
use warnings;
use POSIX qw(:termios_h);
use vars qw($VERSION);
$VERSION = '0.03';


sub new {
	my $pkg = shift;
	my $self = {
		"tts_engine" => "festival",
		"tts_command" => "",
		"no_dot_files" => 1,
		"hide_extentions" => 0,
		@_};
	return bless $self, $pkg;
}

sub say {
	my $self = shift;
	my $arg = shift;
	if ($self->{tts_command}){
		my $command = $self->{tts_command};
		$command =~s/text_arg/\"$arg\"/ 
	}elsif ($self->{tts_engine} eq "festival"){
		print "$arg\n";
		system "echo \"$arg\" | festival --tts";
	}elsif ($self->{tts_engine} eq "cepstral"){
		system "/opt/swift/bin/swift \"$arg\"";
	}
}

sub menu { 
	my $self = shift;
	my %var_hash = @_;
	my $count = 0;
	my @keys = sort(keys %var_hash);
	my $command = "";
	while (not $command){
		$self->say($keys[$count]);
		my $answ = $self->getch();
		if (ord($answ)==27){
			$answ  = $self->getch();
			if (ord($answ)==91){
				$answ  = $self->getch();
				$count++ if $answ =~/B/;
				$count-- if $answ =~/A/;
				$count = 0 if $count == scalar(@keys);
				$count = scalar(@keys) - 1 if $count < 0;
			}

		}elsif ((ord($answ)==10) or (ord($answ)==89) or (ord($answ)==121)){
			&{$var_hash{$keys[$count]}};
			$command = 1;
		}
	}
}

sub filepicker {
	my $self = shift;
	my $d = shift;
	my $file = "";
	my $flter = "";
	my $answ = "";
	my @tmp = ();
	my @lst = ();
	while (not $file) {
		my $count = 0;
		opendir DH, $d or die("Error opening directory: $d\n   $!");
		my @dirlst = (sort readdir DH) or die("Error reading directory: $d\n   $!");
		my $od = $d;
		while ((not $file) and ($od eq $d)) {
			my $f = $dirlst[$count];
			if ($f =~ /^\./){
				$count++;
				next;
			}
			if (-d"$d/$f"){
				$flter = $f;
				$flter =~ s/_/ /g;
				$self->say("Select Folder $flter?");
				$answ = $self->getch();
				if (ord($answ)==27){
					$answ  = $self->getch();
					if (ord($answ)==91){
						$answ  = $self->getch();
						$count++ if $answ =~/B/;
						$count-- if $answ =~/A/;
						$count = 0 if $count == scalar(@dirlst);
						$count = scalar(@dirlst) - 1 if $count < 0;
						if ($answ =~/C/){
							$d = "$d/$f";
							last;
						}
						if ($answ =~/D/){
							@lst = split '/', $d;
							pop @lst;
							$d = join '/', @lst;
							$d = '/' if $d eq "";
							next;
						}
					}
				}elsif ((ord($answ)==10) or (ord($answ)==89) or (ord($answ)==121)){
					$file = $self->filepicker("$d/$f");
				}elsif ((ord($answ)==85) or (ord($answ)==117)){
					@lst = split '/', $d;
					pop @lst;
					$d = join '/', @lst;
					$d = '/' if $d eq "";
					next;				
				}
			}elsif (-f"$d/$f"){
				$flter = $f;
				if ($self->{hide_extentions}){
					$flter =~ s/_/ /g;
					$flter =~ s/\.[\w]*//;
				}
				$self->say("Select File $flter?");
				$answ = $self->getch();
				if (ord($answ)==27){
					$answ  = $self->getch();
					if (ord($answ)==91){
						$answ  = $self->getch();
						$count++ if $answ =~/B/;
						$count-- if $answ =~/A/;
						$count = 0 if $count == scalar(@dirlst);
						$count = scalar(@dirlst) - 1 if $count < 0;
						if ($answ =~/C/){
							$file = "$d/$f";
							last;
						}
						if ($answ =~/D/){
							@lst = split '/', $d;
							pop @lst;
							$d = join '/', @lst;
							$d = '/' if $d eq "";
							next;
						}
					}
				}elsif ((ord($answ)==10) or (ord($answ)==89) or (ord($answ)==121)){
					$file = "$d/$f";
					last;
				}
			}else{print "Error $d/$f";}
		}
		closedir DH;
	}
	return $file;
}

sub dirpicker {
	my $self = shift;
	my $d = shift;
	my $folder = "";
	my $answ = "";
	my @lst = ();
	while ($folder eq "") {
		my $count = 0;
		opendir DH, $d or die("Error opening directory: $d\n   $!");
		my @dirlst = (sort readdir DH) or die("Error reading directory: $d\n   $!");
		closedir DH;
		while ($folder eq "") {
			my $f = $dirlst[$count];
			if ($f =~ /^\./){
				if ($f eq "." or $f eq ".." or $self->{no_dot_files}){
					$count++;
					next;
				}
			}
			if (-d"$d/$f"){
				$self->say("Select Folder $f?");
				$answ = $self->getch();
				if (ord($answ)==27){
					$answ  = $self->getch();
					if (ord($answ)==91){
						$answ  = $self->getch();
						$count++ if $answ =~/B/;
						$count-- if $answ =~/A/;
						$count = 0 if $count == scalar(@dirlst);
						$count = scalar(@dirlst) - 1 if $count < 0;
						if ($answ =~/C/){
							$folder = "$d/$f";
						}
						if ($answ =~/D/){
							@lst = split '/', $d;
							pop @lst;
							$d = join '/', @lst;
							$d = '/' if $d eq "";
							last;
						}

					}
				}elsif ((ord($answ)==10) or (ord($answ)==89) or (ord($answ)==121)){
					$folder = "$d/$f";
				}elsif ((ord($answ)==85) or (ord($answ)==117)){
					@lst = split '/', $d;
					pop @lst;
					$d = join '/', @lst;
					$d = '/' if $d eq "";
					next;
				}

			}else{
				next;
			}
		}
	}
	if ($folder eq "") {
		$self->say("There are no folders to select.");
	}
	return $folder;
}

sub getch {
	my $self = shift;
        my $fd_stdin = fileno(STDIN);
        my $term = POSIX::Termios->new();
        $term->getattr($fd_stdin);
        my $oterm = $term->getlflag();
        my $echo = ECHO | ECHOK | ICANON;
        my $noecho = $oterm & ~$echo;
        my $key = '';
        $term->setlflag($noecho);
        $term->setcc(VTIME, 1);
        $term->setattr($fd_stdin, TCSANOW);
        sysread(STDIN, $key, 1);
    	$term->setlflag($oterm); 
    	$term->setcc( VTIME, 0);
    	$term->setattr($fd_stdin, TCSANOW); 
        return $key;
}
1;

__END__

=head1 NAME

PerlSpeak - Perl Module for text to speach with festival or cepstral

=head1 SYNOPSIS

  use PerlSpeak;
  
  my $ps = PerlSpeak->new();
  
  # Set properties
  $ps->{tts_engine} = "festival"; # or cepstrel
  # Optionally set your own tts command use text_arg where the text goes
  $ps->{tts_command} => ""; 
  $ps->{no_dot_files} => 1;
  $ps->{hide_extentions} => 0;
    
   
  # Speaking file selectors
  my $file = $ps->filepicker($ENV{HOME}); # Returns a file.
  my $dir = $ps->dirpicker($ENV{HOME}); # Returns a directory.
  
  $ps->say("Hello World!"); # The computer talks.

  # Returns the next character typed on the keyboard
  # May take 2 or 3 calls for escape sequences.
  print $ps->getch(); 

  # Make some sub refs to pass to menu  
  my $email = sub {
	print "Email\n";
  };
  my $internet = sub {
	print "Internet\n";
  };
  my $docs = sub {
	print "Documents\n"
  };
  my $mp3 = sub {
	print "MP3\n";	
  };
  my $cdaudio = sub {
	print "CD Audio\n"
  };
  my $help = sub {
	print "Browse Help\n"
  };

  # menu is a talking menu
  # Pass menu a hash of "text to speak" => $callback pairs
  $ps->menu(
	"E-mail Menu" => $email,
	"Internet Menu" => $internet,
	"Documents Menu" => $docs,
	"M P 3 audio" => $mp3,
	"C D audio" => $cdaudio,
	"Browse help files" => $help,
  };


=head2 METHODS

 $ps = PerlSpeak->new(property => value, ...);

 $ps->say("Text to speak.");

 $path = $ps->filepicker("/start/directory");

 $path = $ps->dirpicker("/start/directory");

 $chr = $ps->getchr(); # Returns next character typed on keyboard

 # An audio menu executes callback when item is selected 
 $ps->menu("Text to speak" => $callback, ...) 


=head2 PROPERTIES

 $ps->{tts_engine} => "festival" or "cepstral";
 
 $ps->{tts_command} => "command text_arg";
 
 $ps->{no_dot_files} => $boolean; # Default is 1
 
 $ps->{hide_extentions} => $boolean;  # Default is 0
 
 
 
=head1 DESCRIPTION

  PerlSpeak.pm is Perl Module for text to speach with festival or cepstral.
  One of these must be installed on your system in order for PerlSpeak.
  Plans to include other tts systems in future releases.
  PerlSpeak.pm was developed to use in the PerlSpeak system for blind linux users.
  More information can be found at the authors website http://www.joekamphaus.net


=head1 CHANGES

1/9/2007 ver 0.03

* Fixed error handling for opendir and readdir.

* Added property tts_command => $string 
    (insert "text_arg" where the text to speak should be.)

* Added property no_dot_files => $boolean default is 1
    (Set to 0 to show hidden files)

* Fixed bug in tts_engine => "cepstral" (previously misspelled as cepstrel)

* Added funtionality to traverse directory tree up as well as down.
    (user can now use the arrow keys for browsing and selecting
    up and down browses files in current directory. Right selects the 
    file or directory. Left moves up one directory like "cd ..")

* Added property hide_extentions => $boolean to turn off speaking of file
    extensions with the filepicker method. Default is 0.
    


=head1 SEE ALSO


  More information can be found at the authors website http://www.joekamphaus.net

=head1 AUTHOR

joe, E<lt>joe@joekamphaus.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Joe Kamphaus

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
