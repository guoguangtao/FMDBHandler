Pod::Spec.new do |s|

  s.name         = "FMDBHandler"
  s.version      = "1.0"
  s.summary      = "A Library for iOS to use for FMDBHandler."
  s.description  = <<-DESC
                   Testing Private Podspec.
                   DESC
  s.homepage     = "https://github.com/JudeGGT/FMDBHandler"
  s.license      = "MIT"
  s.author             = { "guoguangtao" => "jude_guo@163.com" }
  s.source       = { :git => "https://github.com/JudeGGT/FMDBHandler", :tag => "v1.0.2" }
  s.source_files  = "FMDBHandler/FMDBHandler/*.{h,m}"
  s.platform = :ios, "8.0"
  s.requires_arc = true
  s.static_framework = true
  s.dependency "FMDB"
end
