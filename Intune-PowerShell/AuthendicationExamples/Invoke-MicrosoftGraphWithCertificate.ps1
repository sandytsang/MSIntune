#Credit to Alex Asplund https://adamtheautomator.com/powershell-graph-api/

$TenantName = "xxxxxx.onmicrosoft.com"  #Your tenant name
$AppId = "788ed3fa-554d-45da-b3ab-xxxxxxx" #Your Azure Application registration
$Certificate = Get-Item Cert:\LocalMachine\My\F0C32E5F4DEE90EA47C34611E43EBD06DA56399F #Your certificate on the client
$Scope = "https://graph.microsoft.com/.default"

# Create base64 hash of certificate
$CertificateBase64Hash = [System.Convert]::ToBase64String($Certificate.GetCertHash())

# Create JWT timestamp for expiration
$StartDate = (Get-Date "1970-01-01T00:00:00Z" ).ToUniversalTime()
$JWTExpirationTimeSpan = (New-TimeSpan -Start $StartDate -End (Get-Date).ToUniversalTime().AddMinutes(2)).TotalSeconds
$JWTExpiration = [math]::Round($JWTExpirationTimeSpan,0)

# Create JWT validity start timestamp
$NotBeforeExpirationTimeSpan = (New-TimeSpan -Start $StartDate -End ((Get-Date).ToUniversalTime())).TotalSeconds
$NotBefore = [math]::Round($NotBeforeExpirationTimeSpan,0)

# Create JWT header
$JWTHeader = @{
    alg = "RS256"
    typ = "JWT"
    # Use the CertificateBase64Hash and replace/strip to match web encoding of base64
    x5t = $CertificateBase64Hash -replace '\+','-' -replace '/','_' -replace '='
}

# Create JWT payload
$JWTPayLoad = @{
    # What endpoint is allowed to use this JWT
    aud = "https://login.microsoftonline.com/$TenantName/oauth2/token"

    # Expiration timestamp
    exp = $JWTExpiration

    # Issuer = your application
    iss = $AppId

    # JWT ID: random guid
    jti = [guid]::NewGuid()

    # Not to be used before
    nbf = $NotBefore

    # JWT Subject
    sub = $AppId
}

# Convert header and payload to base64
$JWTHeaderToByte = [System.Text.Encoding]::UTF8.GetBytes(($JWTHeader | ConvertTo-Json))
$EncodedHeader = [System.Convert]::ToBase64String($JWTHeaderToByte)

$JWTPayLoadToByte =  [System.Text.Encoding]::UTF8.GetBytes(($JWTPayload | ConvertTo-Json))
$EncodedPayload = [System.Convert]::ToBase64String($JWTPayLoadToByte)

# Join header and Payload with "." to create a valid (unsigned) JWT
$JWT = $EncodedHeader + "." + $EncodedPayload

# Get the private key object of your certificate
$PrivateKey = $Certificate.PrivateKey

# Define RSA signature and hashing algorithm
$RSAPadding = [Security.Cryptography.RSASignaturePadding]::Pkcs1
$HashAlgorithm = [Security.Cryptography.HashAlgorithmName]::SHA256

# Create a signature of the JWT
$Signature = [Convert]::ToBase64String(
    $PrivateKey.SignData([System.Text.Encoding]::UTF8.GetBytes($JWT),$HashAlgorithm,$RSAPadding)
) -replace '\+','-' -replace '/','_' -replace '='

# Join the signature to the JWT with "."
$JWT = $JWT + "." + $Signature

# Create a hash with body parameters
$Body = @{
    client_id = $AppId
    client_assertion = $JWT
    client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
    scope = $Scope
    grant_type = "client_credentials"

}

$Url = "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token"

# Use the self-generated JWT as Authorization
$Header = @{
    Authorization = "Bearer $JWT"
}

# Splat the parameters for Invoke-Restmethod for cleaner code
$PostSplat = @{
    ContentType = 'application/x-www-form-urlencoded'
    Method = 'POST'
    Body = $Body
    Uri = $Url
    Headers = $Header
}

$Request = Invoke-RestMethod @PostSplat

# Create header
$Header = @{
    Authorization = "$($Request.token_type) $($Request.access_token)"
}

$Uri = "https://graph.microsoft.com/beta/devicemanagement/manageddevices"

# Fetch all security alerts
$GraphRequest = Invoke-RestMethod -Uri $Uri -Headers $Header -Method Get -ContentType "application/json"

$GraphRequest.value