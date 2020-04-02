﻿<#
	.NOTES
	===========================================================================
	 Created on:   	31/03/2020
	 Created by:   	Automation Team
	 Organization: 	Stefanini
	===========================================================================
	.DESCRIPTION
		Script para instalação do Firefox.
    .UPDATES
        00/00/2020 - #################
#>

# Carrega o arquivo de configuração.
$caminho_scripts = "C:\Windows\AdminArsenal\PDQDeployRunner\service-1\exec"
."$caminho_scripts\ServiceDesk.ps1" | Out-Null

# Define a data e hora de início, produto selecionado e o tipo de pacote relacionado ao produto.
$inicio = Get-Date
$produto = 'Mozilla Firefox'
$pacote = 'Instalação'

<#
# Define o nome do(s) arquivo(s) para download.
$Files = @"
    'Firefox60.0.2ESR_R001.exe'
"@ -replace '\n' -replace '    '
#>

# Busca o caminho dos arquivos no arquivo *.ini.
$IniFile = "$caminho_scripts\Mozilla Firefox - Install.ini"
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

if ($STATUS -ne 'Falha') {
    # Inicia o processo de desinstalação.
    $historico = "Buscando Instalações do Firerox..."

    Try {
        $Key = $ServiceDesk._GETPROGRAM('Mozilla Firefox','UString')
        if ($Key) {
            foreach ($K in $Key) {
                # Inicia o processo de desinstalação.
                $historico = "Desinstalando o Firefox..."
                if (Get-Process -Name 'firefox' -ErrorAction SilentlyContinue) {Stop-Process -Name 'firefox' -Force -ErrorAction SilentlyContinue}
                if (Get-Process -Name 'msiexec' -ErrorAction SilentlyContinue) {Stop-Process -Name 'msiexec' -Force -ErrorAction SilentlyContinue}
                Start-Process -FilePath $K -ArgumentList "/S" -Wait
            }

            # Verifica se o programa/sistema foi desinstalado.
            $Key = $ServiceDesk._GETPROGRAM('Mozilla Firefox')
            if ($Key) {               
                $historico = "ERRO - Não foi possível desinstalar a versão atual do Firefox."
            }
        } else {
            Throw
        }
    }
    Catch {
        $historico = "O Firerox não está instalado na estação."
    }
}

if ($STATUS -ne 'Falha')
{
    # Inicia o processo de instalação.
    $historico = "Instalando $FileName0..."

    Try {
        Start-Process -FilePath "C:\Temp\ServiceDesk\$produto\$FileName0" -ArgumentList '/S /Force' -Wait
        
        if (!($ServiceDesk._GETPROGRAM('Mozilla Firefox'))) {
            Throw
        }
    }
    Catch {
        $STATUS = "Falha"
        $historico = "ERRO - Não foi possível realizar a instalação."
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