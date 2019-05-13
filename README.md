# PasL
A simple language for Parslet::Parse

## Usage
```bash
$ wget https://raw.githubusercontent.com/tct-i15fujimura1s/pasl/master/pasl.rb
```

```Ruby
require './pasl.rb'

Parser = PasL.parseFile root, filename
parsed = Parser.new.parse sourceCode
```

## Grammar
* `rule1 <- E` := `rule(:rule1) { e }`
* `E | F` := `e | f`
* `E F` := `e >> f`
* `&E` := `e.present?`
* `!E` := `e.absent?`
* `E?` := `e.maybe`
* `E*` := `e.repeat`
* `E+` := `e.repeat(1)`
* `.` := `any`
* `"stuv"` := `str("stuv")`
* `[a-z]` := `match("[a-z]")`
* `/pat/` := `match("pat")`
* `E` := `e`
