#
#  Be sure to run `pod spec lint Kliao.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|
  spec.name         = "ZDFfiHook"
  spec.version      = "0.0.1"
  spec.summary      = "hook Objective-C"
  spec.description  = <<-DESC
    hook with libffi
                   DESC
  spec.homepage     = "https://github.com/faimin/ZDFfiHook"
  spec.license      = "MIT"
  spec.author       = { "faimin" => "fuxianchao@gmail.com" }
  spec.requires_arc = true
  spec.prefix_header_file = false
  spec.platform     = :ios, "9.0"
  spec.source       = {
    :git => "https://github.com/faimin/ZDFfiHook.git",
    :tag => "#{spec.version}"
  }
  spec.module_name = 'ZDFfiHook'
  #spec.preserve_path = 'Source/module.modulemap', "Source/ZDFfiHookKit.h"
  #spec.module_map = 'Source/module.modulemap'
  spec.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES'
  }
  spec.source_files = "Source/*.{h,m}"
  spec.public_header_files = "Source/{NSObject+ZDFfiHook,ZDFfiDefine,ZDFfiHook}.h"
  spec.dependency "ZDLibffi"
  
end
