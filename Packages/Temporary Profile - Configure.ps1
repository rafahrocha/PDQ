<#
	.NOTES
	===========================================================================
	 Created on:   	31/03/2020
	 Created by:   	Automation Team
	 Organization: 	Stefanini
	===========================================================================
	.DESCRIPTION
		Script para correção de perfil temporário.
    .UPDATES
        00/00/2020 - #################
#>

# Carrega o arquivo de configuração.
$caminho_scripts = "C:\Windows\AdminArsenal\PDQDeployRunner\service-1\exec"
."$caminho_scripts\ServiceDesk.ps1" | Out-Null

# Define a data e hora de início, produto selecionado e o tipo de pacote relacionado ao produto.
$inicio = Get-Date
$produto = 'Perfil Temporário'
$pacote = 'Configuração'

# Inicia o processo de log.
$historico = "Iniciando procedimentos..."

if ($STATUS -ne 'Falha') {
    # Verifica se existem perfis temporários.
    $historico = "Verificando a existência de perfis temporários..."
    $historico

    $AllProfiles = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -Name
    Try {
        if (!($AllProfiles -match '.bak')) {
            Throw
        }
    }
    Catch {
        $STATUS = 'Falha'
        $historico = "ERRO - Não existem perfis temporários."
    }
}

if ($STATUS -ne 'Falha') {
    Try {
        # Obtém a lista de perfis não temporários.
        $historico = "Comparando perfis..."
        $historico

        $Profiles = $AllProfiles -notlike "*.bak"
        foreach ($A in $AllProfiles) {
            if (!($Profiles -match $A)) {
                [System.Array]$Edit += $A
            }
        }

        # Realiza a contagem de perfis temporários encontrados e configura os perfis.
        $Count = $Edit.Count
        if ($Count -gt 1){
            $historico = "Foram encontrados $Count perfis temporários!"
            $historico

            $historico = "Configurando perfis..."
            $historico
        } else {
            $historico = "Foi encontrado $Count perfil temporário!"
            $historico

            $historico = "Configurando perfil..."
            $historico
        }

        foreach ($E in $Edit) {
            $Folder = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$E").ProfileImagePath

            # Se a pasta de usuário existir, excluí o perfil temporário e renomeia o perfil .bak.
            if (Test-Path -Path $Folder) {

                if ($Folder -match $env:USERDOMAIN) {
                    Throw
                } else {
                    $PTemp = [System.IO.Path]::GetFileNameWithoutExtension($E)
                    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$PTemp" -Recurse -Force
                    Start-Sleep -Milliseconds 200
                    Rename-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$E" -NewName $PTemp -Force
                    Start-Sleep -Milliseconds 200
                }
            } else {
                # Se a pasta não existir, excluí os dois registros.
                $PTemp = [System.IO.Path]::GetFileNameWithoutExtension($E)
                Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$E" -Recurse -Force
                Start-Sleep -Milliseconds 200
                Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$PTemp" -Recurse -Force
                Start-Sleep -Milliseconds 200
            }
        }
    }
    Catch {
        $STATUS = 'Falha'
        $historico = "ERRO - Não é possível efetuar a configuração."
    }
}

# Identifica se houve sucesso no processo.
if ($STATUS -ne "Falha") {
    
    $historico = "Procedimento finalizado com sucesso."

    # Termina o processo de log.
    $ServiceDesk._LOGEND($produto, $pacote, $inicio, $historico, $STATUS)
    Start-Sleep -Milliseconds 200

    # Reinicia o computador com status de correção de segurança (planejada).
    Start-Process -FilePath 'C:\Windows\System32\shutdown.exe' -ArgumentList '/r /t 5 /f /d p:2:18' -Wait
} else {

    # Termina o processo de log.
    $ServiceDesk._LOGEND($produto, $pacote, $inicio, $historico, $STATUS)
    Exit 1
}