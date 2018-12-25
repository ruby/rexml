# News

## 3.1.9 - 2018-12-20 {#version-3-1-9}

### Improvements

  * Improved backward compatibility.

    Restored `REXML::Parsers::BaseParser::UNQME_STR` because it's used
    by kramdown.

## 3.1.8 - 2018-12-20 {#version-3-1-8}

### Improvements

  * Added support for customizing quote character in prologue.
    [GitHub#8][Bug #9367][Reported by Takashi Oguma]

    * You can use `"` as quote character by specifying `:quote` to
      `REXML::Document#context[:prologue_quote]`.

    * You can use `'` as quote character by specifying `:apostrophe`
      to `REXML::Document#context[:prologue_quote]`.

  * Added processing instruction target check. The target must not nil.
    [GitHub#7][Reported by Ariel Zelivansky]

  * Added name check for element and attribute.
    [GitHub#7][Reported by Ariel Zelivansky]

  * Stopped to use `Exception`.
    [GitHub#9][Patch by Jean Boussier]

### Fixes

  * Fixed a bug that `REXML::Text#clone` escapes value twice.
    [ruby-dev:50626][Bug #15058][Reported by Ryosuke Nanba]

### Thanks

  * Takashi Oguma

  * Ariel Zelivansky

  * Jean Boussier

  * Ryosuke Nanba
