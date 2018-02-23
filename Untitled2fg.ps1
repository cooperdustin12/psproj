[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = @'

<Window x:Class="MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WpfApp3"
        mc:Ignorable="d"
        Title="MainWindow" Height="350" Width="525">
	<Grid Background="#FFEAE1FF">
		<TextBox Name="servername" HorizontalAlignment="Left" Height="23" Margin="30,26,0,0" TextWrapping="Wrap" Text="ServerName" VerticalAlignment="Top" Width="352" TextChanged="TextBox_TextChanged"/>
		<RadioButton Content="Windows 2008 R2 Server " HorizontalAlignment="Left" Margin="30,85,0,0" VerticalAlignment="Top"/>
		<RadioButton Name="Windows_2008_R2_Domain_Controller" HorizontalAlignment="Left" Margin="30,105,0,0" VerticalAlignment="Top" Width="217" Content="Windows 2008 R2 Domain Controller "/>
		<RadioButton Content="Windows 2012 R2 Server " HorizontalAlignment="Left" Margin="30,125,0,0" VerticalAlignment="Top" Width="217"/>
		<RadioButton Content="Windows 2012 R2 Domain Controller " HorizontalAlignment="Left" Margin="30,145,0,0" VerticalAlignment="Top" Width="217"/>
		<CheckBox Name="servicesbox" Content="Services" HorizontalAlignment="Left" Margin="30,172,0,0" VerticalAlignment="Top"/>
		<CheckBox Name="processbox" Content="Processes" HorizontalAlignment="Left" Margin="103,172,0,0" VerticalAlignment="Top"/>
		<CheckBox Name="perfmonbox" Content="Perfmon Counters" HorizontalAlignment="Left" Margin="190,172,0,0" VerticalAlignment="Top"/>
		<CheckBox Name="eventlogbox" Content="Event Log Sources" HorizontalAlignment="Left" Margin="330,172,0,0" VerticalAlignment="Top"/>
		<Button Content="Go!" HorizontalAlignment="Left" Margin="30,270,0,0" VerticalAlignment="Top" Width="75"/>
		<TextBlock HorizontalAlignment="Left" Margin="30,217,0,0" TextWrapping="Wrap" Text="Email Results? " VerticalAlignment="Top"/>
		<RadioButton Name="emailyes" Content="Yes" HorizontalAlignment="Left" Margin="30,238,0,0" VerticalAlignment="Top"/>
		<RadioButton Name="emailno" Content="No" HorizontalAlignment="Left" Margin="72,238,0,0" VerticalAlignment="Top"/>
		<TextBox Name="outbox" HorizontalAlignment="Left" Height="112" Margin="120,201,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="387"/>
		<Label Content="Is Type:" HorizontalAlignment="Left" Margin="30,54,0,0" VerticalAlignment="Top" Width="59" Height="26"/>

	</Grid>
</Window>



'@
#Read XAML
$reader=(New-Object System.Xml.XmlNodeReader $xaml) 
try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
catch{Write-Host "Unable to load Windows.Markup.XamlReader. Some possible causes for this problem include: .NET Framework is missing PowerShell must be launched with PowerShell -sta, invalid XAML code was encountered."; exit}