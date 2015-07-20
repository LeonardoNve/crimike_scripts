# File management

:e              reload file
:q              quit
:q!             quit without saving changes
:w              write file
:w {file}       write new file
:x              write file and exit

# Movement

    k
  h   l         basic motion
    j

# Preceding a motion or edition with a number repeats it n times
# Examples:
50k         moves 50 lines up
2dw         deletes 2 words
5yy         copies 5 lines
42G         go to line 42

w               next start of word
W               next start of whitespace-delimited word
e               next end of word
E               next end of whitespace-delimited word
b               previous start of word
B               previous start of whitespace-delimited word
0               start of line
$               end of line
gg              go to first line in file
G               go to end of file
^               first non-blank character in line
zz              move line to middle
zt              move line to top
zb              move line to bottom
^e              move up without moving cursor
^y              move down without moving cursor


# Insertion
#   To exit from insert mode use Esc or Ctrl-C
#   Enter insertion mode and:

a               append after the cursor
A               append at the end of the line
i               insert before the cursor
I               insert at the beginning of the line
o               create a new line under the cursor
O               create a new line above the cursor
R               enter insert mode but replace instead of inserting chars
:r {file}       insert from file
:23r infile     insert file under 23rd line

# Editing

u               undo
yy              yank (copy) a line
y{motion}       yank text that {motion} moves over
p               paste after cursor
P               paste before cursor
<Del> or x      delete a character
dd              delete a line
d{motion}       delete text that {motion} moves over
"ad             cut to a register
"ay             copy to a register (yank)
"ap             paste from a register
"Ad             cut and append to a register
^t              indent forward in insert mode
^d              indent backwards in insert mode
>5>             indent forwards 5 lines
<5<             indent backwards 5 lines


#Search and replace

*                search for word under cursor
/jo[ha]n         search for john or joan
%s/old/new/g     replace everywhere
%s/old/new/gw    replace with confirmation
%s/old/new/gi    case insensitive replace
2,35s/old/new/g  replace between lines 2 and 35
g/string/d       delete lines containing strings
s/old/new/g      replace every occurrence in current line

#Tabs
:tabnew file     open file in new tab
gt               next tab
^w, T            split to tab


#shortcuts
:ab x  xxxxx     define abbreviation x as xxxxx
m{a-z}           marks line with letter
'{a-z}           go to marked line by the letter
:map             sequence of keys to execute another sequence of keys, works in normal, visual, select and operator modes
:map!            same as above, works in insert and commandline mode
:nmap            normal mode maps
:imap            insert mode maps
:vmap            visual and select mode maps
:smap            select mode maps
:xmap            visual mode maps
:cmap            commandline mode maps
:omap            operator pending mode maps

:map <F2> :echo 'Current time'              Prints current time when pressing F2 




#Other

^a                  increment number
^x                  decrement number
!!                  execute command and insert output to file
:1,10 w outfile     save lines 1,10 to file
:1,10 w>> outfile   append
:w !sudo tee %      save current file to itself - used when opened without write privileges
