Pod::Spec.new do |spec|
  spec.name         = "HXCPPRuntime"
  spec.version      = "0.1.0"
  spec.summary      = "HXCPP runtime wrapper to use Haxe libraries from standard iOS/Android projects"
  spec.homepage     = "https://github.com/jeremyfa/lib-hxcpp-runtime"
  spec.license      = "MIT"
  spec.author       = { "Jérémy Faivre" => "contact@jeremyfa.com" }
  spec.platform     = :ios, "8.0"
  spec.requires_arc = true

  spec.source       = { :http => "https://github.com/jeremyfa/lib-hxcpp-runtime/releases/download/v0.1.0/HXCPPRuntime-Release.framework.zip" }
  
  spec.vendored_frameworks = "projects/ios/HXCPPRuntime/Output/Release-iphoneuniversal/HXCPPRuntime.framework"

  spec.frameworks = "Foundation"
end
