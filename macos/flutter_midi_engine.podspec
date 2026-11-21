#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_midi_engine.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_midi_engine'
  s.version          = '0.3.0'
  s.summary          = 'MIDI synthesizer plugin with SF2 soundfont support'
  s.description      = <<-DESC
Flutter MIDI Engine for macOS. Plays MIDI notes through Apple's AUSampler with SF2 soundfonts.
                       DESC
  s.homepage         = 'https://github.com/Brewnbeer/flutter_midi_engine'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Aditya Sutar' => 'brewnbeer34@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'flutter_midi_engine/Sources/flutter_midi_engine/**/*.swift'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.15'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'

  s.frameworks = 'AudioToolbox', 'CoreAudio'
end
