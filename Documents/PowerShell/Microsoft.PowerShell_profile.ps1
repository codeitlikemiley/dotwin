# Requirements
# scoop install fzf
# Install-Module PSReadLine -Force
# Install-Module npm-completion -Scope CurrentUser
# Install-Module -Name PSFzf -RequiredVersion 2.2.9
# cargo install fnm
# cargo install starship

Import-Module npm-completion
Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
Set-PsFzfOption -TabExpansion
# Use VI MODE
Set-PSReadlineOption -EditMode vi -BellStyle None
# Use Tab Completion
Set-PSReadLineKeyHandler -chord = -function Complete -vimode Command

# Bind Fuzzy Finder to Ctrl t and r in our Terminal
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
# Use history for Autocompetion
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineKeyHandler -Chord "Ctrl+f" -Function ForwardWord

# Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
#     param($wordToComplete, $commandAst, $cursorPosition)
#     [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
#     $Local:word = $wordToComplete.Replace('"', '""')
#     $Local:ast = $commandAst.ToString().Replace('"', '""')
#     winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
#     [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
#     }
# }

# -------------------------------------------------------------------------------------------------
# Remove Aliases
# Windows Built in Aliases , We need to Use Unix Counter part
Remove-Item alias:gl -Force
Remove-Item alias:rp -Force

# -------------------------------------------------------------------------------------------------
# Fuzzy Finder Commands
# function Ccd () {
# 	Set-Location (Set-Location (Get-ChildItem . -Recurse | Where-Object { $_.PSIsContainer } | Invoke-Fzf))
# }
if ($PSVersionTable.PSVersion.Major -gt 5){
function ll { Get-ChildItem -Path (Get-Location) | Format-Table -View childrenWithHardLink }
}
function cwd(){Convert-Path . | clip.exe}

#function p{fzf --preview 'bat --style=numbers --color=always --line-range :500 {}'}
# Start Port Killer
function Find-Port(){
	netstat -ano | findstr :$args
}
function Invoke-Kill(){
	taskkill /PID $args /F
}
# End Port Killer
# -------------------------------------------------------------------------------------------------
# UNIX Commands
function rf($filepath) { Remove-Item -Path $filepath -Recurse -Force -ErrorAction SilentlyContinue -Confirm }
function l { Get-ChildItem -Path (Get-Location) }
function c {Clear-Host}

function ls { Get-ChildItem -Path (Get-Location) -ReadOnly}
## define all functions less than 6

function la { Get-ChildItem -Path (Get-Location) -Name}
function lc {Get-ChildItem -Path Cert:\* -Recurse -CodeSigningCert}
function pkill($name) { get-process $name -ErrorAction SilentlyContinue | stop-process }
function pgrep { get-process $args }
# Should really be name=value like Unix version of export but not a big deal
function export($name, $value) {
	set-item -force -path "env:$name" -value $value;
}

function dot(){
	git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $args
}

# Like Unix touch, creates new files and updates time on old ones
# PSCX has a touch, but it doesn't make empty files
function touch($file) {
	if ( Test-Path $file ) {
		Set-FileTime $file
	}
 else {
		New-Item $file -type file
	}
}

# From https://stackoverflow.com/questions/894430/creating-hard-and-soft-links-using-powershell
function New-Link($target, $link) {
	New-Item -ItemType SymbolicLink -Path $link -Value $target
}

function New-HardLink($target, $link) {
	New-Item -ItemType HardLink -Path $link -Value $target
}

# http://stackoverflow.com/questions/39148304/fuser-equivalent-in-powershell/39148540#39148540
function fuser($relativeFile) {
	$file = Resolve-Path $relativeFile
	write-output "Looking for processes using $file"
	foreach ( $Process in (Get-Process)) {
		foreach ( $Module in $Process.Modules) {
			if ( $Module.FileName -like "$file*" ) {
				$Process | select-object id, path
			}
		}
	}
}
function df { get-volume }
# Like a recursive sed
function Edit-Recursive($filePattern, $find, $replace) {
	$files = get-childitem . "$filePattern" -rec # -Exclude
	write-output $files
	foreach ($file in $files) {
		(Get-Content $file.PSPath) |
		Foreach-Object { $_ -replace "$find", "$replace" } |
		Set-Content $file.PSPath
	}
}
function Find-File($name) {
	get-childitem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | foreach-object {
		write-output($PSItem.FullName)
	}
}
function Get-Links($dir) {
	get-childitem $dir | where-object { $_.LinkType } | select-object FullName, LinkType, Target
}
function which() {
	Get-Command $args | Select-Object -ExpandProperty Definition
}
function reboot {
	shutdown /r /t 0
}
# Windows Path Shortcut CMD
function Add-Path {
	param(
		[string]$Dir
	)
	if ( !(Test-Path $Dir) ) {
		Write-warning "Supplied directory was not found!"
		return
	}
	$PATH = [Environment]::GetEnvironmentVariable("PATH", "User")
	if ( $PATH -notlike "*" + $Dir + "*" ) {
		[Environment]::SetEnvironmentVariable("PATH", "$PATH;$Dir", "User")
	}
}

function Get-Path {
	$env:path.split(";")
}
# -------------------------------------------------------------------------------------------------
# Git Commands
# Show Git Status
function ss { git status }
# ignores paths you removed from your working tree.
function ga { git add --ignore-removal . }
# Stages everything, without Deleted Files
function gaa { git add . }
# Stages Everything
function gaA { git add -A }
# Stages only Modified Files
function gam { git add -u }
# Show git log of a specific commit
function gs { git show $args }
# Beautiful Git Log
function gl { git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)' --all }
#Show list of commits
function gL { git log --all --decorate --oneline --graph }
# Show only file names in commits
function glf { git log --graph --oneline --name-only }
# Show full commits
function glF { git log -p }
# Remove File From Git Versioning but file still available Locally
function grm { git rm --cached $args }
# Remove All Changes
function nah { git reset --hard; git clean -df }
function Add-Tag { git tag -a -f $args }
function Remove-Tag-Remote { git push --delete origin $args }
function Remove-Tag-Local { git tag -d $args }
function Push-Tag { git push origin --tags --force }
function Add-Wip { "git add . && git commit -m 'wip'" }
function mp4{yt-dlp.exe -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4' $args}
function mp3{yt-dlp.exe -x --audio-format mp3 --audio-quality 0 $args}
# -------------------------------------------------------------------------------------------------
# Laravel Commands
#function Invoke-Tinker-Command { php artisan tinker }
#function Invoke-Artisan-Command { php artisan $args }
#function Invoke-Fresh-Command { php artisan migrate:fresh --seed }
#function Invoke-Phpunit { .\vendor\bin\phpunit $args }
function Update-FlutterSDK { pub global run fvm:main use $args}
function Get-Netlify-Config { code $env:appdata\netlify\Config\config.json}
function Get-Profiles {$PROFILE | Select-Object *Host* | Format-List}

function Invoke-Reload-Profile {
	.$Profile
}
# -------------------------------------------------------------------------------------------------
# Add All Alias to Commands Shortcuts
set-alias ln New-Link
set-alias rp Invoke-Reload-Profile
# set-alias -Name j -Value jrnl.exe -Option AllScope
set-alias -Name tag -Value Add-Tag -Option AllScope
set-alias -Name ptag -Value Push-Tag -Option AllScope
#Set-Alias -Name fresh -Value Invoke-Fresh-Command -Option AllScope
Set-Alias -Name wip -Value Add-Wip -Option AllScope
#Set-Alias -Name tinker -Value Invoke-Tinker-Command -Option AllScope
#Set-Alias -Name sdk -Value Update-FlutterSDK -Option AllScope
#Set-Alias -Name t -Value Invoke-Phpunit -Option AllScope
#Set-Alias -Name f -Value flutter.exe -Option AllScope
#Set-Alias -Name d -Value dart.exe -Option AllScope
set-alias -Name vim -Value nvim -Option AllScope
# -------------------------------------------------------------------------------------------------
# Directories Functions that will be Alias
#function Set-Path-www { Set-Location -Path $env:USERPROFILE\www }
#function Set-Path-App { Set-Location -Path $env:USERPROFILE\App }
function Set-Path-Home { Set-Location -Path $env:USERPROFILE }
function Set-Path-Win32 { Set-Location -Path $env:windir\System32 }
function Get-Back-OneDIR { Set-Location -Path ../ }
function Get-Back-TwoDIR { Set-Location -Path ../../ }
function Get-Back-ThreeDIR { Set-Location -Path ../../../ }
function Get-Back-FourDIR { Set-Location -Path ../../../../ }
function Set-Path-Workspace { Set-Location -Path $env:USERPROFILE\.workspace}
# Directory Aliases
#Set-Alias -Name www -Value Set-Path-www -Option AllScope
Set-Alias -Name sws -Value Set-Path-Workspace -Option AllScope
#Set-Alias -Name app -Value Set-Path-App -Option AllScope
Set-Alias -Name h -Value Set-Path-Home -Option AllScope
Set-Alias -Name '..' -Value Get-Back-OneDIR -Option AllScope
Set-Alias -Name '..2' -Value Get-Back-TwoDIR -Option AllScope
Set-Alias -Name '..3' -Value Get-Back-ThreeDIR -Option AllScope
Set-Alias -Name '..4' -Value Get-Back-FourDIR -Option AllScope
Set-Alias -Name w32 -Value Set-Path-Win32 -Option AllScope
# -------------------------------------------------------------------------------------------------
# Config for Openning Setting and Config in VSCODIUM
function Open-VSCodium-Keys { code $env:appdata\VSCodium\User\keybindings.json }
function Open-VSCodium-Settings { code $env:appdata\VSCodium\User\settings.json }
# Config for Openning Settings and Config in VSCODE
function Open-VSCode-Workspace($name){code"$env:USERPROFILE\.workspace\${name}.code-workspace"}
function Open-VSCode-Keys { code $env:appdata\Code\User\keybindings.json }
function Open-VSCode-Settings { code $env:appdata\Code\User\settings.json }
# Other Config
function Open-Vim-Config { code $env:LOCALAPPDATA\nvim\init.vim }
function Open-Alacritty-Config { code $env:appdata\alacritty\alacritty.yml }
function Open-Etc-Host { code $env:windir\System32\Drivers\etc\hosts }
function Open-Profile { code $profile}
#function Export-Firestore { gcloud beta firestore export --collection-ids=$args}


# Config Aliases
Set-Alias -Name cfv -Value Open-Vim-Config -Option AllScope
Set-Alias -Name cfvs -Value Open-VSCode-Settings -Option AllScope
Set-Alias -Name cfk -Value Open-VSCode-Keys -Option AllScope
Set-Alias -Name etc -Value Open-Etc-Hosts -Option AllScope
Set-Alias -Name pro -Value Open-Profile -Option AllScope
Set-Alias -Name nc -Value Get-Netlify-Config -Option AllScope
Set-Alias -Name cfa -Value Open-Alacritty-Config -Option AllScope
Set-Alias -Name e -Value explorer.exe -Option AllScope
Set-Alias -Name ws -Value Open-VSCode-Workspace -Option AllScope

# Fuzzy finder alias
#Set-Alias -Name fkill -Value Invoke-FuzzyKillProcess -Option AllScope
# Install-Module ZLocation -Scope CurrentUser
#Set-Alias -Name fz -Value Invoke-FuzzyZLocation -Option AllScope
#Set-Alias -Name fgs -Value Invoke-FuzzyGitStatus -Option AllScope
#Set-Alias -Name fh -Value Invoke-FuzzyHistory -Option AllScope
#Set-Alias -Name fd -Value Invoke-FuzzySetLocation -Option AllScope

# -------------------------------------------------------------------------------------------------
# Beautify our terminal
Invoke-Expression (&starship init powershell)
# FNM Node Js
fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
Invoke-Expression (& {
    $hook = if ($PSVersionTable.PSVersion.Major -lt 6) { 'prompt' } else { 'pwd' }
    (zoxide init --hook $hook powershell) -join "`n"
})
# Enable MenuComplete on Tab
# https://docs.microsoft.com/en-us/powershell/module/psreadline/about/about_psreadline?view=powershell-7.2#basic-editing-functions
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
# Set-PSReadLineKeyHandler -Chord Ctrl+e -ViMode Insert -ScriptBlock {
# }
