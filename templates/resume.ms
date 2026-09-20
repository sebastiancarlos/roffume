.\" resume.ms template — document chrome for the resume pipeline.
.\" Variables come from YAML front matter (name, title, location, email,
.\" phone, github, linkedin, margin-top/left/right/bottom).
\# Import TMAC template
.so resume.tmac
\# Setup Helvetica font
.fam H
.
\# Margin. Create a right margin of 0.5i by subtracting the left margin
\# plus 0.5i from the width of the entire page.
.nr PO $if(margin-left)$$margin-left$$else$0.5i$endif$
.nr HM $if(margin-top)$$margin-top$$else$0.6i$endif$
.nr FM $if(margin-bottom)$$margin-bottom$$else$0.1i$endif$
$if(show_photo)$$if(photo)$
.nr HM \n[HM]-0.3i
$endif$$endif$
.nr LL 21c
.nr LL -\n[PO]
.nr LL -$if(margin-right)$$margin-right$$else$0.5i$endif$
.nr LT \n[LL]
.
\# Main document starts here
$if(show_photo)$$if(photo)$
.photo "$photo$"
$endif$$endif$.title $name$
.subtitle $title$
.sp -4
.DS R
.nf
$location$
$email$
$phone$
$if(github)$
github.com/$github$
$else$
\&
$endif$
$if(linkedin)$
linkedin.com/in/$linkedin$
$else$
\&
$endif$
.DE
.
\# change to left align mode
.ps 11
.vs 12
$if(show_photo)$$if(photo)$
\v'0.2i'
$endif$$endif$$body$
