require_relative "lib/bullet_train/billing/usage/version"

Gem::Specification.new do |spec|
  spec.name = "bullet_train-billing-usage"
  spec.version = BulletTrain::Billing::Usage::VERSION
  spec.authors = ["Andrew Culver"]
  spec.email = ["andrew.culver@gmail.com"]
  spec.homepage = "https://github.com/bullet-train-co/bullet_train-billing-usage"
  spec.summary = "Bullet Train Billing Usage"
  spec.description = spec.summary
  spec.license = "Nonstandard"

  spec.metadata["allowed_push_host"] = "https://gem.fury.io/bullettrain"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 6.0"
  spec.add_dependency "bullet_train"
  spec.add_dependency "verbs"

  spec.add_development_dependency "pg", "~> 1.2.0"
  spec.add_development_dependency "factory_bot_rails", "~> 6.2.0"
  spec.add_development_dependency "standard"
end
