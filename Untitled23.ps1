$text = "<LANG LANGID=""409"">Your system will restart now!</LANG>
<LANG LANGID=""407""><PITCH MIDDLE = '2'>Oh nein, das geht nicht!</PITCH></LANG>
<LANG LANGID=""409"">I don't care baby</LANG>
<LANG LANGID=""407"">Ich rufe meinen Prinz! Herbert! Tu was!</LANG>
"

$speaker = New-Object -ComObject Sapi.SpVoice
$speaker.Rate = 0
$speaker.Speak($text)