#mruby-bnet-authenticator
Battle.net Mobile Authenticator (mruby class)

[![Build Status](https://travis-ci.org/dorentus/mruby-bnet-authenticator.svg?branch=master)](https://travis-ci.org/dorentus/mruby-bnet-authenticator)

## Installation, by mrbgems
- add conf.gem line to `build_config.rb`

```ruby
MRuby::Build.new do |conf|

    # ... (snip) ...

    conf.gem :git => 'https://github.com/dorentus/mruby-bnet-authenticator.git'
end
```

## Usage

Initialize an authenticator with given serial and secret
----
```ruby
authenticator = Bnet::Authenticator.new('CN-1402-1943-1283', '4202aa2182640745d8a807e0fe7e34b30c1edb23')
puts authenticator
```

Get a token
----
```ruby
authenticator.get_token
```

Request a new authenticator from server
----
```ruby
authenticator = Bnet::Authenticator.request_authenticator(:US)
```

Restore an authenticator from server
----
```ruby
authenticator = Bnet::Authenticator.restore_authenticator('CN-1402-1943-1283', '4CKBN08QEB')
```

## License
under the MIT License:
- see LICENSE file

Contains multiple-precision arithmetic code originally written by David Ireland, copyright (c) 2001-13 by D.I. Management Services Pty Limited <www.di-mgt.com.au>, and is used with permission. <a href="http://www.di-mgt.com.au/crypto.html">Cryptography Software Code</a>
