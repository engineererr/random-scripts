$creds = Get-Credential

$servers = @("serverA", "serverB")

$webApplicationName = "SharePoint Intranet"
$pfxPath = "\\serverA\c$\temp\cert.pfx"
$certPw = Read-Host -AsSecureString
$existingCertThumbprint "7629CCB245A5033D2767629CCB245A5033D276"
$newCertThumbprint = "7629CCB245A5033D2767629CCB245A5033D276"

foreach($server in $servers){
    
    $session = New-PSSession -ComputerName $server -Credential $creds -Authentication Credssp
    
    Invoke-Command -Session $session -ArgumentList $webApplicationName, $pfxPath, $pfxPassword, $existingCertThumbprint, $newCertThumbprint -ScriptBlock {
        Import-Module WebAdministration
    
        $webApplicationName = $args[0]
        $pfxPath = $args[1]
        $pfxPassword = $args[2]
        $existingCertThumbprint = $args[3]
        $newCertThumbprint = $args[4]

        # Import new cert
        $pfxCertStoreLocation = "Cert:\LocalMachine\My"
        $pfxCertStoreShortLocation = "My"

        
        $importedCertificate = Import-PfxCertificate -FilePath $pfxPath -CertStoreLocation $pfxCertStoreLocation -Exportable -Password $pfxPassword
        $newCertThumbprint = $importedCertificate.Thumbprint

        # Iterate over existing bindings and replace cert
        $websites = Get-Website
    
        foreach($website in $websites){
            Write-Host "Checking '$($website.name)'"
            foreach($binding in $website.bindings.Collection){
                if($binding.certificateHash -eq $existingCertThumbprint){
                    $confirmed = Read-Host "Can I replace cert for current website? yes (y), no (n)"
                    if($confirmed -eq "y"){
                        $binding.RebindSslCertificate($newCertThumbprint, $pfxCertStoreShortLocation)
                    }
                }
            }
        }
    }
    Disconnect-PSSession -Session $session
}
