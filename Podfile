# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

#install! 'cocoapods',
#         :generate_multiple_pod_projects => true,
#         :incremental_installation => true,
#         :disable_input_output_paths => true,
#         :preserve_pod_file_structure => true

target 'ZDFfiHookDemo' do
  # Comment the next line if you don't want to use dynamic frameworks
  # use_frameworks!

  # Pods for ZDFfiHook
  # pod 'libffi-core'
  pod 'ZDFfiHook', :path => './ZDFfiHook.podspec'
  pod 'Aspects'

  target 'ZDFfiHookDemoTests' do
    inherit! :search_paths
    # Pods for testing
    pod 'Aspects'
  end

  target 'ZDFfiHookDemoUITests' do
    # Pods for testing
  end

end
