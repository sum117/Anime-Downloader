#Realizando a requisição de arquivos necessários.
Add-Type -AssemblyName PresentationFramework;
Import-Module -Name .\functions.psm1;
<#--- Adicionando o leitor de XAML ---#>

Get-Styles  -xamlFile .\MainWindow.xaml; 

<#--- Executando funções da Interface de Usuário. ---#>
$var_animeLinkBox.Add_GotKeyBoardFocus({
        $clipContent = Get-Clipboard -Raw;
        if (($clipContent = Get-Clipboard -Raw).Contains('https://subanimes.biz/anime/')) {
            $var_animeLinkBox.Text = $Response
            Get-AnimeLink -Response $clipContent;
        }
    })

$var_animeLinkBox.Add_KeyUp({
        $content = $var_animeLinkBox.Text;

        if ($content.Contains('https://subanimes.biz/anime/')) {
            Get-AnimeLink -Response $content;
        }
    });

$var_folderBrowser.Add_Click({

        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog;
        $folderBrowser.Description = 'Selecione o local onde o anime será salvo.';
        $folderBrowser.rootFolder = "MyComputer";
        $folderBrowser.selectedPath = "";
        if ($folderBrowser.ShowDialog() -eq "OK") {
            $var_pathBox.Text = $folderBrowser.selectedPath;
            $Global:output = $folderBrowser.SelectedPath;
            Initialize-Download -link $downloadLink
        }
    });

$var_startButton.Add_Click({

        $quality = $var_RadioBtns.Children.Where({ ($_.isChecked -eq "True") });
        if ($quality) {
            $quality = $quality.Content -replace "~.*", "" -replace " " , "";
            $var_outputBlock.Text = "✅ A qualidade selecionada foi: $quality!"
        }
        else {
            $var_outputBlock.Foreground = "Red";
            $var_outputBlock.Text = "Qualidade não selecionada, não é possível prosseguir!";
        }

    });

$Null = $window.ShowDialog();