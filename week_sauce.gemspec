Gem::Specification.new do |s|
  s.name        = 'week_sauce'
  s.version     = '0.0.0'
  
  s.summary     = "Day-of-week bitmask"
  s.description = "A simple gem to serialize selected days of the week as a bitmask"
  s.authors     = "Daniel Høier Øhrgaard"
  s.email       = 'daniel@stimulacrum.com'
  
  s.required_ruby_version = '>= 1.9.3'
  
  s.add_development_dependency 'tzinfo', '~> 0.3.29'
  s.add_development_dependency 'activesupport', '>= 3.2.0'
  
  s.files       = ["lib/week_sauce.rb"]
end
