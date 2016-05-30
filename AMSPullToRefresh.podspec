Pod::Spec.new do |s|

  s.name             = 'AMSPullToRefresh'
  s.version          = '0.1.1'
  s.summary          = 'A simple pull to refresh'
  s.description      = <<-DESC
AMSPullToRefresh is a simple pull to refresh.
                       DESC
  s.homepage         = 'https://github.com/anymuse/AMSPullToRefresh'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'anymuse' => 'anymuse@gmail.com' }
  s.source           = { :git => 'https://github.com/anymuse/AMSPullToRefresh.git', :tag => s.version.to_s }
  s.ios.deployment_target = '7.0'
  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.source_files = 'AMSPullToRefresh/*'
  s.public_header_files = 'AMSPullToRefresh/*.h'

end
