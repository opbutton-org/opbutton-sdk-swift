Pod::Spec.new do |s|
  s.name             = 'OpButtonSDK'
  s.version          = '1.0.61'
  s.summary          = 'OpButton remote debugging SDK for iOS'
  s.description      = <<-DESC
    OpButtonSDK provides real-time remote debugging, logging, metrics collection,
    and UI widget interaction for iOS applications via the OpButton web dashboard.
  DESC
  s.homepage         = 'https://github.com/opbutton-org/opbutton-sdk-swift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'irov' => 'levchenko.yuriy.vladimirovich@gmail.com' }
  s.source           = { :git => 'https://github.com/opbutton-org/opbutton-sdk-swift.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.macos.deployment_target = '10.15'
  s.swift_versions = ['5.9']

  s.source_files = 'Sources/OpButtonSDK/**/*.swift'

  s.frameworks = 'Foundation'
  s.ios.frameworks = 'UIKit', 'ReplayKit'
  s.ios.dependency 'LiveKitClient', '2.15.1'
  s.osx.dependency 'LiveKitClient', '2.15.1'
end
