#
# Be sure to run `pod lib lint MBProgressHUD-Swift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MBProgressHUD-Swift'
  s.version          = '1.0.0'
  s.summary          = 'A short description of MBProgressHUD-Swift.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/xiayy0328/MBProgressHUD-Swift'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'xiayy0328' => 'xyy_ios@163.com' }
  s.source           = { :git => 'https://github.com/xiayy0328/MBProgressHUD-Swift.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  s.swift_version = '5.0'
  s.ios.deployment_target = '12.0'

  s.source_files = 'MBProgressHUD-Swift/Classes/**/*'
  
  # s.resource_bundles = {
  #   'MBProgressHUD-Swift' => ['MBProgressHUD-Swift/Assets/*.png']
  # }
end
