function Get-Styles() {

    [cmdletbinding()]
    Param([String]$xamlFile) #O caminho da folha de estilos XAML.
    Add-Type -AssemblyName PresentationFramework;
    $inputXML = Get-Content $xamlFile -Raw;

    $inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace '^<Win.*', '<Window';
    [xml]$XAML = $inputXML;

    $reader = (New-Object System.Xml.XmlNodeReader $XAML);
    try { 
        $Global:window = [Windows.Markup.XamlReader]::Load($reader);
    }
    catch {
        Write-Warning $_.Exception;
        throw;
    }

    $XAML.SelectNodes("//*[@Name]") | ForEach-Object {
        try {
            Set-Variable "var_$($_.Name)" $window.FindName($_.Name) -Scope "Global";
        } 
        catch {
            throw;
        };
    };
}

function Get-AnimeLink() {
    [cmdletbinding()]
    Param([string]$Response)
    
    $image = (Invoke-WebRequest -Uri $Response);
    $var_refImage.Source = $image.Images[2].src;
    $var_outputBlock.Text = "Link adquirido com sucesso para o anime: $($image.Images[2].title)";
    $var_animeLinkBox.Background = "Green";
    $Global:downloadLink = $Response;

}

function Initialize-Download() {
    [cmdletbinding()]
    param([string]$link)

    $rawContent = (Invoke-WebRequest $link).rawContent;
    # Gera uma Array com todos os códigos de episódio.
    $episodeCodes = ([regex]::matches($rawContent, "(?:https:\/\/subanimes.biz\/episodio\/)(\d+)") | ForEach-Object { $_.groups[1] });
    $var_outputBlock.Text += "Codigos dos Episodios adquiridos com sucesso! Eis aqui a lista deles: $episodeCodes";
    $Object = [ordered]@{};
    $count = 0;
    #Itera em todos os códigos adquiridos.
    foreach ($episode in $episodeCodes) {
        
        (Invoke-WebRequest -Uri "https://subanimes.biz/episodio/$episode").RawContent -match "https:\/\/subanimes\.biz\/watch\/\?v=\d+&t=[dm]&n=0"

        $rawSource = (Invoke-WebRequest -Uri $Matches.0 -Headers @{
                "User-Agent"      = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:101.0) Gecko/20100101 Firefox/101.0"
                "Accept-Encoding" = "utf-8, deflate"
                "Referer"         = "https://ocurioso.site/"
            }).rawContent
        
        $segmentsLink = [regex]::Match($rawSource, "file:\s?`'\s?(https.*)`'");
        $videoSource = [regex]::Match($rawSource, "(?<=let vSources = JSON\.parse\(')\[.*\]");

        if ($segmentsLink.Success) {
            $count++
            try {
                $rawSegments = wget.exe -q $segmentsLink.Groups[1].Value -O -;
                return [regex]::Matches($rawSegments.RawContent, "(https:.*)(1080p|720p|480p).mp4\/(index-v1-a1.m3u8)").Value -replace '#EXT.*', '' | Out-File -FilePath "$output\segs.txt";
            }
            catch {
                $var_outputBlock.Text = "O episódio $count falhou em ser salvo por problemas do próprio website.";
            }
        }
        elseif ($videoSource.Success) {
            $count++;
            $json = $videoSource.Value | ConvertFrom-Json;
            $prop = @{};
            foreach ($item in $json) {
                $prop.Add("$($item.size)", "$($item.src)")
            }
           $Object.Add("$count", $prop);
        }

        <#Checando se por acaso o número de episódios da temporada já foi atingido para concluir o processo de download de forma responsiva.#>
        if ($episode -eq $episodeCodes[-1]) {

            Write-Information "Todos os links para o download foram adquiridos." -InformationAction Continue;

        };
    }
    $export = New-Object -TypeName PSObject -Property $Object;
    $export | ConvertTo-Json | Out-File "$output\segs.txt";
}
