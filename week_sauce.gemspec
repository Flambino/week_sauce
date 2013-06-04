Gem::Specification.new do |s|
  s.name        = 'week_sauce'
  s.version     = '0.0.2'
  s.license     = "MIT"
  
  s.summary     = "Day-of-week bitmask"
  s.description = "A simple gem to serialize selected days of the week as a bitmask"
  s.author      = "Daniel Høier Øhrgaard"
  s.email       = 'daniel@stimulacrum.com'
  s.homepage    = 'https://github.com/Flambino/week_sauce'
  
  s.required_ruby_version = '>= 1.9.2'
  
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'tzinfo', '~> 0.3.29'
  s.add_development_dependency 'activesupport', '>= 3.2.0'
  
  s.files = ["lib/week_sauce.rb", "README.md", "MIT-LICENSE"]
end
