<#
	.NOTES
	===========================================================================
	 Created on:   	31/03/2020
	 Created by:   	Automation Team
	 Organization: 	Stefanini
	===========================================================================
	.DESCRIPTION
		Script para restauração das aplicações nativas do Windows (Barra de tarefas, Menu Iniciar, Windows Search, Explorer e Calculadora).
    .UPDATES
        00/00/2020 - #################
#>

# Carrega o arquivo de configuração.
$caminho_scripts = "C:\Windows\AdminArsenal\PDQDeployRunner\service-1\exec"
."$caminho_scripts\ServiceDesk.ps1" | Out-Null

# Define a data e hora de início, produto selecionado e o tipo de pacote relacionado ao produto.
$inicio = Get-Date
$produto = 'Restaurar Apps'
$pacote = 'Configuração'

# Inicia o processo de log.
$historico = "Iniciando procedimentos..."

# Inicia o serviço do firewall e configura para inicializar automaticamente
$historico = "Iniciando serviço de FIREWALL..."
if (Get-Service -Name MpsSvc) {
    Set-Service -Name MpsSvc -StartupType Automatic -ErrorAction SilentlyContinue | Out-Null
    Start-Service -Name MpsSvc -ErrorAction SilentlyContinue | Out-Null

    if ((Get-Service -Name MpsSvc).Status -eq 'Running') {
		# OK
    } else {
        $historico = "ERRO - Não foi possível iniciar o serviço de FIREWALL."
    }
} else {
    $historico = "ERRO - Serviço de FIREWALL não instalado."
}

# Obtém os pacotes de aplicativos instalados atualmente e faz um novo registro no sistema para cada um deles
$historico = "Restaurando aplicações nativas..."
Get-AppXPackage -AllUsers | Foreach { Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -ErrorAction SilentlyContinue } | Out-Null

Try {
    # Habilita o Controle de Acesso ao Usuário (UAC)
    $historico = "Configurando Controle de Acesso de Usuário (UAC)..."
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA -Value 1 -ErrorAction Stop
}
Catch {
    $STATUS = "Falha"
    $historico = "ERRO - Não foi possível configurar o controle de acesso de usuário."
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