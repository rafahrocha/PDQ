<#
	.NOTES
	===========================================================================
	 Created on:   	31/03/2020
	 Created by:   	Automation Team
	 Organization: 	Stefanini
	===========================================================================
	.DESCRIPTION
		Script para criação e compartilhamento da pasta PUB.
    .UPDATES
        00/00/2020 - #################
#>

# Carrega o arquivo de configuração.
$caminho_scripts = "C:\Windows\AdminArsenal\PDQDeployRunner\service-1\exec"
."$caminho_scripts\ServiceDesk.ps1" | Out-Null

# Define a data e hora de início, produto selecionado e o tipo de pacote relacionado ao produto.
$inicio = Get-Date
$produto = 'Criar PUB'
$pacote = 'Configuração'

# Inicia o processo de log.
$historico = "Iniciando procedimentos..."

# Define o valor das variáveis de nome, compartilhamento e comentário referente a pasta.
$Folder   = 'C:\PUB'
$CompName = 'PUB'
$Comment  = 'Public Folder'

if ($STATUS -ne "Falha") {

    # Cria a pasta PUB
    $historico = "Criando pasta PUB..."

    Try {
        if (!(Test-Path -Path $Folder)) {
            New-Item -Path $Folder -ItemType Directory -Force | Out-Null
            
            if (!(Test-Path -Path $Folder)) {
                Throw
            }   
        }
    }
    Catch {
        $STATUS = "Falha"
        $historico = "ERRO - Não foi possível criar a pasta PUB."
    }
}

if ($STATUS -ne "Falha") {

    # Habilita o compartilhamento.
    $historico = "Habilitando compartilhamento..."

    Try {
        $trustee = ([wmiclass]'Win32_trustee').psbase.CreateInstance()
        $trustee.Domain = $null
        $trustee.Name = 'Todos'

        # Valores das máscaras de acessos.
        $fullcontrol = 2032127
        $change = 1245631
        $read = 1179785

        # Cria a lista de acesso.
        $ace = ([wmiclass]'Win32_ACE').psbase.CreateInstance()
        $ace.AccessMask = $fullcontrol
        $ace.AceFlags = 3
        $ace.AceType = 0
        $ace.Trustee = $trustee

        # Cria uma instância para setar os valores de segurança.
        $sd = ([wmiclass]'Win32_SecurityDescriptor').psbase.CreateInstance()
        $sd.ControlFlags = 4
        $sd.DACL = $ace
        $sd.group = $trustee
        $sd.owner = $trustee

        # Cria a pasta com os acessos definidos.
        $share = Get-WmiObject -Class Win32_Share -List
        $share.Create($Folder, $CompName, 0, 100, $Comment, '', $sd) | Out-Null
        Get-SmbShare -Name 'PUB' -ErrorAction Stop | Out-Null
    }
    Catch {
        $STATUS = "Falha"
        $historico = "ERRO - Não foi possível habilitar o compartilhamento."
    }
}

if ($STATUS -ne "Falha") {
    
    # Define as permissões da pasta.
    $historico = "Definindo permissões..."

    Try {
        # Desabilita a herança.
        $acl = Get-ACL -Path $Folder
        $acl.SetAccessRuleProtection($True, $True)
        Set-Acl -Path $Folder -AclObject $acl

        # Remove todas as permissões atuais.
        $acl = Get-ACL -Path $Folder
        $acl.Access | ? { $_.IdentityReference } |
        %{$acl.RemoveAccessRuleSpecific($_)}
        Set-Acl -Path $Folder -AclObject $acl

        # Adiciona FullControl para o usuário TODOS.
        $acl = Get-ACL -Path $Folder
        $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule('Todos', 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
        $Acl.SetAccessRule($Ar)
        Set-Acl -Path $Folder -AclObject $Acl

        # Define o usuário TODOS como dono da pasta.
        $acl = Get-ACL -Path $Folder
        $Account = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList 'Todos'
        $acl.SetOwner($Account)
        Set-Acl -Path $Folder -AclObject $acl

        # Obtém uma lista com todos os arquivos da pasta.
        $ItemList = Get-ChildItem -Path $Folder -Recurse

        # Define as permissões para cada arquivo obtido.
        foreach ($Item in $ItemList) {
            $Acl = $null; # Reseta a variável ACL.
            $Acl = Get-Acl -Path $Item.FullName; # Obtém o valor da ACL.
            $Acl.SetOwner($Account); # Atualiza a Owner
            Set-Acl -Path $Item.FullName -AclObject $Acl; # Atualiza a ACL.
        }

        $Permissao = Get-Acl -Path $Folder | Where-Object -FilterScript { ($_.Owner -eq 'Todos') -and ($_.Access.IdentityReference -eq 'Todos') }
        if (!($Permissao)) {
            Throw
        }
    }
    Catch {
        $STATUS = "Falha"
        $historico = "ERRO - Não foi possível definir as permissões."
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