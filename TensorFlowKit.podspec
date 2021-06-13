#
# Be sure to run `pod lib lint TensorFlowKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TensorFlowKit'
  s.version          = '1.0.1'
  s.summary          = 'Make TensorFlowLite easy to use.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  Just a few lines of code to set up, all the hard work this pod will take care of it.
                       DESC

  s.homepage         = 'https://github.com/OsenseTech/TensorFlowKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '蘇健豪' => 'jenhausu@osensetech.com' }
  s.source           = { :git => 'https://github.com/OsenseTech/TensorFlowKit.git', :tag => s.version.to_s }
  s.swift_versions   = ['5.0']
  s.ios.deployment_target = '11.0'
  
  s.dependency 'TensorFlowLiteSwift'
  s.static_framework = true
  
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  
  s.default_subspecs = 'Core'
  s.subspec 'Core' do |sp|
      sp.source_files = 'TensorFlowKit/Classes/Core/*'
  end
  
  s.subspec 'ObjC' do |sp|
      sp.source_files = 'TensorFlowKit/Classes/ObjC/*'
      sp.dependency 'TensorFlowKit/Core'
  end
  
end
