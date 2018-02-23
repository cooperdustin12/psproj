Add-Type -AssemblyName System.speech
$tts= New-Object System.Speech.Synthesis.SpeechSynthesizer
$tts.Speak('Have you tried turning it off and on again?')