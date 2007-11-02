package PerlSpeak;
use 5.006;
use strict;
use warnings;
use POSIX qw(:termios_h);
use vars qw($VERSION);
$VERSION = '1.50';


sub new {
	my $pkg = shift;
	my $self = {
		"tts_engine" => "festival",
		"tts_command" => "",
		"tts_file_command" => "",
		"file2wave_command" => "",
		"make_readable" => "[_\/]",
		"no_dot_files" => 1,
		"hide_extentions" => 0,
		"browsable" => 1,
		"dir_return" => 1,
		"file_prefix" => "File",
		"dir_prefix" => "Folder",
		"echo_off" => 0,
		@_};
        $self->{tts_engine} = $ENV{TTS} if $ENV{TTS};
	return bless $self, $pkg;
}

sub say {
	my $self = shift;
	my $arg = shift;
	chomp $arg;
	print "\n$arg\n" unless $self->{echo_off};
	if ($self->{tts_command}){
		my $command = $self->{tts_command};
		$command =~s/text_arg/\"$arg\"/ ;
		system $command or die "Error with tts_command";
	}elsif ($self->{tts_engine} eq "festival"){
		system "echo \"$arg\" | festival --tts";
	}elsif ($self->{tts_engine} eq "cepstral"){
		system "swift \"$arg\"";
	}
}

sub readfile {
	my $self = shift;
	my $arg = shift;
	if (-e $arg){
		if ($self->{tts_file_command}){
			my $command = $self->{tts_file_command};
			$command =~s/file_arg/$arg/;
			system $command;
		}elsif ($self->{tts_engine} eq "festival"){
			system "festival --tts $arg";
		}elsif ($self->{tts_engine} eq "cepstral"){
			system "$self->{path_to_tts}swift -f $arg";
		}else {
			$self->say("ERROR! with tts engine or tts  file command.") & die "ERROR! with tts_engine or tts_file_command.";
		}	
	} else {
		$self->say("ERROR! $arg is not a file.") & die "ERROR! $arg is not a file.";
	}
}

sub file2wave {
	my $self = shift;
	my $in = shift;
	my $out = shift;
	if (-e $in){
		if ($self->{file2wave_command}){
			my $command = $self->{file2wave_command};
			$command =~s/IN/$in/;
			$command =~s/OUT/$out/;
			system "$command";
		} elsif ($self->{tts_engine} eq "festival") {
			system "text2wave -otype riff -o $out $in";
		} elsif ($self->{tts_engine} eq "cepstral") {
			system "swift -f $in -o $out";
		}
	} else {
		$self->say("ERROR! $in is not a file.") & die "ERROR! $in is not a file.";
	}
}

sub menu { 
	my $self = shift;
	my %var_hash = @_;
	my $count = 0;
	my @keys = sort(keys %var_hash);
	my $str = "";
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

		} elsif ($answ =~ /\d/) {
			$count = $answ -1;
		} elsif ($answ =~ /\w/) {
			$str .= uc $answ;
			foreach my $i (0..$#keys) {
				my $test = uc $keys[$i];
				$count = $i and last if ($test =~ /^\d\. $str/);
			}
		} elsif ((ord($answ)==10) or (ord($answ)==13) or (ord($answ)==89) or (ord($answ)==121)){
			$command = 1;
			&{$var_hash{$keys[$count]}};
		}
	}
}

sub menu_list {
	my $self = shift;
	my @lst;
	while (my $word = shift) {
		push @lst, $word;
	}
	my $count = 0;
	while (1) {
		$self->say($lst[$count]);
		my $answ = $self->getch();
		if (ord($answ)==27){
			$answ  = $self->getch();
			if (ord($answ)==91){
				$answ  = $self->getch();
				$count++ if $answ =~/B/;
				$count-- if $answ =~/A/;
				$count = 0 if $count >= $#lst;
				$count = $#lst if $count < 0;
			}
		} elsif ((ord($answ)==10) or (ord($answ)==13) or (ord($answ)==89) or (ord($answ)==121)){
			last;
		}
	}
	return $lst[$count];
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
			if (($f eq ".") or ($f eq "..") or ($self->{no_dot_files} and $f =~/^\./)) {
				$count++;
				next;
			}
			if (-d"$d/$f"){
				$flter = $f;
				$flter =~ s/_/ /g;
				$self->say("$self->{dir_prefix} $flter?");
				$answ = $self->getch();
				if (ord($answ)==27){
					$answ  = $self->getch();
					if (ord($answ)==91){
						$answ  = $self->getch();
						$count++ if $answ =~/B/;
						$count-- if $answ =~/A/;
						$count = 0 if $count == scalar(@dirlst);
						$count = scalar(@dirlst) - 1 if $count < 0;
						if (($answ =~/C/) && ($self->{browsable})) {
							$d = "$d/$f";
							last;
						}
						if (($answ =~/D/) && ($self->{browsable})) {
							@lst = split '/', $d;
							pop @lst;
							$d = join '/', @lst;
							$d = '/' if $d eq "";
							next;
						}
					}
				}elsif ((ord($answ)==10) or (ord($answ)==13) or (ord($answ)==89) or (ord($answ)==121)){
					$file = "$d/$f";
					return $file;
				}elsif ((ord($answ)==85) or (ord($answ)==117)){
					@lst = split '/', $d;
					pop @lst;
					$d = join '/', @lst;
					$d = '/' if $d eq "";
					next;				
				}
			}elsif (-f "$d/$f"){
				$flter = $f;
				if ($self->{hide_extentions}){
					$flter =~ s/\.[\w]*$//;
				}
				if ($self->{make_readable}) {
					my $pattern = $self->{make_readable};
					$flter =~ s/$pattern/ /g;
				}
				$self->say("$self->{file_prefix} $flter?");
				$answ = $self->getch();
				if (ord($answ)==27){
					$answ  = $self->getch();
					if (ord($answ)==91){
						$answ  = $self->getch();
						$count++ if $answ =~/B/;
						$count-- if $answ =~/A/;
						$count = 0 if $count == scalar(@dirlst);
						$count = scalar(@dirlst) - 1 if $count < 0;
						if (($answ =~/C/) && ($self->{browsable})) {
							$file = "$d/$f";
							last;
						}
						if (($answ =~/D/) && ($self->{browsable})) {
							@lst = split '/', $d;
							pop @lst;
							$d = join '/', @lst;
							$d = '/' if $d eq "";
							next;
						}
					}
				}elsif ((ord($answ)==10) or (ord($answ)==89) or (ord($answ)==121)){
					$file = "$d/$f";
					return $file;
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
				$self->say($f);
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

sub getString {
	my $self = shift;
	my $prompt = shift;
	$self->say($prompt);
	my $ord = 0;
	my $string;
	my @chrlst;
	until ($ord == 10){
		my $chr = $self->getch();
		$ord = ord($chr);
		if ($ord == 127) {
			pop @chrlst;
			$self->say("Backspace");
		} elsif ($ord == 32) {
			$self->say("Space");
			push @chrlst, $chr;
		} elsif ($chr =~ /[\w,.-_\n]/) {
			$self->say($chr);
			push @chrlst, $chr;
		} elsif ($ord < 28) {
			return $ord;
		}
	}
		
	$string = join '', @chrlst;
	chomp $string;
	$self->say("You have entered $string. Is this correct?");
	$self->confirm() ? return $string : return $self->getString($prompt);
}

sub confirm {
	my $self = shift;
	my $answ = $self->getch();
	return 1 if $answ =~/[yY\n]/;
	return 0 if $answ =~/[nN]/;
	$self->say("Please answer Y for yes or N for no.");
	return confirm();
}

1;

__END__

=head1 NAME

 PerlSpeak - Perl Module for text to speech with festival, cepstral and others.

=head1 SYNOPSIS

 my $ps = PerlSpeak->new([property => value, property => value, ...]);

=head2 METHODS

 $ps = PerlSpeak->new([property => value, property => value, ...]);
 # Creates a new instance of the PerlSpeak object.

 $ps->say("Text to speak.");
 $ps->say("file_name");
 # The basic text to speech interface.
 
 $ps->readfile("file_name");
 # Reads contents of a text file.
 
 $ps->file2wave("text_file_in", "audio_file_out");
 # Converts a text file to an audio file.

 $path = $ps->filepicker("/start/directory");
 # An audio file selector that returns a path to a file. If "dir_return" is true
 # "filepicker" may also return the path to a directory.

 $path = $ps->dirpicker("/start/directory");
 # An audio directory selector that returns a path to a directroy.

 $chr = $ps->getchr(); 
 # Returns next character typed on keyboard

 $ps->menu("Text to speak" => $callback, ...) 
 # An audio menu executes callback when item is selected

 $item = $ps->menu_list(@list);
 # Returns element of @list selected by user.

 $string = $ps->getString();
 # Returns a string speaking each character as you type. Also handles backspaces

 $boolean = $ps->confirm();
 # Returns boolean. Prompts user to enter Y for yes or N for no.  Enter also returns true.


=head2 PROPERTIES

 # The default property settings should work in most cases. The exception is
 # if you want to use a tts system other than festival or cepstral. The rest
 # of the properties are included because I found them usefull in some instances.

 $ps->{tts_engine} => "festival" or "cepstral"; # Default is "festival"
 # Other tts engines can be used by using the tts command properties.
 
 $ps->{tts_command} => "command text_arg"; # Default is ""
 # Command to read a text string. "text_arg" = text string.
 
 $ps->{tts_file_command} => "command file_arg" # Default is ""
 # Command to read a text file. "file_arg"  = path to text file to be read.
 
 $ps->{file2wave_command} => "command IN OUT"; # Default is ""
 # Command for text file to wave file. "IN" = input file "OUT" = output file.
 # Not needed if tts_engine is festival" or "cepstral.
 
 $ps->{no_dot_files} => $boolean; # Default is 1
 $ Hides files that begin with a '.'
 
 $ps->{hide_extentions} => $boolean;  # Default is 0
 # Will hide file extensions.
 # NOTE: If hiding extensions the no_dot_files property must be set to 1.
 
 $ps->{make_readable} => "regexp pattern"; # default is "[_\\]"  
 # will substitute spaces for regexp pattern 
 
 $ps->{browsable} => $boolean; # Default is 1
 # If true filepicker can browse other directories via the right and left arrows. 
 
 $ps->{dir_return} => $boolean; # Default is 1
 # If true filepicker may return directories as well as files.
 
 $ps->{file_prefix} => $text; # Default is "File"
 # For filepicker. Sets text to speak prior to file name. 
 
 $ps->{dir_prefix} => "text"; # Default is "Folder"
 # For filepicker and dirpicker. Sets text to speak prior to directory name. 

 $ps->{echo_off} => $boolean; # Default is 0
 # If set to true, turns off printing of text to screen.
 
=head1 DESCRIPTION

  PerlSpeak.pm is Perl Module for text to speech with festival or cepstral.
  (Other tts systems may be used by setting the tts command properties).
  PerlSpeak.pm includes several useful interface methods like an audio file 
  selector and menu system. PerlSpeak.pm was developed to use in the 
  Linux Speaks system, an audio interface to linux for blind users. 
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
    (NOTE: If hiding extensions the no_dot_files property must be set to 1)
    
 * Added property "make_readable" which takes a regular expression as an
    argument. PerlSpeak.pm substitues a space for characters that match
    expression. The default is "[_\\]" which substitutes a space for "\"
    and "_".



 1/9/2007 ver 0.50
 
 * Added funtionality for reading a text file. Method "say" will now take
    text or a file name as an argument. Also added method "readfile" which
    takes a file name as an argument. The property tts_file_command was also
    added to accomodate tts systems other than festival or cepstral.

 * Added funtionality for converting a text file to a wave file via the
    "file2wave" method and optionally the "file2wave_command" property.
 
 * Added properties "file_prefix" and "dir_prefix" to enable changing
    text to speak prior to file and directory names in the "filepicker"
    and "dirpicker" methods.
    
 * Added "browsable", a boolean property which will togle the browsable feature
    of the "filepicker" method. 
    
 * Added "dir_return", a boolean property which will allows the "filepicker" 
    method to return the path to a directory as well as the path to a file.
    
 * Changed required version of perl to 5.6. I see no reason why PerlSpeak.pm
    should not work under perl 5.6, however, this has not yet been tested. If
    you have problems with PerlSpeak on your version of perl let me know.
    
    

 10/10/2007 ver 1.50
  * Added boolean property echo_off to turn off printing of text said to screen.

  * Added method menu_list(@list) Returns element of @list selected by user.

  * Added method getString() Returns a string speaking each character as you
    type. Also handles backspaces.

  * Added method conirm(). Returns boolean. Prompts user to enter Y for yes
    or N for no.  Enter also returns true.

  * Added shortcuts to the menu() method. You can press the number of menu
    index or the letter of the first word in menu item to jump to that item.


=head1 EXAMPLE

  use PerlSpeak;
  
  my $ps = PerlSpeak->new();
  
  # Set properties
  $ps->{tts_engine} = "festival"; # or cepstrel
  # Optionally set your own tts command use text_arg where the text goes
  $ps->{tts_command} => ""; 
  $ps->{no_dot_files} => 1;
  $ps->{hide_extentions} => 0;
    
   
  # Audio file selectors
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

  # menu is a audio menu
  # Pass menu a hash of "text to speak" => $callback pairs
  $ps->menu(
	"E-mail Menu" => $email,
	"Internet Menu" => $internet,
	"Documents Menu" => $docs,
	"M P 3 audio" => $mp3,
	"C D audio" => $cdaudio,
	"Browse help files" => $help,
  };


=head1 SEE ALSO

  More information can be found at the authors website http://www.joekamphaus.net
  
  The Festival Speech Synthesis System can be found at:
    http://www.cstr.ed.ac.uk/projects/festival/

  The Flite (festival-lite) Speech Synthesis System can be found at:
    http://www.speech.cs.cmu.edu/flite/index.html

  Reasonably priced high quality proprietary software voices from Cepstral 
  can be found at: http://www.cepstral.com.

=head1 AUTHOR

Joe Kamphaus, E<lt>joe@joekamphaus.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Joe Kamphaus

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
