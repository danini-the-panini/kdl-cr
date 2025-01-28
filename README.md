# KDL

This is a Crystal implementation of the [KDL Document Language](https://kdl.dev/)

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     kdl:
       github: danini-the-panini/kdl-cr
   ```

2. Run `shards install`

## Usage

```crystal
require "kdl"

KDL.parse_document(a_string) #=> KDL::Document
```

## Contributing

1. Fork it (<https://github.com/danini-the-panini/kdl-cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Danielle Smith](https://github.com/danini-the-panini) - creator and maintainer
