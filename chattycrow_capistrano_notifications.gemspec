# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
# Pavel Lazureykis<lazureykis@gmail.com> is original author of Capistrano-Jabber notification gem
# This gem was something like fork, maybe bootstrap for notifications
Gem::Specification.new do |spec|
  spec.name          = "chattycrow_capistrano_notifications"
  spec.version       = '0.0.1'
  spec.authors       = ["NetBrick"]
  spec.email         = ["info@netbrick.eu", "jan.strnadek@gmail.com"]
  spec.description   = %q{Sending notifications about deploy via chattycrow service}
  spec.summary       = %q{Sending notifications about deploy via chattycrow service}
  spec.homepage      = "https://chattycrow.com/"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'capistrano', '~> 3.1'
  spec.add_dependency 'chatty_crow', '>= 1.3.1'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
end
