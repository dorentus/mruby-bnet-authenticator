#mruby-bnet-authenticator
mruby implementation of the Battle.net Mobile Authenticator [:information_source:](https://battle.net/support/article/battlenet-authenticator).

[![Build Status](https://travis-ci.org/dorentus/mruby-bnet-authenticator.svg?branch=master)](https://travis-ci.org/dorentus/mruby-bnet-authenticator)

## Installation, by mrbgems
- add conf.gem line to `build_config.rb`

```ruby
MRuby::Build.new do |conf|

    # ... (snip) ...

    conf.gem :github => 'iij/mruby-digest'
    conf.gem :github => 'iij/mruby-io'
    conf.gem :github => 'iij/mruby-socket'
    conf.gem :github => 'iij/mruby-regexp-pcre'
    conf.gem :github => 'iij/mruby-pack'
    conf.gem :github => 'dorentus/mruby-bnet-authenticator'
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
### mruby-bnet-authenticator
under the MIT License
- see LICENSE file

### BigDigits multiple-precision arithmetic library (`src/bigd*.*`)
Contains multiple-precision arithmetic code originally written by David Ireland, copyright (c) 2001-13 by D.I. Management Services Pty Limited <www.di-mgt.com.au>, and is used with permission. Link: [Cryptography Software Code](http://www.di-mgt.com.au/crypto.html).
