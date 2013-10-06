# String::format

String::format is a JavaScript utility which adds a `.format()` method to
strings. It implements Python's [format string syntax][1] -- including the
[format specification mini-language][2] -- while acknowledging differences
between the two languages.

This remainder of this document is largely derived from then aforementioned
Python documentation.

### str.format(values...)

Perform a string formatting operation. The format string on which this method
is called can contain literal text and/or replacement fields. The return value
is the result of replacing each replacement field with the string value of the
corresponding argument.

```javascript
"The sum of 1 and 2 is {0}".format(1 + 2)
// => "The sum of 1 and 2 is 3"
```

Format strings contain “replacement fields” surrounded by curly braces:
`{` and `}`. Anything that is not contained in braces is considered literal
text, which is copied unchanged to the output. To include a brace character
in literal text, use `{{` or `}}`.

The grammar for a replacement field is as follows:

```ebnf
replacement field = "{" , [field name] , ["!" , transformer name] , [":" , format spec] , "}" ;
field name        = property name , { "." , property name } ;
property name     = ? a character other than ".", "!" or ":" ? ;
transformer name  = ? a character other than ":" ? ;
format spec       = ? described in the next section ? ;
```

In less formal terms, the replacement field can start with a __field_name__
that specifies the object whose value is to be formatted and inserted into
the output instead of the replacement field. The __field_name__ is optionally
followed by a __transformer_name__ field, which is preceded by an exclamation
point `!`, and a __format_spec__, which is preceded by a colon `:`. These
specify a non-default format for the replacement value.

See also the [Format specification mini-language][XXX1] section.

The __field_name__ begins with a number corresponding to a positional
argument. If a format string's field\_names begin 0, 1, 2, ... in sequence,
they can all be omitted (not just some) and the numbers 0, 1, 2, ... will be
automatically inserted in that order. The __field_name__ can also contain any
number of property expressions: a dot `.` followed by a __property_name__.

Some simple format string examples:

```javascript
"First, thou shalt count to {0}" // References first positional argument
"Bring me a {}"                  // Implicitly references the first positional argument
"From {} to {}"                  // Same as "From {0} to {1}"
"Weight in tons: {0.weight}"     // 'weight' property of first positional arg
"My quest is {name}"             // 'name' property of first positional arg
"Units destroyed: {players.0}"   // '0' property of 'players' property of first positional arg
```

The __transformer_name__ field ... TODO

The __format_spec__ field contains a specification of how the value should be
presented: field width, alignment, padding, decimal precision, and so on.

A __format_spec__ field can also include nested replacement fields within it.
These nested replacement fields can contain only a field name; transformers
and format specifications are not allowed. The replacement fields within the
format\_spec are substituted before the __format_spec__ string is interpreted.
This allows the formatting of a value to be dynamically specified.

See the [Format examples][XXX2] section for some examples.

### Format specification mini-language

“Format specifications” are used within replacement fields contained within a
format string to define how individual values are presented. They can also be
passed to the `format()` function this module exports when “required”.

Some of the formatting options are only supported on numbers.

A general convention is that an empty format string (`""`) produces the same
result as if you had called `.toString()` on the value. A non-empty format
string typically modifies the result.

The general form of a _standard format specifier_ is:

```ebnf
format spec = [[fill] , align] , [sign] , ["#"] , ["0"] , [width] , [","] , ["." , precision] , [type] ;
fill        = ? a character other than "{" or "}" ? ;
align       = "<" | ">" | "=" | "^" ;
sign        = "+" | "-" | " " ;
width       = digit , { digit } ;
precision   = digit , { digit } ;
type        = "b" | "c" | "d" | "e" | "E" | "f" | "g" | "G" | "o" | "s" | "x" | "X" | "%" ;
digit       = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" ;
```

If a valid __align__ value is specified, it can be preceded by a __fill__
character that can be any character and defaults to a space if omitted.

The meaning of the various alignment options is as follows:

    Option  Meaning
    --------------------------------------------------------------------
    '<'     Forces the field to be left-aligned within the available
            space (this is the default for most types).
    --------------------------------------------------------------------
    '>'     Forces the field to be right-aligned within the available
            space (this is the default for numbers).
    --------------------------------------------------------------------
    '='     Forces the padding to be placed after the sign (if any) but
            before the digits. This is useful for printing fields in the
            form ‘+000000120’. This alignment option is only valid for
            numbers.
    --------------------------------------------------------------------
    '^'     Forces the field to be centered within the available space.

Note that unless a minimum field width is defined, the field width will always
be the same size as the data to fill it, so that the alignment option has no
meaning in this case.

The __sign__ option is only valid for numbers, and can be one of the
following:

    Option  Meaning
    --------------------------------------------------------------------
    '+'     Indicates that a sign should be used for both positive as
            well as negative numbers.
    --------------------------------------------------------------------
    '-'     Indicates that a sign should be used only for negative
            numbers (this is the default behavior).
    --------------------------------------------------------------------
    ' '     Indicates that a leading space should be used on positive
            numbers, and a minus sign on negative numbers.

The `'#'` option causes the “alternate form” to be used for the conversion.
The alternate form is defined differently for different types. This option is
only valid for numbers. For integer values, when binary, octal, or
hexadecimal output is used, this option adds the prefix respective `'0b'`,
`'0o'`, or `'0x'` to the output value. For non-integer values, the alternate
form causes the result of the conversion to always contain a decimal-point
character, even if no digits follow it. Normally, a decimal-point character
appears in the result of these conversions only if a digit follows it. In
addition, for `'g'` and `'G'` conversions, trailing zeros are not removed from
the result.

The `','` option signals the use of a comma for a thousands separator.

__width__ is a decimal integer defining the minimum field width. If not
specified, then the field width will be determined by the content.

Preceding the __width__ field by a zero (`'0'`) character enables sign-aware
zero-padding for numbers. This is equivalent to a __fill__ character of `'0'`
with an __alignment__ type of `'='`.

The __precision__ is a decimal number indicating how many digits should be
displayed after the decimal point for a number formatted with `'f'`, or before
and after the decimal point for a number formatted with `'g'` or `'G'`. For
strings the field indicates the maximum field size -- in other words, how many
characters will be used from the field content.

Finally, the __type__ determines how the data should be presented.

The available string presentation types are:

    Type    Meaning
    --------------------------------------------------------------------
    's'     String format. This is the default type for strings and may
            be omitted.
    --------------------------------------------------------------------
    None    The same as 's'.

The available integer presentation types are:

    Type    Meaning
    --------------------------------------------------------------------
    'c'     Character. Converts the integer to the corresponding unicode
            character before printing.
    --------------------------------------------------------------------
    'd'     Decimal integer. Outputs the number in base 10.
    --------------------------------------------------------------------
    'b'     Binary format. Outputs the number in base 2.
    --------------------------------------------------------------------
    'o'     Octal format. Outputs the number in base 8.
    --------------------------------------------------------------------
    'x'     Hex format. Outputs the number in base 16, using lower-case
            letters for the digits above 9.
    --------------------------------------------------------------------
    'X'     Hex format. Outputs the number in base 16, using upper-case
            letters for the digits above 9.

In addition to the above presentation types, non-integer numbers can be
formatted with the floating point presentation types listed below.

The available presentation types for floating point and decimal values are:

    Type    Meaning
    --------------------------------------------------------------------
    'e'     Exponential notation. Prints the number in scientific
            notation using the letter ‘e’ to indicate the exponent.
            The default precision is 6.
    --------------------------------------------------------------------
    'E'     Exponential notation. Same as 'e' except it uses an
            upper-case ‘E’ as the separator character.
    --------------------------------------------------------------------
    'f'     Fixed point. Displays the number as a fixed-point number.
            The default precision is 6.
    --------------------------------------------------------------------
    'g'     General format. For a given precision p >= 1, this rounds
            the number of significant digits and then formats the result
            in either fixed-point format or in scientific notation,
            depending on its magnitude.

            The precise rules are as follows: suppose that the result
            formatted with presentation type 'e' and precision p-1 would
            have exponent exp. Then if -4 <= exp < p, the number is
            formatted with precision type 'f' and precision p-1-exp.
            Otherwise, the number is formatted with presentation type
            'e' and precision p-1. In both cases insignificant trailing
            zeros are removed from the significand, and the decimal
            point is also removed if there are no remaining digits
            following it.

            A precision of 0 is treated as equivalent to a precision
            of 1. The default precision is 6.

            This is the default type for numbers and may be omitted.
    --------------------------------------------------------------------
    'G'     Same as 'g' except switches to 'E' if the number gets too
            large.
    --------------------------------------------------------------------
    None    If precision is specified, same as 'g'. Otherwise, same as
            .toString(), except the other format modifiers can be used.

### Format examples

Accessing arguments by position:

```javascript
> "{0}, {1}, {2}".format("a", "b", "c")
"a, b, c"
> "{}, {}, {}".format("a", "b", "c")    // arguments' indices can be omitted
"a, b, c"
> "{2}, {1}, {0}".format("a", "b", "c")
"c, b, a"
> "{0}{1}{0}".format("abra", "cad")     // arguments' indices can be repeated
"abracadabra"
```

TODO: Discuss accessing arguments by name (via implicit "0.")

Accessing arguments' items:

```javascript
> var coord = [3, 5]
undefined
> "X: {0.0};  Y: {0.1}".format(coord)
"X: 3;  Y: 5"
```

Aligning the text and specifying a width:

```javascript
> "{:<30}".format("left aligned")
"left aligned                  "
> "{:>30}".format("right aligned")
"                 right aligned"
> "{:^30}".format("centered")
"           centered           "
> "{:*^30}".format("centered")  // use "*" as a fill char
"***********centered***********"
```

Specifying a sign:

```javascript
> "{:+f}; {:+f}".format(3.14, -3.14)  // show it always
"+3.140000; -3.140000"
> "{: f}; {: f}".format(3.14, -3.14)  // show a space for positive numbers
" 3.140000; -3.140000"
> "{:-f}; {:-f}".format(3.14, -3.14)  // show only the minus -- same as "{:f}; {:f}"
"3.140000; -3.140000"
```

Converting the value to different bases:

```javascript
> "int: {0:d};  hex: {0:x};  oct: {0:o};  bin: {0:b}".format(42)
"int: 42;  hex: 2a;  oct: 52;  bin: 101010"
> "int: {0:d};  hex: {0:#x};  oct: {0:#o};  bin: {0:#b}".format(42)
"int: 42;  hex: 0x2a;  oct: 0o52;  bin: 0b101010"
```

Using the comma as thousands separator:

```javascript
> "{:,}".format(1234567890)
"1,234,567,890"
```

Expressing a percentage:

```javascript
> var points = 19, total = 22
undefined
> "Correct answers: {:.2%}".format(points / total)
"Correct answers: 86.36%"
```

---

### string.format(values...)

A KeyError is thrown if there are unmatched placeholders:

```coffeescript
"{0} {1} {2}".format("x", "y")
# KeyError: "2"
```

A format string must not contain both implicit and explicit references:

```coffeescript
"My name is {} {}. Do you like the name {0}?".format("Lemony", "Snicket")
# ValueError: cannot switch from implicit to explicit numbering
```

Dot notation may be used to reference object properties:

```coffeescript
bobby = first_name: "Bobby", last_name: "Fischer"
garry = first_name: "Garry", last_name: "Kasparov"

"{0.first_name} {0.last_name} vs. {1.first_name} {1.last_name}".format(bobby, garry)
# "Bobby Fischer vs. Garry Kasparov"
```

When referencing the first positional argument, `0.` may be omitted:

```coffeescript
repo = owner: "pypy", slug: "pypy", followers: [...]

"{owner}/{slug} has {followers.length} followers".format(repo)
# "pypy/pypy has 516 followers"
```

If the referenced property is a method, it is invoked and the result is used
as the replacement string:

```coffeescript
me = name: "David", dob: new Date "26 Apr 1984"

"{name} was born in {dob.getFullYear}".format(me)
# "David was born in 1984"

sheldon = quip: -> "Bazinga!"

"I've always wanted to go to a goth club. {quip.toUpperCase}".format(sheldon)
# "I've always wanted to go to a goth club. BAZINGA!"
```

### String.prototype.format.transformers

“Transformers” can be attached to `String.prototype.format.transformers`:

```javascript
String.prototype.format.transformers.upper = function(str) {
  return str.toUpperCase();
};

"Batman's preferred onomatopoeia: {0!upper}".format("pow!")
// => "Batman's preferred onomatopoeia: POW!"
```

A transformer could sanitize untrusted input:

```javascript
String.prototype.format.transformers.escape = function(str) {
  return str.replace(/[&<>"'`]/g, function(chr) {
    return "&#" + chr.charCodeAt(0) + ";";
  });
};

"<p class=status>{!escape}</p>".format("I <3 EICH")
// => "<p class=status>I &#60;3 EICH</p>"
```

Or pluralize nouns, perhaps:

```javascript
String.prototype.format.transformers.s = function(num) {
  return num === 1 ? "" : "s";
};

"{0}, you have {1} unread message{1!s}".format("Holly", 2)
// => "Holly, you have 2 unread messages"

"{0}, you have {1} unread message{1!s}".format("Steve", 1)
// => "Steve, you have 1 unread message"
```

String::format does not currently define any transformers.

### format(template, values...)

The module provides a format function when "required":

```javascript
var format = require("string-format");

format("The name's {1}. {0} {1}.", "James", "Bond")
// => "The name's Bond. James Bond."
```

`format(str, x, y, z)` is equivalent to `str.format(x, y, z)`.

### Creating reusable template functions

If a format string is used in multiple places, one could assign it to
a variable to avoid repetition. The idiomatic alternative is to create
a reusable template function via [`Function::bind`][3]:

```javascript
> var greet = String.prototype.format.bind("{0}, you have {1} unread message{1!s}")
undefined
> greet("Holly", 2)
"Holly, you have 2 unread messages"
> greet("Steve", 1)
"Steve, you have 1 unread message"
```

### Running the test suite

    make setup
    make test


[XXX1]: #format-specification-mini-language
[XXX2]: #format-examples
[1]: http://docs.python.org/3/library/string.html#formatstrings
[2]: http://docs.python.org/3/library/string.html#formatspec
[3]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function/bind
