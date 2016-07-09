Pod::Spec.new do |s|
  s.name             = "LPFPS"
  s.version          = "0.0.2"
  s.summary          = "iOS App FPS tracer and monitor"
  s.description      = <<-DESC
                       iOS App FPS tracer and monitor that works in even different rootViewControllers
                       DESC
  s.homepage         = "https://github.com/litt1e-p/LPFPS"
  s.license          = { :type => 'MIT' }
  s.author           = { "litt1e-p" => "litt1e.p4ul@gmail.com" }
  s.source           = { :git => "https://github.com/litt1e-p/LPFPS.git", :tag => '0.0.2' }
  s.platform = :ios, '8.0'
  s.requires_arc = true
  s.source_files = 'LPFPS/*'
  s.frameworks = 'Foundation', 'UIKit'
end
