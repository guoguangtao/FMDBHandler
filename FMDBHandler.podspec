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
  s.source       = { :git => "https://github.com/JudeGGT/FMDBHandler", :tag => "v1.0.0" }
  s.source_files  = "FMDBHandler/FMDBHandler/*.{h,m}"
  s.exclude_files = "Classes/Exclude"


end
