Pod::Spec.new do |s|
  s.name             = 'TwitterVideoUploader'
  s.version          = '0.2.0'
  s.summary          = 'STTwitter chunked video upload extension using RxSwift.'

  s.description      = <<-DESC
STTwitter chunked video upload extension using RxSwift.
                       DESC

  s.homepage         = 'https://github.com/noppefoxwolf/TwitterVideoUploader'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Tomoya Hirano' => 'cromteria@gmail.com' }
  s.source           = { :git => 'https://github.com/noppefoxwolf/TwitterVideoUploader.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/noppefoxwolf'

  s.ios.deployment_target = '8.0'

  s.source_files = 'TwitterVideoUploader/Classes/**/*'

  s.dependency 'STTwitter'
  s.dependency 'RxSwift', '4.0.0-rc.0'
  s.dependency 'ObjectMapper', '3.0.0'
end
