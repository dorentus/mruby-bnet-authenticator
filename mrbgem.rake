MRuby::Gem::Specification.new('mruby-bnet-authenticator') do |spec|
  spec.license = 'MIT'
  spec.authors = 'ZHANG Yi'
  spec.version = '0.0.1'
  spec.add_dependency('mruby-digest')
  spec.add_dependency('mruby-regexp-pcre')
  spec.add_dependency('mruby-pack')
  spec.add_dependency('mruby-socket')

  bigd_dirname = 'vendor'
  bigd_src = "#{spec.dir}/#{bigd_dirname}"

  spec.cc.include_paths << bigd_src
  spec.objs += %W(
    #{bigd_src}/bigd.c
    #{bigd_src}/bigdigits.c
  ).map { |f| f.relative_path_from(dir).pathmap("#{build_dir}/%X.o") }
end
