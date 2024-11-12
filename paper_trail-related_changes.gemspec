$:.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'paper_trail/related_changes/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = 'paper_trail-related_changes'
  spec.version     = PaperTrail::RelatedChanges::VERSION
  spec.authors     = ['Dustin Zeisler']
  spec.email       = ['dustin@zeisler.net']
  spec.homepage    = 'https://github.com/zeisler/paper_trail-related_changes'
  spec.summary     = 'Groups and formats related changes that are recorded with PaperTrail'
  spec.description = 'Find all child ActiveRecord relationships from a given resource and groups thems by request_id.'
  spec.license     = 'MIT'

  spec.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']


  spec.add_dependency 'paper_trail', '~> 15.2.0'
  spec.add_dependency 'rails', '7.0.1'


  spec.add_development_dependency 'pg'
  spec.add_development_dependency 'rspec-rails'
end
