# Windows + Android + iOS klasorlerini olusturur ve Android internet iznini ekler.
flutter create --platforms=windows,android,ios --project-name frc_scouting .
flutter pub get

$m = "android\app\src\main\AndroidManifest.xml"
$t = [IO.File]::ReadAllText($m)
if ($t -notmatch "android.permission.INTERNET") {
  $t = $t -replace "<application", "<uses-permission android:name=`"android.permission.INTERNET`"/>`n    <application"
  [IO.File]::WriteAllText($m, $t, (New-Object Text.UTF8Encoding($false)))
  Write-Host "INTERNET izni eklendi."
}
Write-Host "Tamam."
