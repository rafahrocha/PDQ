**SCRIPTS E PACOTES PARA O PDQ DEPLOY**

**Requisitos obrigatórios para utilização dos pacotes:**

1.  Todos os scripts do PowerShell (*.ps1) e arquivos de configuração (*.ini) devem estar no diretório "C:\Packages";
2.  Todos os arquivos de configuração (*.ini) devem ser atualizados com o caminho do instalador do programa ao qual faz referência (mesmo nome do script *.ps1);
3.  O arquivo de configuração "ServiceDesk.ps1", responsável pelos métodos e funções utilizadas nos scripts de instalação/desinstalação/configuração de softwares deve estar no diretório "C:\Packages\Config";
4.  O arquivo "Robocopy.exe" também deve estar no diretório "C:\Packages\Config";

**Importando os pacotes para o PDQ:**

Após instalação da ferramenta, download dos arquivos necessários e extração dos pacotes no Disco Local C (C:\Packages) de cada computador que irá utilizar o PDQ, siga os seguintes passos:

*  Opção 1: Clique com o botão direito na tela branca e vá na opção Import;
*  Opção 2: Selecione as opções "File > Import";
*  Opção 3: Envie o comando de atalho "Ctrl + I";
*  Selecione o arquivo "ServiceDesk - v.01.xml" no diretório "C:\Packages\Pacote XML - PDQ" e clique em Abrir;