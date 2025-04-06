Pod::Spec.new do |s|
  s.name                        = "Resyncer"
  s.version                     = "1.2.0"
  s.summary                     = "Resyncer is a Swift library designed to seamlessly integrate asynchronous APIs within synchronous environments"
  s.license                     = { :type => "MIT", :file => "LICENSE" }
  s.homepage                    = "https://github.com/danielepantaleone/Resyncer"
  s.authors                     = { "Daniele Pantaleone" => "danielepantaleone@me.com" }
  s.ios.deployment_target       = "12.0"
  s.osx.deployment_target       = "12.0"
  s.source                      = { :git => "https://github.com/danielepantaleone/Resyncer.git", :tag => "#{s.version}" }
  s.source_files                = "Sources/Resyncer/**/*.swift"
  s.swift_version               = "5.7"
end
