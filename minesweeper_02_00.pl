#!/usr/local/bin/perl5.6.1


sub initiate;				# passes back the initiation data and field (by reference)
sub fill_field;				# pass $level: $width, $higth, $numofminesl (by value) and field (by reference)
sub bind_buttons;           # binds the buttons and fills the field
sub min;					# pass LIST
sub look_around;			# pass $x, $y, $width, $height, /@field, $total
sub create_ini_file;		# creates an ini file
sub about;					# creates the "about" window
sub create_field;			# draws the mine field
sub new_game;				# starts new game
sub get_custom_info;		# enables the user to enter the data for custom level
sub hit_a_mine;				# stops game and shows field if mine has been hit
sub game_won;				# end of game if game won
sub help;					# displays the help menu
sub check_coverage;			# checks whther the Button-2 option is OK
sub best_times;				# displays the best times
sub write_ini;				# updates the ini file
sub OkCanc;					# displays R U Sure message
sub mark_btn;               # Changes the markings on a pressed button
sub set_cell_colors;		# sets the value of %cell_colors

#################################################
#												#
# This is the main Program.						#
#												#
#################################################

use Tk;

#use lib "/users/dovl/local/perl/lib";
use Pod::Text;

use vars qw($APP);
use vars qw($VERSION);
use vars qw($LIB_PATH);
use vars qw($MAN_PATH);
use vars qw($MAN_PAGE);
use vars qw($MAN_VIEWER);

my $ini_file = '.\minesweeper.ini';

use vars qw(%current);				# contains the level, and the width, height and nomofmines if level is custom
use vars qw(@field);				# the mine field
use vars qw($marks);				# if marks =1 the ? option is enabled
use vars qw(@mine_btns);			# an array of links to all the buttons
use vars qw($uncovered);			# how many buttons are uncovered
use vars qw($time);					# game timer
use vars qw($flags);				# counts flags
use vars qw($first);				# changes value when first button is hit
use vars qw($colors);				# if colors = 1, the colors are turned on
use vars qw($raised_color);	        # the color of the filed can vary from gray70 to gray100 (white)
use vars qw($sunken_color);			# the sunken buttons are always darker than the raised ones.
use vars qw(%cell_colors);          # the color of the writing in the cells
use vars qw($field_frame);          # the frame in which the field resides


$APP = "Minesweeper";
$VERSION = "2.00";
$LIB_PATH = "/users/dovl/local/perl/lib";
$MAN_PATH = "/users/dovl/local/man";
$MAN_PAGE = "/mandovl/minesweeper.dovl";
$MAN_VIEWER = "/usr/dt/bin/dthelpview";
$raised_color = '85';
$sunken_color = '80';

local $SIG{ALRM} = sub {$time = sprintf ("%3.0d",++$time); alarm(1) if ($time < 999);};

\&initiate();

# Main Window
$MW = MainWindow->new(-background => "gray85",);
$MW -> title("Minesweeper $VERSION (dovl)");
$MW -> resizable(0, 0);
if (-e "$LIB_PATH/mine.gif"){
	my $icon=$MW->Photo(-file=>"$LIB_PATH/mine.gif",-palette =>'red');#agembaras
	$MW->Icon(-image=>$icon,);
}


my $menus = $MW->Frame(-background => "gray85",);
$menus -> pack(
	-side => 'top',
	-fill =>'x',
	);

my $restart = $MW->Frame(-background => "gray85",);
$restart -> pack(
	-side => 'top',
	-fill =>'x',
	-pady => '10',
	-anchor => 'center',
	);

$field_frame =$MW->Frame(-background => "gray85",);
$field_frame -> pack(-side => 'bottom', -fill =>'x');

# Main menu
my $main_menu = $menus->Menubutton(
	-background => "gray85",
	-text => "Menu",
	-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
	-tearoff => '0',
	);
$main_menu-> pack(
	-side => 'left',
	);
$main_menu -> command(
	-label => 'New Game',
	-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
	-background => "gray85",
	-command => [sub {\&new_game()}],
	);
$main_menu -> separator;
$main_menu -> radiobutton(
	-label => 'Beginner',
	-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
	-background => "gray85",
	-variable => \$current{level},
	-value => 'Beginner',
	-command => [sub {\&new_game(1)}],
	);
$main_menu -> radiobutton(
	-label => 'Intermediate',
	-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
	-background => "gray85",
	-variable => \$current{level},
	-value => 'Intermediate',
	-command => [sub {\&new_game(1)}],
	);
$main_menu -> radiobutton(
	-label => 'Expert',
	-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
	-background => "gray85",
	-variable => \$current{level},
	-value => 'Expert',
	-command => [sub {\&new_game(1)}],
	);
$main_menu -> radiobutton(
	-label => 'Custom',
	-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
	-background => "gray85",
	-variable => \$current{level},
	-value => "Custom",
	-command => [sub {\&get_custom_info();
						\&new_game(1)}],
	);
$main_menu -> separator;
$marks_btn = $main_menu -> checkbutton(
	-label => "Marks (?)",
	-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
	-background => "gray85",
	-variable => \$marks,
	-offvalue => '0',
	-onvalue => '1',
	);
$colors_btn = $main_menu -> checkbutton(
	-label => "Colors",
	-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
	-background => "gray85",
	-variable => \$colors,
	-offvalue => '0',
	-onvalue => '1',
	-command => [sub {\&set_cell_colors()}]	);
$main_menu -> separator;
$main_menu -> command(
	-label => 'Best Times',
	-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
	-background => "gray85",
	-command => [sub {\&best_times()}],
	);
$main_menu -> separator;
$main_menu -> command(
	-label => 'Exit',
	-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
	-background => "gray85",
	-command => [sub {exit}],
	);
my $color_slide = $menus->Scale(
	-from => '70',
	-to => '100',
	-orient => 'horizontal',
	-showvalue => '0',
	-label => "BG Color",
	-tickinterval => '15',
	-variable => \$raised_color,
	-background => 'gray85',
	-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
	-command => [sub {$sunken_color = ($raised_color-5);
					\&new_game()}],
	);
$color_slide -> pack(-anchor => 'center',
					);
# Help menu
my $help_menu = $menus->Menubutton(
	-text => "Help",
	-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
	-background => "gray85",
	-tearoff => '0',
	);
$help_menu -> pack(
	-side => 'right',
	-before => $color_slide,
	);
$help_menu -> command(
	-label => 'Help Topics',
	-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
	-background => "gray85",
	-command => [sub {\&help ()}],
	);
$help_menu -> command(
	-label => 'About Minesweeper',
	-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
	-background => "gray85",
	-command => [sub {\&about()}],
	);
$help_menu -> command(
	-label => 'Credits',
	-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
	-background => "gray85",
	-command => [sub {\&credits}],
	);

# Counter of mines
my $counter = $restart -> Label(-textvariable => \$flags,
								-foreground => 'RoyalBlue',
								-background => "gray85",
								-padx => '20',
								-pady => '10',
								-relief => 'ridge',
								-font => '-adobe-courier-bold-r-normal-*-*-300-*-*-m-*-koi8-1',
								);
$counter -> pack ( -anchor => 'w',
				-side => 'left',
				-fill => 'none',
				);


# Give up button
#my $give_up = $restart->Button(
#	-text => 'I Give Up',
#	-font => '-adobe-courier-bold-r-normal-*-*-120-*-*-m-*-koi8-1',
#	-background => "gray85",
#	-command => [sub {if ($first == 1){
#						\&hit_a_mine(($current{width}+1), ($current{height}+1),)
#					}}],
#	-anchor => 'center',
#	);
#$give_up -> pack(-anchor => 'center',
#					);

# Restart button
my $restart_btn = $restart->Button(
	-text => 'New Game',
	-font => '-adobe-courier-bold-r-normal-*-*-200-*-*-m-*-koi8-1',
	-background => "gray85",
	-command => [sub {\&new_game()}],
	-anchor => 'center',
	);
$restart_btn -> pack(-anchor => 'center',
#				-before => $give_up,
					);
# Time Counter
my $timer = $restart -> Label(-textvariable => \$time,
								-foreground => 'RoyalBlue',
								-background => "gray85",
								-padx => '20',
								-pady => '10',
								-relief => 'ridge',
								-font => '-adobe-courier-bold-r-normal-*-*-300-*-*-m-*-koi8-1',
								);
$timer -> pack (-anchor => 'e',
				-side => 'right',
				-before => $restart_btn,
				);


\&create_field();

MainLoop;


#################################################################################################
#################################################################################################
#																								#
#										SUBROUTINES												#
#																								#
#################################################################################################
#################################################################################################


#################################################
#												#
# initiate fills 4 hashes:						#
# Beginner, Intermediate, Custom:				#
#			the name and score of the best 		#
#			player in that level				#
# current: the current level (and field stats	#
#			if level is Custom)					#
#												#
# this function calls 'fill_field' and returns 	#
# a filled mine field.							#
#												#
#################################################

sub initiate{

	alarm(0);				# stop any previous timers

	unless ($current{level} =~ m/Beginner|Intermediate|Expert|Custom/){
		unless (-e "$ini_file"){create_ini_file;}
		open (INI,"<$ini_file") || die "Can not open $ini_file for reading!\n";
		$line=<INI>;		# DO NOT ERASE
		chomp ($line=<INI>); ($marks, $colors) = split / /, $line;
		chomp ($line=<INI>); ($current{level}, $current{width}, $current{height}, $current{numofmines}) = split / /, $line;
	}
	$marks = 0 unless ($marks==1);
	$colors = 1 unless ($colors==0);

	# test for a corrupt ini file
	if (($current{width} =~ m/[^0-9]/) || ($current{height} =~ m/[^0-9]/) || ($current{numofmines} =~ m/[^0-9]/)){
				print STDOUT "You played around with the .ini file, very naughty!!!\n";
				print STDOUT "We are creating a new one.\n";
				print STDOUT "All your previous high scores have been reset!\n";
				unlink "$ini_file" || die "Can't fix $ini_file.\nErase it manually\n";
				create_ini_file;
				open (INI,"</users/$ENV{USER}/.minesweeper.ini") || die "Can not open /users/$ENV{USER}/.minesweeper.ini for reading!\n";
				$line=<INI>;		# DO NOT ERASE
				chomp ($line=<INI>); ($marks, $colors) = $line;
				chomp ($line=<INI>); ($current{level}, $current{width}, $current{height}, $current{numofmines}) = split / /, $line;
				close (INI);
	}

	# these next few lines default the mine field to
	# Beginner size (Custom game), if not otherwise set;
	$current{level} = "Beginner" unless ($current{level} =~ m/Intermediate|Expert|Custom/);
	$current{width} = 	$current{level} =~ "Beginner" ? 8 :
			 			$current{level} =~ "Intermediate" ? 16 :
			 			$current{level} =~ "Expert" ? 30 :
			 			$current{width} <= 8 ? 8 :
			 			$current{width} >= 30 ? 30 :
						$current{width};
	$current{height} = $current{level} =~ "Beginner" ? 8 :
			 			$current{level} =~ "Intermediate" ? 16 :
			 			$current{level} =~ "Expert" ? 16 :
			 			$current{height} <= 8 ? 8 :
			 			$current{height} >= 24 ? 24 :
			 			$current{height};
	$current{numofmines} = $current{level} =~ "Beginner" ? 10 : 
			 				$current{level} =~ "Intermediate" ? 40 :
			 				$current{level} =~ "Expert" ? 99 :
							$current{numofmines} && ($current{numofmines} > 0) && ($current{numofmines} <= (($current{width}-3)*($current{height}-3))) ? min($current{numofmines},667):
							(($current{width}-3)*($current{height}-3));

	# initiation of general variables
	$uncovered = 0;
	$time = '  0';
	$flags = $current{numofmines};
	$first = 0;

	\&set_cell_colors();

	return;
}

#################################################
#												#
# starts new game							  	#
#												#
#################################################

sub new_game{
	
	my $destroy = (defined $_[0]) ? shift : undef;

    \&initiate();

	if (defined $destroy) {
		my @to_destroy = $field_frame -> children();
		foreach $frame (@to_destroy){
			Tk::destroy($frame);
		}
		\&create_field();
	}	
	else {
		for my $y (0..($current{height}-1)){
			for my $x (0..($current{width}-1)){
				${$mine_btns[$y][$x]} -> configure(
					-text => '',
					-height => '0',
					-width => '1',
					-state => 'normal',
					-background => "gray$raised_color",
					-font => '-adobe-courier-bold-r-normal-*-*-120-*-*-m-*-koi8-1',
					-relief => 'raised',
				);
			}
		}
	}	
		
	@field = ();
	\&bind_buttons();
			
	return;
}

#################################################
#												#
# binds the buttons and fills the field		  	#
#												#
#################################################

sub bind_buttons {
	
	# bind different options to the buttons, depending on the button pressed
	for my $y (0..($current{height}-1)){
		for my $x (0..($current{width}-1)){
			${$mine_btns[$y][$x]} -> bind ("<ButtonRelease-1>", sub {unless ($first){
																				\&fill_field($y, $x);
																				$first = 1;
																				alarm(1);
																			}
																	\&look_around($x, $y, 1, 1);
																});
			${$mine_btns[$y][$x]} -> bind ("<ButtonRelease-2>", sub {if ((${$mine_btns[$y][$x]} -> cget(-text)) =~ m/[1-8]/){
									\&check_coverage($x, $y);}});
			${$mine_btns[$y][$x]} -> bind ("<ButtonRelease-3>", sub {\&mark_btn($x, $y)});
		}
	}
	return;
}

#################################################
#												#
# draws the mine field						  	#
#												#
#################################################

sub create_field{
	
	# create a frame for each row of buttons
	# and place the buttons in them
    @mine_btns = ();
	@field = ();

	for my $y (0..($current{height}-1)){
		${"frame"."$y"} = $field_frame -> Frame (-background => 'grey85',) -> pack();
		for my $x (0..($current{width}-1)){
			${"row"."$y"."column"."$x"} = ${"frame"."$y"} -> Button(
				-text => '',
				-height => '0',
				-width => '1',
				-state => 'normal',
				-background => "gray$raised_color",
				-font => '-adobe-courier-bold-r-normal-*-*-120-*-*-m-*-koi8-1',
			);
			${"row"."$y"."column"."$x"} -> pack (
				-side => 'left',
			);
			$mine_btns[$y][$x] = \${"row"."$y"."column"."$x"};
		}
	}
	\&bind_buttons();
	return;

}



#################################################
#												#
# fill_field fills the mine field with mines	#
# using random filling							#
#												#
# $level can be Beginner, Intermediate, Expert	#
# $width is width of mine field					#
# $higth is height of mine field				#
# $numofmines is number of mines in field		#
#												#
# @field looks like this:	|-----|-----|-----|	#
# 							| 0,0 | 0,1 | 0,2 | #
#							|-----|-----|-----|	#
#							| 1,0 | 1,1 | 1,2 |	#
#							|-----|-----|-----|	#
#												#
#################################################

sub fill_field{
	my $y = shift;
	my $x = shift;
	

	srand(time ^ $$);

 	for (1..$current{numofmines}){
		my $random_y = int(rand ($current{height}));
		my $random_x = int(rand ($current{width}));
		redo if (($field[$random_y][$random_x] =~ "m") || (($y == $random_y) && ($x == $random_x)));
		$field[$random_y][$random_x] = "m";
	}
	return;
}

#################################################
#												#
# look_around checks to see how many mines  	#
# there are around a given location				#
# (recursivly).									#
#												#
#################################################

sub look_around{
	my $x = shift; 				# X coordination
	my $y = shift; 				# Y coordination
	my $origional = shift; 		# shows if this is the original call to the recursive subroutine
	my $cause = shift;			# which button invoked the call (1 or 2)

	my $btn_width = 0;

	# this line is to prevent unwanted results by pressng pre-pressed buttons
	return if ((((${$mine_btns[$y][$x]} -> cget(-relief)) =~ 'sunken') && ($cause == 1)) || ((${$mine_btns[$y][$x]} -> cget(-text)) =~ 'F'));

	# if pressed a mine
	if ($field[$y][$x]) {
		\&hit_a_mine($x, $y);
		return;}

	my $total = 0;
	my $left = my $right = my $up = my $down = 1;
	$left = 0  if ($x == 0);
	$right = 0 if ($x == ($current{width}-1));
	$up = 0    if ($y == 0);
	$down = 0  if ($y == ($current{height}-1));
	$total++ if ($up && $left && $field[$y-1][$x-1]);
	$total++ if ($up && $field[$y-1][$x]);
	$total++ if ($up && $right && $field[$y-1][$x+1]);
	$total++ if ($left && $field[$y][$x-1]);
	$total++ if ($right && $field[$y][$x+1]);
	$total++ if ($down && $left && $field[$y+1][$x-1]);
	$total++ if ($down && $field[$y+1][$x]);
	$total++ if ($down && $right && $field[$y+1][$x+1]);

	if (${$mine_btns[$y][$x]} -> cget (-relief) !~ 'sunken'){
		${$mine_btns[$y][$x]} -> configure (-relief => 'sunken',
											-background => "gray$sunken_color",);
		++$uncovered;
	}

	if (($total == 0) || ($cause == 2)){
		if ($up && $left)    {&look_around(($x-1), ($y-1), 0, 1)}
		if ($up) 		     {\&look_around($x,     ($y-1), 0, 1)}
		if ($up && $right)   {&look_around(($x+1), ($y-1), 0, 1)}
		if ($left) 		     {\&look_around(($x-1), $y,     0, 1)}
		if ($right) 	     {\&look_around(($x+1), $y,     0, 1)}
		if ($down && $left)  {&look_around(($x-1), ($y+1), 0, 1)}
		if ($down) 			 {\&look_around($x, ($y+1),     0, 1)}
		if ($down && $right) {&look_around(($x+1), ($y+1), 0, 1)}
		$total = ' ';
		$btn_width = 1;
	}
	if ((${$mine_btns[$y][$x]} -> cget(-text)) !~ m/[1-8]/){
		${$mine_btns[$y][$x]} -> configure (-text => "$total",
											-width => "$btn_width",
											-foreground => "$cell_colors{$total}",
											);
	}
	if (($current{width} * $current{height} - $uncovered) == $current{numofmines}){
		$flags = 0;
		\&game_won();
		return;
	}

	Tk::break if ($origional);
	return;
}


#################################################
#												#
# uses middle button						  	#
#												#
#################################################

sub check_coverage{
	my $x = shift; 				# X coordination
	my $y = shift; 				# Y coordination

	my $total = 0;
	my $left = my $right = my $up = my $down = 1;
	$left = 0  if ($x == 0);
	$right = 0 if ($x == ($current{width}-1));
	$up = 0    if ($y == 0);
	$down = 0  if ($y == ($current{height}-1));
	$total++ if ($up && $left && (${$mine_btns[$y-1][$x-1]} -> cget(-text) =~ 'F' ));
	$total++ if ($up && (${$mine_btns[$y-1][$x] } -> cget(-text) =~ 'F' ));
	$total++ if ($up && $right && (${$mine_btns[$y-1][$x+1]} -> cget(-text) =~ 'F' ));
	$total++ if ($left && (${$mine_btns[$y][$x-1]} -> cget(-text) =~ 'F' ));
	$total++ if ($right && (${$mine_btns[$y][$x+1]} -> cget(-text) =~ 'F' ));
	$total++ if ($down && $left && (${$mine_btns[$y+1][$x-1]} -> cget(-text) =~ 'F' ));
	$total++ if ($down && (${$mine_btns[$y+1][$x]} -> cget(-text) =~ 'F' ));
	$total++ if ($down && $right && (${$mine_btns[$y+1][$x+1]} -> cget(-text) =~ 'F' ));

	if ($total == (${$mine_btns[$y][$x]} -> cget(-text))){
		\&look_around($x, $y, 0, 2);
	}
	return;
}


#################################################
#												#
# changes the marking on the button			  	#
#												#
#################################################

sub mark_btn{
	my $x = shift; 				# X coordination
	my $y = shift; 				# Y coordination

	# this line is to prevent unwanted results by pressng pre-pressed buttons
	if ((${$mine_btns[$y][$x]} -> cget(-relief)) =~ 'sunken') {Tk::break}

	my $current_mark = ${$mine_btns[$y][$x]} -> cget(-text);

	if ((! $current_mark) && $marks)
		{${$mine_btns[$y][$x]} -> configure(-text => 'Q',
											-foreground => 'orange',
											);}
	elsif ((! $current_mark) && !$marks)
		{${$mine_btns[$y][$x]} -> configure(-text => 'F',
											-foreground => 'purple',
											);
		--$flags;}
	elsif ($current_mark =~ m/Q/)
		{${$mine_btns[$y][$x]} -> configure(-text => 'F',
											-foreground => 'purple',
											);
		--$flags;}
	else {${$mine_btns[$y][$x]} -> configure(-text => '');
		++$flags;}

	return;
}

#################################################
#												#
# gets the data for custom size game		  	#
#												#
#################################################

sub get_custom_info{

	$window = MainWindow->new(-background => 'grey85',);
	$window -> resizable (0,0);
	$height_frame = $window -> Frame(-background => 'grey85',) -> pack (-pady => '10', -padx => '5');
	$height_label = $height_frame -> Label (-text => "Height  ",
											-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
											-background => 'grey85',
											);
	$height_label -> pack (-side => 'left');
	$height_entry = $height_frame -> Entry (-textvariable => \$current{height},
											-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
											);
	$height_entry -> pack (-side => 'right');

	$width_frame = $window -> Frame(-background => 'grey85',);
	$width_frame -> pack (-pady => '5', -padx => '5');
	$width_label = $width_frame -> Label (-text => "Width   ",
											-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
											-background => 'grey85',
											);
	$width_label -> pack (-side => 'left');
	$width_entry = $width_frame -> Entry (-textvariable => \$current{width},
											-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
											);
	$width_entry -> pack (-side => 'right');

	$mines_frame = $window -> Frame(-background => 'grey85',);
	$mines_frame -> pack (-pady => '5', -padx => '5');
	$mines_label = $mines_frame -> Label (-text => "Mines   ",
											-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
											-background => 'grey85',
											);
	$mines_label -> pack (-side => 'left');
	$mines_entry = $mines_frame -> Entry (-textvariable => \$current{numofmines},
											-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
										);
	$mines_entry -> pack (-side => 'right');

	$btn_frame = $window -> Frame(-background => 'grey85',);
	$btn_frame -> pack (-pady => '5');
	$ok_btn = $btn_frame -> Button(
		-text => 'OK',
		-font => '-adobe-courier-bold-r-normal-*-*-180-*-*-m-*-koi8-1',
		-background => "gray$raised_color",
		-command => [$window => 'destroy'],
		);

	$ok_btn -> pack(
		-side => 'bottom',
		-anchor => 's',
		);

	$window->waitWindow();
	return;
}

#################################################
#												#
# min returns the minimum value of the values 	#
# passed to it.									#
#												#
#################################################

sub min{
	my $min = shift @_;

	for my $temp (@_){
		$min = $temp if $min > $temp;
	}
	return $min;
}

#################################################
#												#
# creates the miesweeper.ini file			  	#
#												#
#################################################

sub create_ini_file{

	print "Creating $ini_file - DO NOT ERASE!!!\n";
	open (INI,">$ini_file") || die "Can not create $ini_file\n";
	print INI "DO NOT ERASE!!!\n";
	print INI "0 1\n";					# default = no marks, yes colors
	print INI "Beginner 8 8 10\n";		# current
	print INI "999 Anonymous\n";		# beginner
	print INI "999 Anonymous\n";		# intermediate
	print INI "999 Anonymous\n";		# expert
	close (INI);
	return;
}

#################################################
#												#
# end the game if mine has been hit			  	#
#												#
#################################################

sub hit_a_mine{
	my $x_hit = shift; 			# X coordination
	my $y_hit = shift; 			# Y coordination

	alarm(0);
	for my $y (0..($current{height}-1)){
		for my $x (0..($current{width}-1)){
			${$mine_btns[$y][$x]} -> bind ("<ButtonRelease-1>",'');
			${$mine_btns[$y][$x]} -> bind ("<ButtonRelease-2>",'');
			${$mine_btns[$y][$x]} -> bind ("<ButtonRelease-3>",'');

			# unmarked mines
			if (($field[$y][$x]) && ((${$mine_btns[$y][$x]} -> cget(-text)) !~ /F|X/)){
				${$mine_btns[$y][$x]} -> configure (-text => 'M',
										-width => '0',
										-foreground => 'red',
										);
				next;
			}

			# mistaken flags
			if (((${$mine_btns[$y][$x]} -> cget(-text)) =~ 'F') && (! $field[$y][$x])){ #((${$mine_btns[$y][$x]} -> cget(-background)) !~ 'red') && 
				${$mine_btns[$y][$x]} -> configure (-relief => 'sunken',
													-background => "red",
													-foreground => 'ivory1',
													-text => 'F',
													);
				next;
				++$flags;
			}

			# correct flags
			if ((${$mine_btns[$y][$x]} -> cget(-text)) =~ 'F'){
				${$mine_btns[$y][$x]} -> configure (-foreground => 'ivory1',
													);
				next;
			}										
		}
	}

	# the mine that was hit
	
	if ($y_hit < $current{height}){
		${$mine_btns[$y_hit][$x_hit]} -> configure (-text => 'X',
												-width => '0',
												-foreground => 'yellow',
												-relief => 'sunken',
												-background => "red",
												);
	}

	open (INI,"<$ini_file") || ((\&create_ini_file) && (open (INI,"<$ini_file"))); 
	$line=<INI>;		# DO NOT ERASE
	$line=<INI>;
	$line=<INI>;
	chomp ($line=<INI>); ($Beginner{score}, $Beginner{name}) = split / /, $line;
	chomp ($line=<INI>); ($Intermediate{score}, $Intermediate{name}) = split / /, $line;
	chomp ($line=<INI>); ($Expert{score}, $Expert{name}) = split / /, $line;
	close(INI);
	\&write_ini (\$Beginner, \$Intermediate, \Expert);
	return;
}	

#################################################
#												#
# end the game if mine has been hit			  	#
#												#
#################################################

sub game_won{

	alarm(0);

	for my $y (0..($current{height}-1)){
		for my $x (0..($current{width}-1)){
			${$mine_btns[$y][$x]} -> bind ("<ButtonRelease-1>",'');
			${$mine_btns[$y][$x]} -> bind ("<ButtonRelease-2>",'');
			${$mine_btns[$y][$x]} -> bind ("<ButtonRelease-3>",'');
			if ($field[$y][$x] =~ "m"){
				${$mine_btns[$y][$x]} -> configure (-text => 'F',
													-width => '0',
													-foreground => 'ivory1',
													);
			}
		}
	}
	if (-e "$ini_file"){
		open (INI,"<$ini_file");
		$line=<INI>;		# DO NOT ERASE
		$line=<INI>;
		$line=<INI>;
		chomp ($line=<INI>); ($Beginner{score}, $Beginner{name}) = split / /, $line;
		chomp ($line=<INI>); ($Intermediate{score}, $Intermediate{name}) = split / /, $line;
		chomp ($line=<INI>); ($Expert{score}, $Expert{name}) = split / /, $line;
		close(INI);
	}
	else{\&create_ini_file;}

	if ($current{level}{score} > $time){

		$current{level}{score} = $time;

		my $score = MainWindow->new(-background => 'grey85',);
		$score -> resizable (0,0);
		$score -> title ("New High Score");
		my $entry_frame = $score -> Frame(-background => 'grey85',) -> pack (-pady => '10', -padx => '5');
		my $entry_label = $entry_frame -> Label (-text => "Name:  ",
												-background => 'grey85',
												-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
												);
		$entry_label-> pack (-side => 'left');
		my $entry_entry = $entry_frame -> Entry (-textvariable => \$current{level}{name},
												-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
												);
		$entry_entry -> pack (-side => 'right');

		my $btn_frame = $score -> Frame(-background => 'grey85',);
		$btn_frame -> pack (-pady => '5');
		my $ok_btn = $btn_frame -> Button(
			-text => 'OK',
			-font => '-adobe-courier-bold-r-normal-*-*-180-*-*-m-*-koi8-1',
			-background => 'grey85',
			-command => [$score => 'Tk::destroy'],
			);

		$ok_btn -> pack(
			-side => 'bottom',
			-anchor => 's',
			);
		$score->waitWindow();
	}
	\&write_ini (\$Beginner, \$Intermediate, \Expert);
	return;
}

#################################################
#												#
# creates the about window					  	#
#												#
#################################################

sub about{

	my $about_win = MainWindow->new(-background => 'grey85',);
	$about_win -> title("About");
	$about_win -> resizable (0,0);
	my $actual_data = $about_win -> Label(
		-font => '-adobe-courier-bold-r-normal-*-*-180-*-*-m-*-koi8-1',
		-foreground => 'black',
		-background => 'grey85',
		-highlightcolor => 'white',
		-text => "Minesweeper\n\n".
					"Version: $VERSION\n\n".
					"Written by Dov Levenglick\n".
					"as a self exercise in Perl Tk.\n",
		-anchor => 'nw',
		-justify => 'left',
		);
	$actual_data -> pack(
		-pady => '20',
		-padx => '10',
		-side =>'top',
		-fill => 'both',
		);
	my $ok_btn = $about_win -> Button(
		-text => 'OK',
		-command => [$about_win => 'destroy'],
		-background => 'grey85',
		-font => '-adobe-courier-bold-r-normal-*-*-180-*-*-m-*-koi8-1',
		);

	$ok_btn -> pack(
		-side => 'bottom',
		-anchor => 's',
		);
	$about_win->waitWindow();
	return;
}

#################################################
#												#
# creates the help window					  	#
#												#
#################################################

sub help{

	
	$ENV{MANPATH} .= ":$man_path" unless ($ENV{MANPATH} !~ $man_path);

	if ((-e "$man_path"."$man_page") && (-e "$man_viewer")){
		system("$man_viewer -manPage minesweeper");}
	else{
		my $help_win = MainWindow->new(-background => 'grey85',);
		$help_win -> title("Help");
		$help_win -> resizable(0, 0);
		my $actual_data = $help_win -> Scrolled(
			'Text',
			-background => 'grey85',
		    -scrollbars => 'oe',
	        -width      => '80',
	        -height     => '40',
	        -wrap       => 'word',
			);
		$actual_data -> pack(
			-pady => '20',
			-padx => '10',
			-side =>'top',
			-fill => 'both',
			);
		
		$man_page = `pod2text "$0"`;
		$actual_data ->insert("end",$man_page);
				
		my $ok_btn = $help_win -> Button(
			-text => 'OK',
			-command => [$help_win => 'destroy'],
			-background => 'grey85',
			-font => '-adobe-courier-bold-r-normal-*-*-180-*-*-m-*-koi8-1',
			);
		$ok_btn -> pack(
			-side => 'bottom',
			-anchor => 's',
			);
		$help_win->waitWindow();
	}	
	return;
}

#################################################
#												#
# creates the credits window				  	#
#												#
#################################################

sub credits{

	my $credits_win = MainWindow->new(-background => 'grey85',);
	$credits_win -> title("About");
	$credits_win -> resizable (0,0);
	my $actual_data = $credits_win -> Label(
		-font => '-adobe-courier-bold-r-normal-*-*-180-*-*-m-*-koi8-1',
		-foreground => 'black',
		-background => 'grey85',
		-highlightcolor => 'white',
		-text => "Thank you:\n\n".
					"Ran Fisher, for hours of help, many ideas.\nand for some 'stolen' code\n".
					"Anton Rapp, for helping with the timer mechanism.\n".
					"Hagit Ofer-Levenglick (my wife), for putting up with me\n",
		-anchor => 'nw',
		-justify => 'left',
		);
	$actual_data -> pack(
		-pady => '20',
		-padx => '10',
		-side =>'top',
		-fill => 'both',
		);
	my $ok_btn = $credits_win -> Button(
		-text => 'OK',
		-command => [$credits_win => 'destroy'],
		-background => 'grey85',
		-font => '-adobe-courier-bold-r-normal-*-*-180-*-*-m-*-koi8-1',
		);

	$ok_btn -> pack(
		-side => 'bottom',
		-anchor => 's',
		);
	$credits_win->waitWindow();
	return;
}

#################################################
#												#
# Display best times						  	#
#												#
#################################################

sub best_times{

	my $rusure;

	unless (-e "$ini_file"){create_ini_file;}
	open (INI,"<$ini_file") || die "Can not open $ini_file for reading!\n";
	$line=<INI>;		# DO NOT ERASE
	$line=<INI>;
	$line=<INI>;
	chomp ($line=<INI>); ($Beginner{score}, $Beginner{name}) = split / /, $line;
	chomp ($line=<INI>); ($Intermediate{score}, $Intermediate{name}) = split / /, $line;
	chomp ($line=<INI>); ($Expert{score}, $Expert{name}) = split / /, $line;
	close(INI);

	my $scores = MainWindow->new(-background => 'grey85',);
	$scores -> title("Best Times");
	$scores -> resizable (0,0);

	my $Beginner_frame = $scores -> Frame(-background => 'grey85',);
	$Beginner_frame -> pack(-side => 'top',
		-fill => 'both');
	my $Beginner_name = $Beginner_frame -> Label(
		-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
		-foreground => 'black',
		-background => 'grey85',
		-highlightcolor => 'white',
		-textvariable => \$Beginner{name},
		-anchor => 'nw',
		-justify => 'left',
		);
	$Beginner_name -> pack(
		-padx => '20',
		-side =>'left',
		);
	my $Beginner_score = $Beginner_frame -> Label(
		-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
		-foreground => 'black',
		-background => 'grey85',
		-highlightcolor => 'white',
		-textvariable => \$Beginner{score},
		-anchor => 'nw',
		-justify => 'left',
		);
	$Beginner_score -> pack(
		-padx => '20',
		-side =>'right',
		-before => $Beginner_name,
		);

	my $Intermediate_frame = $scores -> Frame(-background => 'grey85',);
	$Intermediate_frame -> pack(-side => 'top',
		-fill => 'both');
	my $Intermediate_name = $Intermediate_frame -> Label(
		-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
		-foreground => 'black',
		-background => 'grey85',
		-highlightcolor => 'white',
		-textvariable => \$Intermediate{name},
		-anchor => 'nw',
		-justify => 'left',
		);
	$Intermediate_name -> pack(
		-padx => '20',
		-side =>'left',
		);
	my $Intermediate_score = $Intermediate_frame -> Label(
		-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
		-foreground => 'black',
		-background => 'grey85',
		-highlightcolor => 'white',
		-textvariable => \$Intermediate{score},
		-anchor => 'nw',
		-justify => 'left',
		);
	$Intermediate_score -> pack(
		-padx => '20',
		-side =>'right',
		-before => $Intermediate_name,
		);

	my $Expert_frame = $scores -> Frame(-background => 'grey85',);
	$Expert_frame -> pack(-side => 'top',
		-fill => 'both');
	my $Expert_name = $Expert_frame -> Label(
		-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
		-foreground => 'black',
		-background => 'grey85',
		-highlightcolor => 'white',
		-textvariable => \$Expert{name},
		-anchor => 'nw',
		-justify => 'left',
		);
	$Expert_name -> pack(
		-padx => '20',
		-side =>'left',
		);
	my $Expert_score = $Expert_frame -> Label(
		-font => '-adobe-courier-bold-r-normal-*-*-140-*-*-m-*-koi8-1',
		-foreground => 'black',
		-background => 'grey85',
		-highlightcolor => 'white',
		-textvariable => \$Expert{score},
		-anchor => 'nw',
		-justify => 'left',
		);
	$Expert_score -> pack(
		-padx => '20',
		-side =>'right',
		-before => $Expert_name,
		);

	my $ok_btn = $scores-> Button(
		-text => 'OK',
		-command => [$scores => 'destroy'],
		-background => 'grey85',
		-font => '-adobe-courier-bold-r-normal-*-*-180-*-*-m-*-koi8-1',
		);

	$ok_btn -> pack(
		-side => 'left',
		-anchor => 'sw',
		);

	my $reset_btn = $scores-> Button(
		-text => 'Reset',
		-command => [sub{
						\&OkCanc($scores, "Are You Sure??", \$rusure);
						if ($rusure =~ 'Ok'){
							$Beginner{name} = $Intermediate{name} = $Expert{name} = "Anonymous";
							$Beginner{score} = $Intermediate{score} = $Expert{score} = 999;
							\&write_ini(\$Beginner, \$Intermediate, \Expert)
						}
					}],	
		-font => '-adobe-courier-bold-r-normal-*-*-180-*-*-m-*-koi8-1',
		-background => 'grey85',
		);

	$reset_btn -> pack(
		-side => 'right',
		-anchor => 'se',
	);

$scores->waitWindow();
	return;

}

#################################################
#												#
# write an updated INI file					  	#
#												#
#################################################
sub write_ini{

	my $Beginner = shift;		# the best score and scorers name for this level
	my $Intermediate = shift;	# the best score and scorers name for this level
	my $Expert = shift;			# the best score and scorers name for this level

	open (INI,">$ini_file") ||  return;
	print INI "DO NOT ERASE!!!\n";
	print INI "$marks $colors\n";
	print INI "$current{level} $current{width} $current{height} $current{numofmines}\n";
	print INI "$Beginner{score} $Beginner{name}\n";
	print INI "$Intermediate{score} $Intermediate{name}\n";
	print INI "$Expert{score} $Expert{name}\n";
	close (INI);

	return;
}

#################################################
#												#
# Display "R U sure" message				  	#
#												#
#################################################
sub OkCanc
{
  my $win = shift;
  my $message = shift;
  my $answer_p = shift;
  my $yesno = $win -> Dialog (
                    -text => "$message",
                    -background => 'gray85',
                    -buttons => ["Ok","Cancel"]);
  $$answer_p = $yesno -> Show;
  $yesno -> destroy();
}

#################################################
#												#
# change the value of %cell_colors			  	#
#												#
#################################################
sub set_cell_colors {

	if ($colors){
		%cell_colors = ('1' => "#0000ff",
						'2' => "#ff0000",
						'3' => "#00052a",
						'4' => "#0f0f0f",
						'5' => "#000000",
						'6' => "#efefe0",
						'7' => "#ffd700",
						'8' => "#ff34b3",
						' ' => "#000000");
	}
	else{
		%cell_colors = ('1' => "#0000ff",
						'2' => "#0000ff",
						'3' => "#0000ff",
						'4' => "#0000ff",
						'5' => "#0000ff",
						'6' => "#0000ff",
						'7' => "#0000ff",
						'8' => "#0000ff",
						' ' => "#0000ff",);
	}
}	

#####################################################################################
#							POD														#	
#####################################################################################

=head1 NAME

minesweeper.pl - The Perl Based Minesweeper for UNIX

=head1 SYNOPSYS

/users/dovl/local/bin/minesweeper.pl

=head1 VERSION

2.00

=head1 DESCRIPTION

The object of the game is to discover all of the mines.
An opened cell shows the number of mines in the 8 cells surounding it.
Winning the game is done by opening all cells that don't contain a mine.
To open a cell, click it with your number-1 button on the mouse,
generaly the left button.
To mark a cell as a mine, click on it with your nuber-3 mouse button,
generaly the right button. This enables you to either mark a cell as
definetly containing a mine: 'F'(flag), or as possibly having a mine:
'Q' (question) if you have the 'Marks' option (off by default) turned on.
Notice that while cells marked with 'F' can't be opened with the number-1
mouse button, cells marked with 'Q' may be.
To open cells surounding an opened cell, click on it with your number-2
mouse button, generaly the middle button. This is only possible when
you have flaged the amount of cells surounding the desired cell with as
many flags as specified in that cell.
When the game ends, either by winning or losing, all flags ('F') will be 
repainted in ivory.
If you lose (G-D forbid), the mine that you blew up will be marked
with a yellow 'X' in a red background. Where there were unmarked mines,
a red 'M' will appear and any mistaken flags ('F') will be rewritten as an ivory
'F' in a red background.
The Colors option is used to enable different colors for the different values
in the cells. When the option is turned on (by default), the different values
have different colors. When the option is turned off, all the values are
displayed in blue
If you give up, feel free to press the "I Give Up" button. Please notice that
pressing this button before you have opened a sigle cell is not possible. 
The scroll bar marked "BG Color" enables the user to change the color of the
mine field. Each time the scroll bar is moved a new game is started!

=head1 KNOW BUGS

The script calls Tk::destroy() every time that "New Game" is pressed.
This causes a memory leak that has been extensivally discussed in 
http://groups.google.com/groups?hl=en\&lr=&ie=UTF-8&group=comp.lang.perl.tk
Basically, the Tk module is destroying the widgets but not returning the
freed memory to the kernel. As soon as this is fixed in Tk, the problem will 
disappear. I may try and fix the game in further versions.

=head1 FILES

/users/<username>/.minesweeper.ini

=head1 AUTHOR

Dov Levenglick <Dov.Levenglick@motorola.com>

=cut
#######################################################################################





