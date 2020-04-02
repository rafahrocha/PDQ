<#
	.NOTES
	===========================================================================
	 Created on:   	30/03/2020
	 Created by:   	Automation Team
	 Organization: 	Stefanini
	===========================================================================
	.DESCRIPTION
		Script para desinstalação do Google Chrome.
    .UPDATES
        00/00/2020 - #################
#>

# Carrega o arquivo de configuração.
$caminho_scripts = "C:\Windows\AdminArsenal\PDQDeployRunner\service-1\exec"
."$caminho_scripts\ServiceDesk.ps1" | Out-Null

# Define a data e hora de início, produto selecionado e o tipo de pacote relacionado ao produto.
$inicio = Get-Date
$produto = 'Google Chrome'
$pacote = 'Desinstalação'

# Inicia o processo de log.
$historico = "Iniciando procedimentos..."

if ($STATUS -ne "Falha")
{
    Try {
        # Verifica se existem versões anteriores instaladas
        $historico = "Verificando instalações anteriores..."
        
        $Key = $ServiceDesk._GETPROGRAM('Google Chrome','Key')
        if ($Key) {

            # Verifica se existem versões anteriores instaladas
            $historico = "Removendo arquivos antigos..."

            # Finaliza os processos do Chrome e instalação
            Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue
            Stop-Process -Name msiexec -Force -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 200

            foreach ($K in $Key) {
                Start-Process -FilePath 'C:\Windows\system32\msiexec.exe' -ArgumentList "/fa $Key /qn" -Wait
                Start-Process -FilePath 'C:\Windows\System32\msiexec.exe' -ArgumentList "/x $Key /qn" -Wait
            }
        
            $Users = (Get-ChildItem -Path 'C:\Users').Name
            foreach ($U in $Users) {
                Remove-Item -Path "C:\Users\$U\AppData\Local\Google" -Force -Recurse -ErrorAction SilentlyContinue
            }
        } else {
            Throw
        }
    }
    Catch {
        $STATUS = 'Falha'
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