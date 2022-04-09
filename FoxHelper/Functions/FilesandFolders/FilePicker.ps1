function Invoke-FilePicker
{
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
    InitialDirectory = [Environment]::GetFolderPath('Desktop') 
}
$null = $FileBrowser.ShowDialog()
return $FileBrowser.FileName
}