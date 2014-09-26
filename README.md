# rebase_attr [![Gem Version](https://badge.fury.io/rb/rebase_attr.svg)](http://badge.fury.io/rb/rebase_attr)

Convert an attribute to a specified base.

When do you need this?

- If your IDs are too long to show, just convert to base 36 (digits and lower
  case letters).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rebase_attr'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rebase_attr

## Usage

Example for an active record table with long IDs:

```ruby
# == Schema Info
#
# Table name: medical_bills
#
#  id                  :integer(11)    not null, primary key
#

class Bill < ActiveRecord::Base
  rebase_attr :id, to: 32, readable: true # only digits and leters, without '0', 'o', '1' and 'l'
end
```

Then use it:

```ruby
bill = Bill.find(3151957185711)
bill.id
=> "2rnfkjw5f"
bill.id_without_rebase
=> 3151957185711
bill.id = "gw88yeya"
bill.id_without_rebase
=> 572581263402
```

Other functions you get when using rebase_attr:

```ruby
bill.id_without_rebase = 3151957185711
bill.id
=> "2rnfkjw5f"
Bill.find(Bill.decode_id("2rnfkjw5f"))
=> #<Bill id: 3151957185711>
bill.decode_id("2rnfkjw5f")
=> 3151957185711
Bill.encode_id(3151957185711)
=> "2rnfkjw5f"
bill.encode_id(3151957185711)
=> "2rnfkjw5f"
```

Options you can pass to rebase_attr:

```ruby
# Have :x return base 16, while '0' and '1' are replaced with 'x' and 'y', and then uppercased.
rebase_attr :x, to: 16, readable: true, convert: :upcase
# Have both :x and :y converted from a backend of octal string to a binary string, adding a 'b' in the beginning.
rebase_attr :x, :y, from: 8, to: 2, convert: -> (v) { "b#{v}" }, deconvert: -> (v) { v[1..-1] }
```

## Contributing

1. Fork it ( https://github.com/odedniv/rebase_attr/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
