$City = 'Virginia Beach'

(Invoke-WebRequest "http://wttr.in/$City" -UserAgent curl).content -split "`n" 