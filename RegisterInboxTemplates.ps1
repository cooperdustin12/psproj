# Enumerate the Inbox UE-V Templates and register those templates
$inboxTemplates= Get-ChildItem -Path $env:PROGRAMDATA\Microsoft\UEV\InboxTemplates -Filter *.xml
for ($count = 0; $count -lt $inboxTemplates.Count; $count++) {
    Register-UevTemplate -Path $inboxTemplates[$count].FullName -ErrorAction SilentlyContinue
}
