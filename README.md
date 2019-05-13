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
