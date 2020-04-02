<#
	.NOTES
	===========================================================================
	 Created on:   	31/03/2020
	 Created by:   	Automation Team
	 Organization: 	Stefanini
	===========================================================================
	.DESCRIPTION
		Script para desinstalação do RStudio.
    .UPDATES
        00/00/2020 - #################
#>

# Carrega o arquivo de configuração.
$caminho_scripts = "C:\Windows\AdminArsenal\PDQDeployRunner\service-1\exec"
."$caminho_scripts\ServiceDesk.ps1" | Out-Null

# Define a data e hora de início, produto selecionado e o tipo de pacote relacionado ao produto.
$inicio = Get-Date
$produto = 'RStudio'
$pacote = 'Desinstalação'

# Inicia o processo de log.
$historico = "Iniciando procedimentos..."

if ($STATUS -ne 'Falha') {
    # Inicia o processo de desinstalação.
    $historico = "Buscando $produto..."

    Try {
        $Key = $ServiceDesk._GETPROGRAM('RStudio','UString')
        if ($Key) {
            foreach ($K in $Key) {
                # Inicia o processo de desinstalação.
                $historico = "Desinstalando $produto..."

                if (Get-Process -Name 'msiexec' -ErrorAction SilentlyContinue) {Stop-Process -Name 'msiexec' -Force -ErrorAction SilentlyContinue}
                Start-Process -FilePath "$K" -ArgumentList "/S" -Wait
            }

            # Verifica se o programa/sistema foi desinstalado.
            $Key = $ServiceDesk._GETPROGRAM('RStudio')
            if ($Key) {
                $STATUS = "Falha"
                $historico = "ERRO - Não foi possível desinstalar o $produto."
            }
        } else {
            Throw
        }
    }
    Catch {
        $STATUS = "Falha"
        $historico = "Uninstall_ERROR - O $produto não está instalado."
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