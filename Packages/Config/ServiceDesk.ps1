<#
	.NOTES
	===========================================================================
	 Created on:   	24/03/2020
	 Created by:   	Cloud - Automation Team
	 Organization: 	Stefanini
	===========================================================================
	.DESCRIPTION
        Este arquivo tem como objetivo criar diversos métodos e funções para serem utilizados nos demais scripts do Service Desk.		
#>


# Cria um objeto chamado ServiceDesk
$ServiceDesk = New-Object psobject
    
# Função LOGEND
$ServiceDesk | Add-Member -MemberType ScriptMethod -Name "_LOGEND" -Value {
        
    $produto = $args[0]
    $pacote = $args[1]
    $inicio = $args[2]
    $historico = $args[3]
    $status = $args[4]

    $Usuario = $env:USERNAME
    if (!($Usuario)) { $Usuario = C:\Windows\System32\cmd.exe /c echo %USERNAME% }
    $equipamento = $env:COMPUTERNAME

    if($status -ne "Falha") {
        $status = "Sucesso"
        $status
    } else {
        $OutputPDQ = 'C:\WINDOWS\AdminArsenal\PDQDeployRunner\service-1\output'
        $historico | Out-File -FilePath $OutputPDQ -Force -Append
    }

} -PassThru


# Função COPYALL
$ServiceDesk | Add-Member -MemberType ScriptMethod -Name "_COPYALL" -Value {

    $caminho_scripts = $args[0]
    $Local   = $args[1]
    $Destino = $args[2]
    
    if (Test-Path -Path 'C:\WINDOWS\System32\Robocopy.exe') {
        # Procura o Robocopy no diretório C:\Windows\System32.
        $Robocopy = 'C:\WINDOWS\System32\Robocopy.exe'
    }
    elseif (Test-Path -Path 'C:\WINDOWS\Robocopy.exe') {
        # Procura o Robocopy no diretório C:\Windows.
        $Robocopy = 'C:\WINDOWS\Robocopy.exe'
    }
    elseif (Test-Path -Path 'C:\Windows\SysWOW64\Robocopy.exe') {
        # Procura o Robocopy no diretório C:\Windows\SysWOW64.
        $Robocopy = 'C:\Windows\SysWOW64\Robocopy.exe'
    }
    else {
        # Procura o Robocopy no diretório C:\Windows e seus subdiretórios.
        $Robocopy = (Get-ChildItem -Recurse C:\Windows -Filter "Robocopy.exe" -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
        if (!($Robocopy)) {
            # Caso o Robocopy não exista em nenhum dos locais anteriores, copia o mesmo do servidor para a estação
            Copy-Item -Path "$caminho_scripts\Robocopy.exe" -Destination 'C:\WINDOWS\System32\Robocopy.exe' -Force
            $Robocopy = 'C:\WINDOWS\System32\Robocopy.exe'
        }
    }
    
    # Executa o comando de cópia
    Invoke-Expression "C:\Windows\System32\cmd.exe /c '$Robocopy' '$Local' '$Destino' * /E /Z"
            
} -PassThru

# Função COPYFILE
$ServiceDesk | Add-Member -MemberType ScriptMethod -Name "_COPYFILE" -Value {

    $caminho_scripts = $args[0]
    $Local   = $args[1]
    $Destino = $args[2]
    $Arquivo = $Local | Split-Path -Leaf
	$Local   = $Local | Split-Path -Parent
	
    if (Test-Path -Path 'C:\WINDOWS\System32\Robocopy.exe') {
        # Procura o Robocopy no diretório C:\Windows\System32.
        $Robocopy = 'C:\WINDOWS\System32\Robocopy.exe'
    }
    elseif (Test-Path -Path 'C:\WINDOWS\Robocopy.exe') {
        # Procura o Robocopy no diretório C:\Windows.
        $Robocopy = 'C:\WINDOWS\Robocopy.exe'
    }
    elseif (Test-Path -Path 'C:\Windows\SysWOW64\Robocopy.exe') {
        # Procura o Robocopy no diretório C:\Windows\SysWOW64.
        $Robocopy = 'C:\Windows\SysWOW64\Robocopy.exe'
    }
    else {
        # Procura o Robocopy no diretório C:\Windows e seus subdiretórios.
        $Robocopy = (Get-ChildItem -Recurse 'C:\Windows' -Filter "Robocopy.exe" -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
        if (!($Robocopy)) {
            # Caso o Robocopy não exista em nenhum dos locais anteriores, copia o mesmo do servidor para a estação
            Copy-Item -Path "$caminho_scripts\Robocopy.exe" -Destination 'C:\WINDOWS\System32\Robocopy.exe' -Force
            $Robocopy = 'C:\WINDOWS\System32\Robocopy.exe'
        }
    }

	# Encerra o processo com o mesmo nome de arquivo para evitar corrompimentos.
	if ([System.IO.Path]::HasExtension($Arquivo)) {
        $Processo = [System.IO.Path]::GetFileNameWithoutExtension($Arquivo)
        Get-Process -Name $Processo -ErrorAction SilentlyContinue | Stop-Process -Force
    }
	Get-Process -Name msiexec -ErrorAction SilentlyContinue | Stop-Process -Force
	
	# Executa o comando de cópia.
    Invoke-Expression "C:\Windows\System32\cmd.exe /C '$Robocopy' '$Local' '$Destino' '$Arquivo' /Z" | Out-Null
         
} -PassThru

# Função GETHASH
$ServiceDesk | Add-Member -MemberType ScriptMethod -Name "_GETHASH" -Value {

    $Arquivo = $args[0]
    
    # Define o algoritmo.
    $Algoritimo = 'SHA256'

    # Cria um objeto com os dados do arquivo especificado.
    $FileInfo = [System.IO.File]::OpenRead($Arquivo)

    # Cria um objeto de concatenação de strings.
    $StringBuilder = New-Object System.Text.StringBuilder

    # Faz o processamento e concatenação dos valores obtidos.
    [System.Security.Cryptography.HashAlgorithm]::Create($Algoritimo).ComputeHash($FileInfo)|%{[Void]$StringBuilder.Append($_.ToString('x2'))}

    # Encerra a abertura do arquivo especificado.
    $FileInfo.Close()

    # Obtém o valor gerado pela concatenação do StringBuilder com os caractéres maiúsculos.
    $hash = ($StringBuilder.ToString()).ToUpper()

    Return $hash

} -PassThru

# Função GETPROGRAM
$ServiceDesk | Add-Member -MemberType ScriptMethod -Name "_GETPROGRAM" -Value {
    
    $Programa = $args[0]
    $Op = $args[1]

    $UNINSTALL_PATHS = @( 
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 
        'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    )

    foreach ($UNINSTALL in $UNINSTALL_PATHS) {
        if (Test-Path -Path $UNINSTALL) {
            $SubKeys = Get-ItemProperty -Path "$UNINSTALL\*" -Exclude "nbi-nb-base-8.2.0.0.201609300101"
            foreach ($SubKey in $SubKeys) {
                if ($SubKey.DisplayName -like "*$Programa*") {
                
                    $Name = $SubKey.DisplayName
                    $Key = $SubKey.PSChildName
                    $UString = $SubKey.UninstallString
                    $QString = $SubKey.QuietUninstallString

                    if ($Op -eq 'Key') {
                        if ($Key.StartsWith('{') -and !$Key.Contains('_')) {
                            $Key
                        }
                    } elseif ($Op -eq 'UString') {
                        $UString
                    } elseif ($Op -eq 'QString') {
                        $QString
                    } else {
                        $Name
                    }
                }
            }
        }
    }
} -PassThru

# Função UNZIP
$ServiceDesk | Add-Member -MemberType ScriptMethod -Name "_UNZIP" -Value {
	
	$ZipFile = $args[0]
	$OutPath = $args[1]
	
	Add-Type -AssemblyName System.IO.Compression.FileSystem
	[System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $OutPath)
	Start-Sleep -Seconds 1
} -PassThru

# Função UNBLOCKFILE
Function _UNBLOCKFILE
{
	
	[cmdletbinding(DefaultParameterSetName = "ByName", SupportsShouldProcess = $True)]
	param (
		[parameter(Mandatory = $true, ParameterSetName = "ByName", Position = 0)]
		[string]$FilePath,
		[parameter(Mandatory = $true, ParameterSetName = "ByInput", ValueFromPipeline = $true)]
		$InputObject
	)
	begin
	{
		Add-Type -Namespace Win32 -Name PInvoke -MemberDefinition @"
        // http://msdn.microsoft.com/en-us/library/windows/desktop/aa363915(v=vs.85).aspx
        [DllImport("kernel32", CharSet = CharSet.Unicode, SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool DeleteFile(string name);
        public static int Win32DeleteFile(string filePath) {
            bool is_gone = DeleteFile(filePath); return Marshal.GetLastWin32Error();}
 
        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        static extern int GetFileAttributes(string lpFileName);
        public static bool Win32FileExists(string filePath) {return GetFileAttributes(filePath) != -1;}
"@
	}
	process
	{
		switch ($PSCmdlet.ParameterSetName)
		{
			'ByName'  { $input_paths = Resolve-Path -Path $FilePath | ? { [IO.File]::Exists($_.Path) } | Select -Exp Path }
			'ByInput' { if ($InputObject -is [System.IO.FileInfo]) { $input_paths = $InputObject.FullName } }
		}
		$input_paths | % {
			if ([Win32.PInvoke]::Win32FileExists($_ + ':Zone.Identifier'))
			{
				if ($PSCmdlet.ShouldProcess($_))
				{
					$result_code = [Win32.PInvoke]::Win32DeleteFile($_ + ':Zone.Identifier')
					if ([Win32.PInvoke]::Win32FileExists($_ + ':Zone.Identifier'))
					{
						Write-Error ("Failed to unblock '{0}' the Win32 return code is '{1}'." -f $_, $result_code)
					}
				}
			}
		}
	}
}


# Função GetIniContent
$ServiceDesk | Add-Member -MemberType ScriptMethod -Name "_GETINICONTENT" -Value {
    
    $FilePath = $args[0]

    $ini = @{}
    switch -regex -file $FilePath
    {
        “^\[(.+)\]” # Section
        {
            $section = $matches[1]
            $ini[$section] = @{}
            $CommentCount = 0
        }
        “^(;.*)$” # Comment
        {
            $value = $matches[1]
            $CommentCount = $CommentCount + 1
            $name = “Comment” + $CommentCount
            $ini[$section][$name] = $value
        }
        “(.+?)\s*=(.*)” # Key
        {
            $name,$value = $matches[1..2]
            $ini[$section][$name] = $value.trim()
        }
    }
    return $ini

} -PassThru

# Cria o método de ajuda, explicando todos os outros métodos
$ServiceDesk | Add-Member -MemberType ScriptMethod -Name "_Help" -Value {

    # Cria um array para 
    $help = @()
    

    # Insere a descrição da função Log final
    $object = New-Object -TypeName PSObject
    $object | Add-Member -Name 'Method' -MemberType Noteproperty -Value '_LOGEND()'
    $object | Add-Member -Name 'Sintax' -MemberType Noteproperty -Value '$ServiceDesk._LOGSTART("produto_string", "pacote_string", "date/time_inicial", "status_string")'
    $object | Add-Member -Name 'Description' -MemberType Noteproperty -Value 'Escreve informações finais pra saída no PDQ.'
    $help += $object

    # Insere a descrição da função _COPYALL
    $object = New-Object -TypeName PSObject
    $object | Add-Member -Name 'Method' -MemberType Noteproperty -Value '_COPYALL()'
    $object | Add-Member -Name 'Sintax' -MemberType Noteproperty -Value '$ServiceDesk._COPYALL("UNC_string","pasta_origem_string","pasta_destino_string")'
    $object | Add-Member -Name 'Description' -MemberType Noteproperty -Value 'Utiliza o ROBOCOPY para copiar todos os arquivos de uma pasta para outra.'
    $help += $object

    # Insere a descrição da função _COPYFILE
    $object = New-Object -TypeName PSObject
    $object | Add-Member -Name 'Method' -MemberType Noteproperty -Value '_COPYFILE()'
    $object | Add-Member -Name 'Sintax' -MemberType Noteproperty -Value '$ServiceDesk._COPYALL("UNC_server","pasta_origem_string","pasta_destino_string", "nome_arquivo_string")'
    $object | Add-Member -Name 'Description' -MemberType Noteproperty -Value 'Utiliza o ROBOCOPY para copiar um arquivo de uma pasta para outra.'
    $help += $object

    # Insere a descrição da função _GETHASH
    $object = New-Object -TypeName PSObject
    $object | Add-Member -Name 'Method' -MemberType Noteproperty -Value '_GETHASH()'
    $object | Add-Member -Name 'Sintax' -MemberType Noteproperty -Value '$ServiceDesk._GETHASH("caminho_arquivo_string")'
    $object | Add-Member -Name 'Description' -MemberType Noteproperty -Value 'Busca a HASH de um arquivo.'
    $help += $object

    # Insere a descrição da função GETPROGRAM
    $object = New-Object -TypeName PSObject
    $object | Add-Member -Name 'Method' -MemberType Noteproperty -Value '_GETPROGRAM()'
    $object | Add-Member -Name 'Sintax' -MemberType Noteproperty -Value '$ServiceDesk._GETPROGRAM()'
    $object | Add-Member -Name 'Description' -MemberType Noteproperty -Value 'Verifica se um programa está instalado.'
    $help += $object

    # Insere a descrição da função UNZIP
    $object = New-Object -TypeName PSObject
    $object | Add-Member -Name 'Method' -MemberType Noteproperty -Value '_UNZIP()'
    $object | Add-Member -Name 'Sintax' -MemberType Noteproperty -Value '$ServiceDesk._UNZIP()'
    $object | Add-Member -Name 'Description' -MemberType Noteproperty -Value 'Extraí arquivos zipados.'
    $help += $object

    # Exibe a ajuda do método. Caso não seja passado parâmetro, exibe todos, senão exibe somente o desejado.
    if (!$args[0]) {
        $help | Format-Table
    } else {
        $a = $args[0]
        $help | Where-Object {$_.Method -like "*$a*"} | Format-Table
    }
} -PassThru