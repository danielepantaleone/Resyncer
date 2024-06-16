Pod::Spec.new do |s|
  s.name                        = "Resyncer"
  s.version                     = "1.0.0"
  s.summary                     = "A swift library to make use of asynchronous API in a synchronous environment"
  s.license                     = { :type => "MIT", :file => "LICENSE" }
  s.homepage                    = "https://github.com/danielepantaleone/PersistedProperty"
  s.authors                     = { "Daniele Pantaleone" => "danielepantaleone@me.com" }
  s.ios.deployment_target       = "12.0"
  s.osx.deployment_target       = "12.0"
  s.source                      = { :git => "https://github.com/danielepantaleone/Resyncer.git", :tag => "#{s.version}" }
  s.source_files                = "Sources/Resyncer/**/*.swift"
  s.resources                   = "Sources/Resyncer/**/*.xcprivacy"
  s.swift_version               = "5.7"
end
