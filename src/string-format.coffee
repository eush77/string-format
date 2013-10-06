# ::: Helpers ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

exponent = (n, e = 0) -> switch
  when  -1 < n <  1 then exponent n * 10, e - 1
  when -10 < n < 10 then e
  else                   exponent n / 10, e + 1


pad = (string, fill, align, width) ->
  padding = Array(Math.max 0, width - string.length + 1).join(fill)
  switch align
    when '<'
      string + padding
    when '>'
      padding + string
    when '^'
      idx = Math.floor padding.length / 2
      padding.substr(0, idx) + string + padding.substr(idx)


# ::: Error Types ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

class KeyError extends Error
  constructor: (@message) ->
  name: 'KeyError'


class ValueError extends Error
  constructor: (@message) ->
  name: 'ValueError'


# ::: Tokenizers :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

consume_literal = (str, memo = '') ->
  if str.length is 0
    [memo, str]
  else if str[0] in ['{', '}'] and str[0] is str[1]
    consume_literal str.substr(2), memo + str[0]
  else if str[0] is '{'
    [memo, str]
  else if str[0] is '}'
    throw new SyntaxError 'unmatched, unescaped "}" in format string'
  else
    consume_literal str.substr(1), memo + str[0]


consume_expression = (str, memo = '', depth = 0) ->
  if depth > 1
    throw new ValueError 'max string recursion exceeded'
  else if str.length is 0 or str[0] is '}' and depth is 0
    m = /// ^ ([^!:]*) (?:!([^:]*))? (?::(.*))? $ ///.exec memo
    throw new ValueError 'invalid transformer name' if m[2] is ''
    [{field_name: m[1], transformer: m[2] ? '', format_spec: m[3] ? ''}, str]
  else
    consume_expression str.substr(1), memo + str[0], switch str[0]
      when '{' then depth + 1
      when '}' then depth - 1
      else          depth


tokenize = (chars, memo = [], type = 'literal') ->
  if chars.length is 0
    memo
  else if type is 'literal'
    [token, remainder] = consume_literal chars
    tokenize remainder, [memo..., token], 'expression'
  else if type is 'expression'
    [token, remainder] = consume_expression chars.substr(1)
    if remainder
      tokenize remainder.substr(1), [memo..., token], 'literal'
    else
      throw new SyntaxError 'unmatched, unescaped "{" in format string'


tokenize_format_spec = (format_spec) ->
  chars = format_spec.split('')
  keys = 'fill align sign # 0 width , precision type'.split(' ')
  tokens = {}
  tokens[key] = '' for key in keys
  processors = [
    ->
      # The presence of a fill character is signalled by the character
      # following it, which must be one of the alignment options. Unless
      # the second character of format_spec is a valid alignment option,
      # the fill character is assumed to be are absent.
      if chars[1] in ['<', '>', '=', '^']
        tokens['fill'] = chars.shift()
      if chars[0] in ['<', '>', '=', '^']
        tokens['align'] = chars.shift()
    ->
      if chars[0] in ['+', '-', ' ']
        tokens['sign'] = chars.shift()
    ->
      if chars[0] is '#'
        tokens['#'] = chars.shift()
    ->
      if chars[0] is '0'
        tokens['0'] = chars.shift()
    ->
      while /\d/.test chars[0]
        tokens['width'] += chars.shift()
    ->
      if chars[0] is ','
        tokens[','] = chars.shift()
    ->
      if chars[0] is '.'
        chars.shift()
        while /\d/.test chars[0]
          tokens['precision'] += chars.shift()
        unless tokens['precision']
          throw new SyntaxError 'format specifier missing precision'
    ->
      tokens['type'] = chars.shift()
  ]
  processor() for processor in processors when chars.length
  throw new SyntaxError 'unused characters in format specifier' if chars.length
  tokens.toString = -> (this[key] for key in keys).join('')
  tokens


# ::: Formatters :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

format_value = (value, tokens) ->
  switch Object(value).constructor
    when Number then format_number value, tokens
    when String then format_string value, tokens
    else
      if String tokens
        throw new ValueError 'non-empty format string for {0.2} object'
                             .format Object::toString.call(value).split(/\W/)
      String value


format_string = (value, tokens) ->
  fill = tokens['fill'] or tokens['0'] or ' '
  align = tokens['align'] or (if tokens['0'] then '=' else '<')
  precision = Number tokens['precision'] or value.length

  if tokens['type'] not in ['', 's']
    template = 'unknown format code "{type}" for String object'
    throw new ValueError template.format tokens
  if tokens[',']
    throw new ValueError 'cannot specify "," with "s"'
  if tokens['sign']
    throw new ValueError 'sign not allowed in string format specifier'
  if tokens['#']
    throw new ValueError \
      'alternate form (#) not allowed in string format specifier'
  if align is '='
    throw new ValueError '"=" alignment not allowed in string format specifier'

  pad value.substr(0, precision), fill, align, Number tokens['width']


format_number = (value, tokens) ->
  fill = tokens['fill'] or tokens['0'] or ' '
  align = tokens['align'] or (if tokens['0'] then '=' else '>')
  width = tokens['width']
  type = tokens['type']

  switch type
    when 'c', 'd', 'b', 'o', 'x', 'X'
      if value % 1 < 0 or value % 1 > 0
        template = 'cannot format non-integer with format specifier "{}"'
        throw new ValueError template.format type
      if tokens[','] and type isnt 'd'
        throw new ValueError 'cannot specify "," with "{}"'.format type
      if tokens['precision']
        throw new ValueError 'precision not allowed in integer format specifier'
    when 'e', 'E', 'f', 'g', 'G', '%'
      precision = Number tokens['precision'] or '6'
    when '' then
    else
      template = 'unknown format code "{}" for Number object'
      throw new ValueError template.format type

  switch type
    when 'c'
      if tokens['sign']
        throw new ValueError 'sign not allowed with format specifier "c"'
      s = String.fromCharCode(value)
    when 'd'
      s = Math.abs(value).toString(10)
    when 'b'
      s = Math.abs(value).toString(2)
    when 'o'
      s = Math.abs(value).toString(8)
    when 'x', 'X'
      s = Math.abs(value).toString(16)
      s = s.toUpperCase() if type is 'X'
    when 'e', 'E'
      s = Math.abs(value).toExponential(precision)
      s = s.replace(/[.]|(?=e)/, '.') if tokens['#']
      s = s.toUpperCase() if type is 'E'
    when 'f'
      s = Math.abs(value).toFixed(precision) +
          (if tokens['#'] and precision is 0 then '.' else '')
    when 'g', 'G'
      # A precision of 0 is treated as equivalent to a precision of 1.
      p = precision or 1
      if -4 <= exponent(value) < p
        factor = Math.pow 10, p - 1 - exponent Math.abs(value)
        n = Math.round(Math.abs(value) * factor) / factor
        s = String n
        if tokens['#']
          s += '.' if n % 1 is 0
          s += Array(p - s.match(/\d/g).length + 1).join('0')
      else
        s = Math.abs(value).toExponential(Math.max 0, p - 1)
        s = if tokens['#']
          s.replace(/[.]|(?=e)/, '.')
        else
          s.replace(/[.]?0+(?=e)/, '')
      s = s.toUpperCase() if type is 'G'
    when '%'
      s = Math.abs(value * 100).toFixed(precision) + '%'
    when ''
      if tokens['precision']
        tokens['type'] = 'g'
        return format_number value, tokens
      else
        s = Math.abs(value).toString(10)

  sign = if value < 0 or 1 / value < 0
    '-'
  else if tokens['sign'] is '-'
    ''
  else
    tokens['sign']

  prefix = type in 'boxX' and tokens['#'] and '0' + type or ''

  if tokens[',']
    [whole, fract] = if (idx = s.indexOf('.')) >= 0
      [s.substr(0, idx), s.substr(idx)]
    else
      [s, '']

    chars = []
    unshift = (chr) ->
      chars.unshift(',') if chars.length is 3 or chars[3] is ','
      chars.unshift(chr)
    unshift chr for chr in whole by -1

    if align isnt '='
      pad sign + chars.join('') + fract, fill, align, width
    else if fill is '0'
      min = width - sign.length - fract.length
      unshift fill until chars.length >= min
      sign + chars.join('') + fract
    else
      sign + pad chars.join('') + fract, fill, '>', width - sign.length
  else if align is '='
    sign + prefix + pad s, fill, '>', width - sign.length - prefix.length
  else
    pad sign + prefix + s, fill, align, width


# ::: Evaluator ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

get = (x, prop) ->
  if prop not of Object x
    throw new KeyError '"{}"'.format prop.replace(/"/g, '\\"')
  if typeof x[prop] is 'function' then x[prop]() else x[prop]

descend = (x, path) ->
  if path.length is 0 then x else descend get(x, path[0]), path[1..]

evaluate = (expr, ctx) ->
  val = descend ctx, expr.field_name.split('.')
  if expr.transformer is ''
    val
  else if Object::hasOwnProperty.call format.transformers, expr.transformer
    format.transformers[expr.transformer] val
  else
    throw new ValueError 'unknown transformer "{}"'
                         .format expr.transformer.replace(/"/g, '\\"')


# ::: Exports ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

format = (template, args...) ->
  normalize = do (idx = 0, modes = []) -> (field_name) ->
    if field_name
      unless (modes[modes.length] = 'explicit') is modes[0]
        throw new ValueError 'cannot switch from implicit to explicit numbering'
      if /^\d+(?:[.]|$)/.test field_name then field_name else "0.#{field_name}"
    else
      unless (modes[modes.length] = 'implicit') is modes[0]
        throw new ValueError 'cannot switch from explicit to implicit numbering'
      "#{idx++}"

  values = for token in tokenize template
    switch Object::toString.call token
      when '[object String]'
        token
      when '[object Object]'
        token.field_name = normalize token.field_name
        format_value evaluate(token, args), tokenize_format_spec \
          token.format_spec.replace /\{(.*?)\}/g, (match, field_name) ->
            descend args, normalize(field_name).split('.')
  values.join('')


String::format = (args...) -> format this, args...

String::format.transformers = format.transformers = {}

String::format.version = format.version = '0.2.1'


module?.exports = format
