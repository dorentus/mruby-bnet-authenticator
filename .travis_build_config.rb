MRuby::Build.new do |conf|
  toolchain :gcc
  conf.gembox 'default'
  conf.gem :github => 'iij/mruby-digest'
  conf.gem :github => 'iij/mruby-io'
  conf.gem :github => 'iij/mruby-socket'
  conf.gem :github => 'iij/mruby-mtest'
  conf.gem :github => 'luisbebop/mruby-polarssl'
  conf.gem :github => 'mattn/mruby-http'
  conf.gem :github => 'matsumoto-r/mruby-simplehttp'
  conf.gem :github => 'matsumoto-r/mruby-httprequest'
  conf.gem :github => 'iij/mruby-regexp-pcre'
  conf.gem :github => 'iij/mruby-pack'
  conf.gem '../mruby-bnet-authenticator'
end
