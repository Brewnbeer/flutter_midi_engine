#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_midi_engine.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_midi_engine'
  s.version          = '0.1.0'
  s.summary          = 'Advanced MIDI synthesizer plugin with SF2/SF3 soundfont support'
  s.description      = <<-DESC
Flutter MIDI Engine provides comprehensive MIDI synthesis capabilities with support for SF2/SF3 soundfonts,
multi-channel playback, program changes, audio effects, and more.
                       DESC
  s.homepage         = 'https://github.com/yourusername/flutter_midi_engine'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # Include AudioToolbox framework for MIDI synthesis
  s.frameworks = 'AudioToolbox', 'AVFoundation', 'CoreAudio'
end
