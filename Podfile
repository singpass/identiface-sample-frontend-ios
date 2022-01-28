# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'ndi-identiface-sample-public-ios' do
    # Comment the next line if you don't want to use dynamic frameworks
    use_frameworks!

    # Pods for ndi-identiface-sample-public-ios
    pod 'iProov', '~> 9.0.1'
    pod 'SwiftyJSON', '~> 4.0'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        if ['SwiftyJSON', 'iProov', 'Socket.IO-Client-Swift', 'Starscream'].include? target.name
            target.build_configurations.each do |config|
                config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
            end
        end
    end
end
