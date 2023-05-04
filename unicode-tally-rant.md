# tally marks in unicode. A rant. 

So what I want here is vertical tally marks. One through Four. (I to IIII)
However, the unicode consortium only included tally marks for One and Five
on the stated logic that:

> The original proposal included five characters for this tally mark system,
> but this proposal reduces it to two, given that three of the characters,
> which represent the digits two through four, can be handled as sequences of
> the character that represents the digit one.
-- https://unicode.org/L2/L2016/16065-tally-marks.pdf

This is in contrast to the "COUNTING ROD UNIT DIGIT" and "COUNTING ROD TENS
DIGIT" characters from the very same "Counting Rod Numerals" block having
a single glyph for groups of TWO, THREE and FOUR, and also in contast to the
obvious (to me) logic that if a block of five is a single glyph, then so is
a block of two, three and four.  The Counting Rod Numerals block can be seen
here:  http://unicode.org/charts/PDF/U1D360.pdf

Stepping into a different part of unicode, the "ROMAN NUMERAL TWO" and
"THREE" are implemented as single characters in tally style as expected.
However ROMAN NUMERAL FOUR is a glyph of "IV" style, so as a group are not
a complete substitute for the lack of tally glyphs. 

So, back to looking at that Counting Rod Numerals block, perhaps you wonder
why I dont just use COUNTING ROD TENS DIGIT TWO through DIGIT FOUR, as they
have exactly the look I seek. And indeed they do - in that reference PDF.
However, real world usage is inconsistent. 

My ubuntu desktop displays the Counting Rod Numerals block characters in
accordance with the unicode reference. However my macOS desktop displays them
differently. The horizontals are vertical and vice versa - so to get the look
correct, I need TENS DIGIT TWO through FOUR if the terminal is linux, but
UNIT DIGIT TWO through FOUR if the terminal is macOS. Specific fonts and
macOS and ubuntu versions aren't detailed here as I'm not trying to be
comprehensive about where the inconsistencies are. I note that the UNIT DIGIT
FIVE through NINE and TENS DIGIT FIVE through NINE have similar
vertical/horizontal swaps, resulting in different topological shapes in some
cases!

Wikipedia has a reference page with both an images of each glyph, and the
local font rendering of the same:
https://en.wiktionary.org/wiki/Appendix:Unicode/Counting_Rod_Numerals

Finally, over on omniglot, https://omniglot.com/chinese/numerals.htm the "Rod
numerals (筹 [籌] chóu)" section matches the macOS implementation, but is
clearly the closest match to the counting rods implemented in unicode, with
the alternates on that page being Shang, Suzhou, Modern Chinese Simple and
Modern Chinese Complex - all of which have obviously different logical
structure after the first three or four. 


# Solution? 

I think it's obvious that the COUNTING ROD NUMERALS unicode block simply needs
to add TALLY MARK TWO, TALLY MARK THREE and TALLY MARK FOUR. 


# Tangent note

Tangent note is related, but outside the scope of this specific rant/solution:
there are other tally mark systems in use around the world (as per mention on
https://en.wikipedia.org/wiki/Tally_marks ) that do not appear to have explicit
representation as of Unicode 15.0. It's likely that their look may be
reproducable with other box drawing characters and similar glyphs. 
