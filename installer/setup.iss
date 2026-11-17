[Setup]
AppName=FRC Scouting
AppVersion=1.0.0
DefaultDirName={autopf}\FRC Scouting
DefaultGroupName=FRC Scouting
OutputDir=output
OutputBaseFilename=FRC_Scouting_Setup
Compression=lzma
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"

[Tasks]
Name: "desktopicon"; Description: "Masaüstü kısayolu oluştur"

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\FRC Scouting"; Filename: "{app}\frc_scouting.exe"
Name: "{autodesktop}\FRC Scouting"; Filename: "{app}\frc_scouting.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\frc_scouting.exe"; Description: "FRC Scouting'i başlat"; Flags: nowait postinstall skipifsilent
