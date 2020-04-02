<#
	.NOTES
	===========================================================================
	 Created on:   	01/04/2020
	 Created by:   	Automation Team
	 Organization: 	Stefanini
	===========================================================================
	.DESCRIPTION
		Script para instalação do Java-JRE-8.
    .UPDATES
        00/00/2020 - #################
#>

# Carrega o arquivo de configuração.
$caminho_scripts = "C:\Windows\AdminArsenal\PDQDeployRunner\service-1\exec"
."$caminho_scripts\ServiceDesk.ps1" | Out-Null

# Define a data e hora de início, produto selecionado e o tipo de pacote relacionado ao produto.
$inicio = Get-Date
$produto = 'Java-JRE-8'
$pacote = 'Instalação'

<#
# Define o nome do(s) arquivo(s) para download.
$Files = @"
    'jre-8u131_x86CEF_R005.exe'
"@ -replace '\n' -replace '    '
#>

# Busca o caminho dos arquivos no arquivo *.ini.
$IniFile = "$caminho_scripts\Java-JRE-8 - Install.ini"
$IniConf = $ServiceDesk._GETINICONTENT($IniFile)
$FilePath = $IniConf.Path.Values -split "`n"

# Define uma variável para cada arquivo encontrado.
foreach ($F in $FilePath) {
    if (!($C)) {
        $C = 0
    }
    Set-Variable -Name FilePath$C -Value $F -Force
    Set-Variable -Name FileName$C -Value ([System.IO.Path]::GetFileName($F).ToUpper()) -Force
    $C++
}

# Inicia o processo de log.
$historico = "Iniciando procedimentos..."

if ($STATUS -ne 'Falha')
{
    # Busca o arquivo 0 no servidor.
    $historico = "Buscando arquivo $FileName0..."

    Try {
        if (!(Test-Path -Path $FilePath0)) {
            Throw
        } else {
            
            # Copia o arquivo.
            $historico = "Copiando arquivo..."
            $ServiceDesk._COPYFILE($caminho_scripts, $FilePath0, "C:\Temp\ServiceDesk\$produto")
        }
    }
    Catch {
        $STATUS = "Falha"
        $historico = "ERRO - Não foi possível encontrar o arquivo no servidor."
    }
}

if ($STATUS -ne 'Falha')
{
    # Verifica a integridade do arquivo.
    $historico = "Verificando integridade do arquivo..."

    Try {
        # Obtém a hash do arquivo no servidor e no computador local.
        $ServerHash = $ServiceDesk._GETHASH($FilePath0)
        $LocalHash = $ServiceDesk._GETHASH("C:\Temp\ServiceDesk\$produto\$FileName0")
        
        # Compara as hashes.
        if ($ServerHash -ne $LocalHash) {
            Throw
        }
    }
    Catch {
        $STATUS = "Falha"
        $historico = "ERRO - Arquivo corrompido."
    }
}

if ($STATUS -ne 'Falha')
{
    # Desbloqueando o arquivo.
    $historico = "Desbloqueando o arquivo..."

    Try {

        $Versao = $PSVersionTable.BuildVersion.Major
        if ($Versao -eq '10'){
            Unblock-File "C:\Temp\ServiceDesk\$produto\$FileName0"
        }else{
            dir "C:\Temp\ServiceDesk\$produto\$FileName0" | _UNBLOCKFILE
        }

        # Validando o desbloqueio
        $Dir_arquivo = cmd.exe /r dir /r "C:\Temp\ServiceDesk\$produto"
        if ($Dir_arquivo -like '*:Zone.Identifier*'){
            Throw
        }
    }
    Catch {
        $STATUS = "Falha"
        $historico = "ERRO - Não foi possível desbloquear o arquivo."
    }
}

if ($STATUS -ne 'Falha')
{
    # Inicia o processo de desinstalação.
    $historico = "Desinstalando Versões anteriores..."

    Try {

        Start-Job -Name 'CloseIE' -ScriptBlock {
            While($true){
                Get-Process -Name 'iexplore' | Stop-Process -Force
                Start-Sleep -Milliseconds 100
            }
        } | Out-Null

        $UNINSTALL_PATHS = @( 
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 
            'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
        )

        foreach ($UNINSTALL in $UNINSTALL_PATHS) {
            $JavaRegs = (Get-ChildItem -Path $UNINSTALL | Where-Object -FilterScript {$_.Name -match '26A24AE4-039D-4CA4-87B4'}).Name
            foreach ($J in $JavaRegs) {
                # Define as variáveis para desinstalação.
                $Chave = "Registry::$J"
                $Path = (Get-ItemProperty -Path "Registry::$J").PSChildName

                # Finaliza os processos que podem interromper a execução.
                Get-Process -Name 'iexplore' -ErrorAction SilentlyContinue | Stop-Process -Force
                Get-Process -Name 'msiexec'  -ErrorAction SilentlyContinue | Stop-Process -Force
                Get-Process -Name 'java'     -ErrorAction SilentlyContinue | Stop-Process -Force
                Get-Process -Name 'javaw'    -ErrorAction SilentlyContinue | Stop-Process -Force
                Get-Process -Name 'javaws'   -ErrorAction SilentlyContinue | Stop-Process -Force
                Get-Process -Name 'WmiPrvSE' -ErrorAction SilentlyContinue | Stop-Process -Force
                Get-Process -Name 'msiexec'  -ErrorAction SilentlyContinue | Stop-Process -Force

                # Inicia o processo de desinstalação do Java.
                Start-Process 'C:\Windows\System32\msiexec.exe' "/x $($Path) /quiet /norestart" -Wait

                if (Test-Path -Path $Chave) {
                    Remove-Item -Path $Chave -Force -Recurse
                }
            } 
        }

        if (Test-Path -Path "C:\Windows\SysWOW64\Uninstall_J2RE7.bat"){Start-Process 'C:\Windows\SysWOW64\Uninstall_J2RE7.bat' -Wait}
        if (Test-Path -Path "C:\TEMP\Uninstall_J2RE8_x86.exe"){Start-Process 'C:\TEMP\Uninstall_J2RE8_x86.exe' -ArgumentList '/S' -Wait}

        # Limpa a variável JavaRegs.
        $JavaRegs = $null

        # Busca as chaves relacionadas ao Java.
        foreach ($UNINSTALL in $UNINSTALL_PATHS){
            $JavaRegs += (Get-ChildItem -Path $UNINSTALL | Where-Object -FilterScript {$_.Name -match '26A24AE4-039D-4CA4-87B4'}).Name
        }

        # Caso possua alguma chave, dá erro.
        if (($JavaRegs)){
            Throw
        }

    }Catch {
        $STATUS = "Falha"
        $historico = "ERRO - Não foi possível realizar a desinstalação completa do Java."
    }
}

if ($STATUS -ne 'Falha')
{
    # Inicia o processo de instalação.
    $historico = "Instalando $FileName0..."

    Try {

        Start-Process -FilePath "C:\Temp\ServiceDesk\$produto\$FileName0" -ArgumentList '/s' -Wait
        Start-Sleep -Seconds 2

        if (Test-Path "C:\Program Files\Java" -Filter 'jre1.8.0*'){
            $VerUpdate = (Get-ChildItem "C:\Program Files\Java" -Filter 'jre1.8.0*').Name.Split('_')[1]
        }elseif(Test-Path "C:\Program Files (x86)\Java" -Filter 'jre1.8.0*'){
            $VerUpdate = (Get-ChildItem "C:\Program Files (x86)\Java" -Filter 'jre1.8.0*').Name.Split('_')[1]
        }else{
            $VerUpdate = ''
        }

        if ($ServiceDesk._GETPROGRAM("Java 8 Update $VerUpdate")) {
 
            $historico = "Configurando políticas de segurança..."

            # Habilita o perfil do Firewall.
            Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled True | Out-Null

            # Remove todas as regras relacionadas ao Java;
            Remove-NetFirewallRule -DisplayName "*JAVA*" | Out-Null

            # Cria regras TCP e UDP para liberar o Java.
            New-NetFirewallRule -DisplayName "Java(TM) Platform SE binary" -Program "C:\program files (x86)\java\jre1.8.0*\bin\java.exe" -Direction Inbound -Profile Any -Action Allow -Enabled True -Protocol TCP | Out-Null
            New-NetFirewallRule -DisplayName "Java(TM) Platform SE binary" -Program "C:\program files (x86)\java\jre1.8.0*\bin\java.exe" -Direction Inbound -Profile Any -Action Allow -Enabled True -Protocol UDP | Out-Null

            # Libera todas as regras relacionadas ao Internet Explorer e Java.
            Set-NetFirewallRule -DisplayName “*Internet Explorer*","*Java*" –Enabled True -Action Allow | Out-Null

            $historico = "Associando extensão (.JAR)..."

            # Concatena variáveis e strings.
            $REGISTRY = 'Registry::'
            $HKCR = "$REGISTRY"+"HKCR"
            $HKLM = "$REGISTRY"+"HKLM"

            # Cria chaves na HKEY_CLASSES_ROOT para extensão .JAR.
            New-Item "$HKCR\.jar" -Value 'jarfile' -Force | Out-Null
            New-Item "$HKCR\jar_auto_file\shell\open\command" -Value '"C:\Program Files (x86)\Java\jre1.8.0*\bin\javaw.exe" -jar "%1" %*' -Force | Out-Null
            New-Item "$HKCR\jarfile\shell\open\command" -Value '"C:\Program Files (x86)\Java\jre1.8.0*\bin\javaw.exe" -jar "%1" %*' -Force | Out-Null

            # Cria chaves na HKEY_LOCAL_MACHINE para extensão .JAR.
            New-Item "$HKLM\SOFTWARE\Classes\.jar" -Value 'jarfile' -Force | Out-Null
            New-Item "$HKLM\SOFTWARE\Classes\jar_auto_file\shell\open\command" -Value '"C:\Program Files (x86)\Java\jre1.8.0*\bin\javaw.exe" -jar "%1" %*' -Force | Out-Null
            New-Item "$HKLM\SOFTWARE\Classes\jarfile\shell\open\command" -Value '"C:\Program Files (x86)\Java\jre1.8.0*\bin\javaw.exe" -jar "%1" %*' -Force | Out-Null

            # Busca e separa os usuários por SID;;
            $SIDS = (Get-ChildItem -Path "Registry::HKEY_USERS" | Where-Object -FilterScript {($_.Name -notlike  "*.DEFAULT") -and ($_.Name -notlike "*S-1-5-18") -and ($_.Name -notlike "*S-1-5-19") -and ($_.Name -notlike  "*S-1-5-20") -and ($_.Name -notlike  "*_Classes")} | Select-Object Name -ExpandProperty Name) -replace "HKEY_USERS\\"

            # Cria as chaves de associação do Java para cada SID.
            foreach($SID in $SIDS){
                $SID = "Registry::HKU\$SID"
    
                New-Item "$SID\SOFTWARE\Classes\.jar" -Value 'jar_auto_file' -Force | Out-Null
                New-Item "$SID\SOFTWARE\Classes\jar_auto_file\shell\open\command" -Value '"C:\Program Files (x86)\Java\jre1.8.0*\bin\javaw.exe" -jar "%1" %*' -Force | Out-Null
    
                New-Item "$SID\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jar\OpenWithList" -Force | Out-Null
                Set-ItemProperty "$SID\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jar\OpenWithList" -Name "a" -Value "javaw.exe" | Out-Null
                Set-ItemProperty "$SID\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jar\OpenWithList" -Name "MRUList" -Value "a" | Out-Null

                New-Item "$SID\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jar\OpenWithProgids" -Force | Out-Null

                New-Item "$SID\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jar\UserChoice" -Force | Out-Null
                Set-ItemProperty "$SID\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jar\UserChoice" -Name "ProgId" -Value "Applications\javaw.exe" | Out-Null
            }

            # Busca e separa as classes de usuários por SID.
            $SIDS_CLASSES = (Get-ChildItem -Path "Registry::HKEY_USERS" | Where-Object -FilterScript {($_.Name -like  "*_Classes")} | Select-Object Name -ExpandProperty Name) -replace "HKEY_USERS\\"

            # Cria as chaves de associação do Java para cada classe de SID.
            foreach($SID_CLASSES in $SIDS_CLASSES){
                $SID_CLASSES = "Registry::HKU\$SID_CLASSES"
    
                New-Item "$SID_CLASSES\.jar" -Value 'jar_auto_file' -Force | Out-Null
                New-Item "$SID_CLASSES\jar_auto_file\shell\open\command" -Value '"C:\Program Files (x86)\Java\jre1.8.0*\bin\javaw.exe" -jar "%1" %*' -Force | Out-Null
            }

            # Identifica se houve sucesso no processo de associação.
            if ($?){
                $historico = "Associação do Java para cada classe de SID realizada."
            }else{
                $historico = "ERRO - Não foi possível associar a extensão."
                Throw
            }

        }else{ 

            # Interrompe a execução caso não consiga instalar o Java.           
            $historico = "ERRO - Não foi possível instalar o JAVA."
            Throw
        }
    }
    Catch {
        $STATUS = "Falha"
        $historico = "ERRO - Não foi possível realizar a instalação/configuração do Java."
    }
}

# Identifica se houve sucesso no processo.
if ($STATUS -ne "Falha") {
    
    $historico = "Procedimento finalizado com sucesso."

    # Termina o processo de log.
    $ServiceDesk._LOGEND($produto, $pacote, $inicio, $historico, $STATUS)
    
} else {

    # Termina o processo de log.
    $ServiceDesk._LOGEND($produto, $pacote, $inicio, $historico, $STATUS)
    Exit 1
}