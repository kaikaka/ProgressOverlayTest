
Pod::Spec.new do |s|
  s.name         = "ProgressOverlay"
  s.version      = "1.0.0"
  s.summary      = "This is Swift for MBProgressHUD"
  s.homepage     = "http://yoon.farbox.com/"
  s.license      = "MIT"
  s.authors      = { '观剑不则声' => 'yoon1583@foxmail.com'}
  s.platform     = :ios, "9.0"
  s.ios.deployment_target = '9.0'
  s.source       = { :git => "https://github.com/sugarAndsugar/ProgressOverlay.git", :tag => 's.version' }
  s.source_files = 'ProgressOverlay/*.{h,m}'
  s.requires_arc = true
end
