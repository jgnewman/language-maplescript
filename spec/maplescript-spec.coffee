describe "MapleScript grammar", ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage("language-maplescript")

    runs ->
      grammar = atom.grammars.grammarForScopeName("source.maplescript")

  it "parses the grammar", ->
    expect(grammar).toBeDefined()
    expect(grammar.scopeName).toBe "source.maplescript"

  it "tokenizes basic comments", ->
    {tokens} = grammar.tokenizeLine "-- maplescript"
    expect(tokens[0]).toEqual value: "--", scopes: ["source.maplescript", "comment.line.semicolon.maplescript", "punctuation.definition.comment.maplescript"]
    expect(tokens[1]).toEqual value: " maplescript", scopes: ["source.maplescript", "comment.line.semicolon.maplescript"]

  it "does not tokenize escaped hashtags as comments", ->
    {tokens} = grammar.tokenizeLine "\\-- maplescript"
    expect(tokens[0]).toEqual value: "\\-- ", scopes: ["source.maplescript"]
    expect(tokens[1]).toEqual value: "maplescript", scopes: ["source.maplescript", "meta.symbol.maplescript"]

  it "tokenizes double quote strings", ->
    {tokens} = grammar.tokenizeLine '"foo bar"'
    expect(tokens[0]).toEqual value: '"', scopes: ["source.maplescript", "string.quoted.double.maplescript", "punctuation.definition.string.begin.maplescript"]
    expect(tokens[1]).toEqual value: 'foo bar', scopes: ["source.maplescript", "string.quoted.double.maplescript"]
    expect(tokens[2]).toEqual value: '"', scopes: ["source.maplescript", "string.quoted.double.maplescript", "punctuation.definition.string.end.maplescript"]

  it "tokenizes single quote strings", ->
    {tokens} = grammar.tokenizeLine "'foo bar'"
    expect(tokens[0]).toEqual value: "'", scopes: ["source.maplescript", "string.quoted.single.maplescript", "punctuation.definition.string.begin.maplescript"]
    expect(tokens[1]).toEqual value: "foo bar", scopes: ["source.maplescript", "string.quoted.single.maplescript"]
    expect(tokens[2]).toEqual value: "'", scopes: ["source.maplescript", "string.quoted.single.maplescript", "punctuation.definition.string.end.maplescript"]

  it "tokenizes backtick strings", ->
    {tokens} = grammar.tokenizeLine "`foo bar`"
    expect(tokens[0]).toEqual value: "`", scopes: ["source.maplescript", "string.quoted.single.maplescript", "punctuation.definition.string.begin.maplescript"]
    expect(tokens[1]).toEqual value: "foo bar", scopes: ["source.maplescript", "string.quoted.single.maplescript"]
    expect(tokens[2]).toEqual value: "`", scopes: ["source.maplescript", "string.quoted.single.maplescript", "punctuation.definition.string.end.maplescript"]

  it "tokenizes string interpolation", ->
    {tokens} = grammar.tokenizeLine "`${foo}`"
    expect(tokens[0]).toEqual value: "`", scopes: ['source.maplescript', 'string.quoted.single.maplescript', 'punctuation.definition.string.begin.maplescript']
    expect(tokens[1]).toEqual value: "${", scopes: [ 'source.maplescript', 'string.quoted.single.maplescript', 'meta.interpolation.maplescript' ]
    expect(tokens[2]).toEqual value: "foo", scopes: [ 'source.maplescript', 'string.quoted.single.maplescript', 'meta.interpolation.maplescript', 'meta.symbol.maplescript' ]
    expect(tokens[3]).toEqual value: "}", scopes: [ 'source.maplescript', 'string.quoted.single.maplescript', 'meta.interpolation.maplescript' ]
    expect(tokens[4]).toEqual value: "`", scopes: ['source.maplescript', 'string.quoted.single.maplescript', 'punctuation.definition.string.end.maplescript']

  it "tokenizes character escape sequences", ->
    {tokens} = grammar.tokenizeLine '"\\n"'
    expect(tokens[0]).toEqual value: '"', scopes: ["source.maplescript", "string.quoted.double.maplescript", "punctuation.definition.string.begin.maplescript"]
    expect(tokens[1]).toEqual value: '\\n', scopes: ["source.maplescript", "string.quoted.double.maplescript", "constant.character.escape.maplescript"]
    expect(tokens[2]).toEqual value: '"', scopes: ["source.maplescript", "string.quoted.double.maplescript", "punctuation.definition.string.end.maplescript"]

  it "tokenizes regexes", ->
    {tokens} = grammar.tokenizeLine '/foo\\//gim'
    expect(tokens[0]).toEqual value: '/foo\\//gim', scopes: ["source.maplescript", "string.regexp.maplescript"]

  it "tokenizes numerics", ->
    numbers =
      "constant.numeric.ratio.maplescript": ["1/2", "123/456"]
      "constant.numeric.arbitrary-radix.maplescript": ["2R1011", "16rDEADBEEF"]
      "constant.numeric.hexadecimal.maplescript": ["0xDEADBEEF", "0XDEADBEEF"]
      "constant.numeric.octal.maplescript": ["0123"]
      "constant.numeric.bigdecimal.maplescript": ["123.456M"]
      "constant.numeric.double.maplescript": ["123.45", "123.45e6", "123.45E6", "123", "12321"]
      "constant.numeric.bigint.maplescript": ["123N"]

    for scope, nums of numbers
      for num in nums
        {tokens} = grammar.tokenizeLine num
        expect(tokens[0]).toEqual value: num, scopes: ["source.maplescript", scope]

  it "tokenizes booleans", ->
    booleans =
      "constant.language.boolean.maplescript": ["true", "false"]

    for scope, bools of booleans
      for bool in bools
        {tokens} = grammar.tokenizeLine bool
        expect(tokens[0]).toEqual value: bool, scopes: ["source.maplescript", scope]

  it "tokenizes null", ->
    {tokens} = grammar.tokenizeLine "null"
    expect(tokens[0]).toEqual value: "null", scopes: ["source.maplescript", "constant.language.nil.maplescript"]

  it "tokenizes undefined", ->
    {tokens} = grammar.tokenizeLine "undefined"
    expect(tokens[0]).toEqual value: "undefined", scopes: ["source.maplescript", "constant.language.nil.maplescript"]

  it "tokenizes keywords", ->
    tests =
      "meta.expression.maplescript": ["(:foo)"]
      "meta.map.maplescript": ["{:foo}"]
      "meta.vector.maplescript": ["[:foo]"]

    for metaScope, lines of tests
      for line in lines
        {tokens} = grammar.tokenizeLine line
        expect(tokens[1]).toEqual value: ":foo", scopes: ["source.maplescript", metaScope, "constant.keyword.maplescript"]

  it "tokenizes keyfns (keyword control)", ->
    keyfns = ["->", ">>=", "async", "await", "destr", "do", "export", "if", "import", "make", "of"]

    for keyfn in keyfns
      {tokens} = grammar.tokenizeLine "(#{keyfn})"
      expect(tokens[1]).toEqual value: keyfn, scopes: ["source.maplescript", "meta.expression.maplescript", "keyword.control.maplescript"]

  it "tokenizes functions", ->
    expressions = ["(foo)", "(foo 1 10)"]

    for expr in expressions
      {tokens} = grammar.tokenizeLine expr
      expect(tokens[1]).toEqual value: "foo", scopes: ["source.maplescript", "meta.expression.maplescript", "entity.name.function.maplescript"]

  testMetaSection = (metaScope, puncScope, startsWith, endsWith) ->
    # Entire expression on one line.
    {tokens} = grammar.tokenizeLine "#{startsWith}foo, bar#{endsWith}"

    [start, mid..., end] = tokens

    expect(start).toEqual value: startsWith, scopes: ["source.maplescript", "meta.#{metaScope}.maplescript", "punctuation.section.#{puncScope}.begin.maplescript"]
    expect(end).toEqual value: endsWith, scopes: ["source.maplescript", "meta.#{metaScope}.maplescript", "punctuation.section.#{puncScope}.end.trailing.maplescript"]

    for token in mid
      expect(token.scopes.slice(0, 2)).toEqual ["source.maplescript", "meta.#{metaScope}.maplescript"]

    # Expression broken over multiple lines.
    tokens = grammar.tokenizeLines("#{startsWith}foo\n bar#{endsWith}")

    [start, mid..., after] = tokens[0]

    expect(start).toEqual value: startsWith, scopes: ["source.maplescript", "meta.#{metaScope}.maplescript", "punctuation.section.#{puncScope}.begin.maplescript"]

    for token in mid
      expect(token.scopes.slice(0, 2)).toEqual ["source.maplescript", "meta.#{metaScope}.maplescript"]

    [mid..., end] = tokens[1]

    expect(end).toEqual value: endsWith, scopes: ["source.maplescript", "meta.#{metaScope}.maplescript", "punctuation.section.#{puncScope}.end.trailing.maplescript"]

    for token in mid
      expect(token.scopes.slice(0, 2)).toEqual ["source.maplescript", "meta.#{metaScope}.maplescript"]

  it "tokenizes expressions", ->
    testMetaSection "expression", "expression", "(", ")"

  it "tokenizes vectors", ->
    testMetaSection "vector", "vector", "[", "]"

  it "tokenizes maps", ->
    testMetaSection "map", "map", "{", "}"

  it "tokenizes functions in nested sexp", ->
    {tokens} = grammar.tokenizeLine "((foo bar) baz)"
    expect(tokens[0]).toEqual value: "(", scopes: ["source.maplescript", "meta.expression.maplescript", "punctuation.section.expression.begin.maplescript"]
    expect(tokens[1]).toEqual value: "(", scopes: ["source.maplescript", "meta.expression.maplescript", "meta.expression.maplescript", "punctuation.section.expression.begin.maplescript"]
    expect(tokens[2]).toEqual value: "foo", scopes: ["source.maplescript", "meta.expression.maplescript", "meta.expression.maplescript", "entity.name.function.maplescript"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.maplescript", "meta.expression.maplescript", "meta.expression.maplescript"]
    expect(tokens[4]).toEqual value: "bar", scopes: ["source.maplescript", "meta.expression.maplescript", "meta.expression.maplescript", "meta.symbol.maplescript"]
    expect(tokens[5]).toEqual value: ")", scopes: ["source.maplescript", "meta.expression.maplescript", "meta.expression.maplescript", "punctuation.section.expression.end.maplescript"]
    expect(tokens[6]).toEqual value: " ", scopes: ["source.maplescript", "meta.expression.maplescript"]
    expect(tokens[7]).toEqual value: "baz", scopes: ["source.maplescript", "meta.expression.maplescript", "meta.symbol.maplescript"]
    expect(tokens[8]).toEqual value: ")", scopes: ["source.maplescript", "meta.expression.maplescript", "punctuation.section.expression.end.trailing.maplescript"]

  it "tokenizes maps used as functions", ->
    {tokens} = grammar.tokenizeLine "({:foo bar} :foo)"
    expect(tokens[0]).toEqual value: "(", scopes: ["source.maplescript", "meta.expression.maplescript", "punctuation.section.expression.begin.maplescript"]
    expect(tokens[1]).toEqual value: "{", scopes: ["source.maplescript", "meta.expression.maplescript", "meta.map.maplescript", "punctuation.section.map.begin.maplescript"]
    expect(tokens[2]).toEqual value: ":foo", scopes: ["source.maplescript", "meta.expression.maplescript", "meta.map.maplescript", "constant.keyword.maplescript"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.maplescript", "meta.expression.maplescript", "meta.map.maplescript"]
    expect(tokens[4]).toEqual value: "bar", scopes: ["source.maplescript", "meta.expression.maplescript", "meta.map.maplescript", "meta.symbol.maplescript"]
    expect(tokens[5]).toEqual value: "}", scopes: ["source.maplescript", "meta.expression.maplescript", "meta.map.maplescript", "punctuation.section.map.end.maplescript"]
    expect(tokens[6]).toEqual value: " ", scopes: ["source.maplescript", "meta.expression.maplescript"]
    expect(tokens[7]).toEqual value: ":foo", scopes: ["source.maplescript", "meta.expression.maplescript", "constant.keyword.maplescript"]
    expect(tokens[8]).toEqual value: ")", scopes: ["source.maplescript", "meta.expression.maplescript", "punctuation.section.expression.end.trailing.maplescript"]

  describe "firstLineMatch", ->
    it "recognises interpreter directives", ->
      valid = """
        #!/usr/sbin/boot foo
        #!/usr/bin/boot foo=bar/
        #!/usr/sbin/boot
        #!/usr/sbin/boot foo bar baz
        #!/usr/bin/boot perl
        #!/usr/bin/boot bin/perl
        #!/usr/bin/boot
        #!/bin/boot
        #!/usr/bin/boot --script=usr/bin
        #! /usr/bin/env A=003 B=149 C=150 D=xzd E=base64 F=tar G=gz H=head I=tail boot
        #!\t/usr/bin/env --foo=bar boot --quu=quux
        #! /usr/bin/boot
        #!/usr/bin/env boot
      """
      for line in valid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).not.toBeNull()

      invalid = """
        \x20#!/usr/sbin/boot
        \t#!/usr/sbin/boot
        #!/usr/bin/env-boot/node-env/
        #!/usr/bin/das-boot
        #! /usr/binboot
        #!\t/usr/bin/env --boot=bar
      """
      for line in invalid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).toBeNull()

    it "recognises Emacs modelines", ->
      valid = """
        #-*- MapleScript -*-
        #-*- mode: MapleScript -*-
        /* -*-mapleScript-*- */
        // -*- MapleScript -*-
        /* -*- mode:MapleScript -*- */
        // -*- font:bar;mode:MapleScript -*-
        // -*- font:bar;mode:MapleScript;foo:bar; -*-
        // -*-font:mode;mode:MapleScript-*-
        // -*- foo:bar mode: mapleSCRIPT bar:baz -*-
        " -*-foo:bar;mode:maplescript;bar:foo-*- ";
        " -*-font-mode:foo;mode:maplescript;foo-bar:quux-*-"
        "-*-font:x;foo:bar; mode : maplescript; bar:foo;foooooo:baaaaar;fo:ba;-*-";
        "-*- font:x;foo : bar ; mode : MapleScriptScript ; bar : foo ; foooooo:baaaaar;fo:ba-*-";
      """
      for line in valid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).not.toBeNull()

      invalid = """
        /* --*maplescript-*- */
        /* -*-- maplescript -*-
        /* -*- -- MapleScript -*-
        /* -*- MapleScript -;- -*-
        // -*- iMapleScript -*-
        // -*- MapleScript; -*-
        // -*- maplescript-door -*-
        /* -*- model:maplescript -*-
        /* -*- indent-mode:maplescript -*-
        // -*- font:mode;MapleScript -*-
        // -*- mode: -*- MapleScript
        // -*- mode: das-maplescript -*-
        // -*-font:mode;mode:maplescript--*-
      """
      for line in invalid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).toBeNull()
