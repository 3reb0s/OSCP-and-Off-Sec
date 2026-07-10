#!/bin/bash
# OSCP tool fetcher. Sorts tools into windows/ and linux/ subdirectories by the
# OS each tool RUNS ON (so you can scp a whole folder onto a target of that OS).
#
# Usage:
#   ./transfer.sh [transfer_dir] e.g ./transfer.sh ~/oscp/transfer 
#   - no arg  -> uses the current directory as the transfer dir
#   - with arg-> uses (and creates if needed) the given directory
#
# Note: windows-exploit-suggester.py is grouped in windows/ by purpose (it's a
# Windows privesc tool), though it actually RUNS on Kali against systeminfo
# output - you don't drop it on the target itself.

set -uo pipefail

TRANSFER_DIR="${1:-$PWD}"
if [ -d "$TRANSFER_DIR" ]; then
    echo "[*] Using existing transfer directory: $TRANSFER_DIR"
else
    echo "[*] Transfer directory not found - creating: $TRANSFER_DIR"
    mkdir -p "$TRANSFER_DIR" || { echo "[-] Could not create $TRANSFER_DIR"; exit 1; }
fi
cd "$TRANSFER_DIR" || { echo "[-] Could not enter $TRANSFER_DIR"; exit 1; }
mkdir -p windows linux
echo "[*] Subdirectories ready: windows/ and linux/"
echo

gh_asset() {
    local repo="$1" include="$2" out="$3" exclude="${4:-}"
    local matches url
    matches=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" \
        | grep '"browser_download_url"' | cut -d'"' -f4 | grep -iE "$include")
    [ -n "$exclude" ] && matches=$(echo "$matches" | grep -viE "$exclude")
    url=$(echo "$matches" | head -1)
    if [ -n "$url" ]; then
        curl -sSfL "$url" -o "$out" && echo "[+] ${repo} -> ${out}"
    else
        echo "[-] ${repo}: no asset matching /${include}/ (source-only release? build it or grab a trusted precompiled copy)"
    fi
}

copy_first() {
    local dest="$1" label="$2"; shift 2
    local p
    for p in "$@"; do
        if [ -e "$p" ]; then
            cp -f "$p" "$dest/" && echo "[+] copied from Kali: $label -> $dest/"
            return 0
        fi
    done
    return 1
}

echo "[*] pspy"
curl -sSfL "https://github.com/DominicBreuker/pspy/releases/latest/download/pspy64" -o linux/pspy64
curl -sSfL "https://github.com/DominicBreuker/pspy/releases/latest/download/pspy32" -o linux/pspy32
chmod +x linux/pspy64 linux/pspy32

echo "[*] linpeas"
curl -sSfL "https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh" -o linux/linpeas.sh
chmod +x linux/linpeas.sh

echo "[*] LSE (linux smart enumeration)"
curl -sSfL "https://raw.githubusercontent.com/diego-treitos/linux-smart-enumeration/master/lse.sh" -o linux/lse.sh
chmod +x linux/lse.sh

echo "[*] linux-exploit-suggester"
curl -sSfL "https://raw.githubusercontent.com/The-Z-Labs/linux-exploit-suggester/master/linux-exploit-suggester.sh" -o linux/linux-exploit-suggester.sh
chmod +x linux/linux-exploit-suggester.sh

echo "[*] PwnKit"
curl -sSfL "https://raw.githubusercontent.com/ly4k/PwnKit/main/PwnKit" -o linux/PwnKit
chmod +x linux/PwnKit

echo "[*] traitor"
curl -sSfL "https://github.com/liamg/traitor/releases/latest/download/traitor" -o linux/traitor
chmod +x linux/traitor

echo "[*] socat (static linux binary)"
curl -sSfL "https://raw.githubusercontent.com/andrew-d/static-binaries/master/binaries/linux/x86_64/socat" -o linux/socat
chmod +x linux/socat

echo "[*] winPEAS"
curl -sSfL "https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEASany.exe" -o windows/winPEASany.exe
curl -sSfL "https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEASx64.exe" -o windows/winPEASx64.exe
curl -sSfL "https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEASx86.exe" -o windows/winPEASx86.exe

echo "[*] mimikatz (x64 build)"
curl -sSfL "https://github.com/gentilkiwi/mimikatz/releases/latest/download/mimikatz_trunk.zip" -o mimikatz_trunk.zip
unzip -oq mimikatz_trunk.zip -d mimikatz_tmp && {
    cp mimikatz_tmp/x64/mimikatz.exe windows/mimikatz.exe 2>/dev/null || find mimikatz_tmp -iname "mimikatz.exe" -exec cp {} windows/ \;
    rm -rf mimikatz_tmp mimikatz_trunk.zip
} || echo "[-] mimikatz unzip failed, leaving mimikatz_trunk.zip in place"

echo "[*] PowerUp"
curl -sSfL "https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Privesc/PowerUp.ps1" -o windows/PowerUp.ps1

echo "[*] Invoke-RunasCs"
curl -sSfL "https://raw.githubusercontent.com/antonioCoco/RunasCs/master/Invoke-RunasCs.ps1" -o windows/Invoke-RunasCs.ps1

echo "[*] Inveigh"
git clone --depth 1 -q https://github.com/Kevin-Robertson/Inveigh.git Inveigh_tmp && {
    find Inveigh_tmp -iname "*.ps1" -exec cp {} windows/ \;
    find Inveigh_tmp -iname "*.exe" -exec cp {} windows/ \;
    rm -rf Inveigh_tmp
} || echo "[-] Inveigh clone failed"

echo "[*] Snaffler"
curl -sSfL "https://github.com/SnaffCon/Snaffler/releases/latest/download/Snaffler.exe" -o windows/Snaffler.exe

echo "[*] PrintSpoofer"
curl -sSfL "https://github.com/itm4n/PrintSpoofer/releases/latest/download/PrintSpoofer32.exe" -o windows/PrintSpoofer32.exe
curl -sSfL "https://github.com/itm4n/PrintSpoofer/releases/latest/download/PrintSpoofer64.exe" -o windows/PrintSpoofer64.exe

echo "[*] LaZagne"
curl -sSfL "https://github.com/AlessandroZ/LaZagne/releases/latest/download/LaZagne.exe" -o windows/LaZagne.exe

echo "[*] GodPotato"
curl -sSfL "https://github.com/BeichenDream/GodPotato/releases/latest/download/GodPotato-NET2.exe" -o windows/GodPotato-NET2.exe
curl -sSfL "https://github.com/BeichenDream/GodPotato/releases/latest/download/GodPotato-NET35.exe" -o windows/GodPotato-NET35.exe
curl -sSfL "https://github.com/BeichenDream/GodPotato/releases/latest/download/GodPotato-NET4.exe" -o windows/GodPotato-NET4.exe

echo "[*] RunasCs (both .NET 4.0 and .NET 2.0 builds)"
curl -sSfL "https://github.com/antonioCoco/RunasCs/releases/latest/download/RunasCs.zip" -o RunasCs.zip
unzip -oq RunasCs.zip RunasCs.exe RunasCs_net2.exe -d windows/ && rm -f RunasCs.zip || echo "[-] RunasCs unzip failed, leaving RunasCs.zip in place"

echo "[*] JuicyPotato"
curl -sSfL "https://github.com/ohpe/juicy-potato/releases/latest/download/JuicyPotato.exe" -o windows/JuicyPotato.exe

echo "[*] RoguePotato"
curl -sSfL "https://github.com/antonioCoco/RoguePotato/releases/latest/download/RoguePotato.zip" -o RoguePotato.zip
unzip -oq RoguePotato.zip -d RoguePotato_tmp && {
    find RoguePotato_tmp -iname "*.exe" -exec cp {} windows/ \;
    rm -rf RoguePotato_tmp RoguePotato.zip
} || echo "[-] RoguePotato unzip failed, leaving RoguePotato.zip in place"

echo "[*] SeManageVolumeExploit"
curl -sSfL "https://github.com/CsEnox/SeManageVolumeExploit/releases/latest/download/SeManageVolumeExploit.exe" -o windows/SeManageVolumeExploit.exe

echo "[*] Sherlock"
curl -sSfL "https://raw.githubusercontent.com/rasta-mouse/Sherlock/master/Sherlock.ps1" -o windows/Sherlock.ps1

echo "[*] JAWS"
curl -sSfL "https://raw.githubusercontent.com/411Hall/JAWS/master/jaws-enum.ps1" -o windows/jaws-enum.ps1

echo "[*] windows-exploit-suggester"
curl -sSfL "https://raw.githubusercontent.com/AonCyberLabs/Windows-Exploit-Suggester/master/windows-exploit-suggester.py" -o windows/windows-exploit-suggester.py

echo "[*] PowerView (dev branch)"
curl -sSfL "https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/dev/Recon/PowerView.ps1" -o windows/PowerView.ps1

echo "[*] ADRecon"
curl -sSfL "https://raw.githubusercontent.com/adrecon/ADRecon/master/ADRecon.ps1" -o windows/ADRecon.ps1

echo "[*] Powermad"
curl -sSfL "https://raw.githubusercontent.com/Kevin-Robertson/Powermad/master/Powermad.ps1" -o windows/Powermad.ps1

echo "[*] Get-GPPPassword"
curl -sSfL "https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Exfiltration/Get-GPPPassword.ps1" -o windows/Get-GPPPassword.ps1

echo "[*] PSPKIAudit"
curl -sSfL "https://raw.githubusercontent.com/GhostPack/PSPKIAudit/main/PSPKIAudit.psm1" -o windows/PSPKIAudit.psm1

echo "[*] powercat"
curl -sSfL "https://raw.githubusercontent.com/besimorhino/powercat/master/powercat.ps1" -o windows/powercat.ps1

echo "[*] Rubeus"
gh_asset "GhostPack/Rubeus" "Rubeus.*\.exe$" "windows/Rubeus.exe"

echo "[*] SharpHound (BloodHound CE collector)"
gh_asset "SpecterOps/SharpHound" "SharpHound_v[0-9.]+_windows.*\.zip$" SharpHound.zip "debug|sha256"
[ -f SharpHound.zip ] && unzip -oq SharpHound.zip SharpHound.exe -d windows/ && rm -f SharpHound.zip

echo "[*] kerbrute (linux + windows builds)"
curl -sSfL "https://github.com/ropnop/kerbrute/releases/latest/download/kerbrute_linux_amd64" -o linux/kerbrute_linux_amd64
curl -sSfL "https://github.com/ropnop/kerbrute/releases/latest/download/kerbrute_windows_amd64.exe" -o windows/kerbrute_windows_amd64.exe
chmod +x linux/kerbrute_linux_amd64

echo "[*] chisel (linux + windows builds)"
curl -sSfL "https://github.com/jpillora/chisel/releases/latest/download/chisel_linux_amd64.gz" -o linux/chisel_linux_amd64.gz
gunzip -f linux/chisel_linux_amd64.gz
curl -sSfL "https://github.com/jpillora/chisel/releases/latest/download/chisel_windows_amd64.gz" -o windows/chisel_windows_amd64.gz
gunzip -f windows/chisel_windows_amd64.gz
mv -f windows/chisel_windows_amd64 windows/chisel_windows_amd64.exe
chmod +x linux/chisel_linux_amd64

echo "[*] ligolo-ng (linux agent+proxy, windows agent)"
gh_asset "nicocha30/ligolo-ng" "agent_.*_linux_amd64\.tar\.gz$"  ligolo_agent_linux.tar.gz
gh_asset "nicocha30/ligolo-ng" "agent_.*_windows_amd64\.zip$"    ligolo_agent_windows.zip
gh_asset "nicocha30/ligolo-ng" "proxy_.*_linux_amd64\.tar\.gz$"  ligolo_proxy_linux.tar.gz
[ -f ligolo_agent_linux.tar.gz ] && tar -xzf ligolo_agent_linux.tar.gz agent 2>/dev/null && mv -f agent linux/ligolo-agent-linux && rm -f ligolo_agent_linux.tar.gz
[ -f ligolo_agent_windows.zip ] && unzip -oq ligolo_agent_windows.zip agent.exe && mv -f agent.exe windows/ligolo-agent.exe && rm -f ligolo_agent_windows.zip
[ -f ligolo_proxy_linux.tar.gz ] && tar -xzf ligolo_proxy_linux.tar.gz proxy 2>/dev/null && mv -f proxy linux/ligolo-proxy-linux && rm -f ligolo_proxy_linux.tar.gz
chmod +x linux/ligolo-agent-linux linux/ligolo-proxy-linux 2>/dev/null

echo "[*] credshunter (linux .sh + windows .ps1)"
curl -sSfL "https://raw.githubusercontent.com/NeCr00/Credential-Hunting/main/credshunter.sh" -o linux/credshunter.sh
curl -sSfL "https://raw.githubusercontent.com/NeCr00/Credential-Hunting/main/credshunter.ps1" -o windows/credshunter.ps1
chmod +x linux/credshunter.sh

echo "[*] Copying Windows helper binaries already on Kali"
copy_first windows "nc.exe"    /usr/share/windows-resources/binaries/nc.exe    /usr/share/windows-binaries/nc.exe    || { echo "[*]   nc.exe not on Kali - fetching int0x33 mirror"; curl -sSfL "https://raw.githubusercontent.com/int0x33/nc.exe/master/nc.exe" -o windows/nc.exe; }
copy_first windows "nc64.exe"  /usr/share/windows-resources/binaries/nc64.exe  || { echo "[*]   nc64.exe not on Kali - fetching int0x33 mirror"; curl -sSfL "https://raw.githubusercontent.com/int0x33/nc.exe/master/nc64.exe" -o windows/nc64.exe; }
copy_first windows "plink.exe"  /usr/share/windows-resources/binaries/plink.exe  /usr/share/windows-binaries/plink.exe  || echo "[-] plink.exe not found on Kali"
copy_first windows "wget.exe"   /usr/share/windows-resources/binaries/wget.exe   /usr/share/windows-binaries/wget.exe   || echo "[-] wget.exe not found on Kali"
copy_first windows "whoami.exe" /usr/share/windows-resources/binaries/whoami.exe /usr/share/windows-binaries/whoami.exe || echo "[-] whoami.exe not found on Kali"

echo
echo "======================================================================"
echo "[*] Transfer files done. Directory: $TRANSFER_DIR"
echo "    Sanity-check sizes below; anything only a few hundred bytes is"
echo "    probably an error page, not the real tool."
echo "======================================================================"
echo "--- linux/ ---";   ls -lh linux/   2>/dev/null
echo "--- windows/ ---"; ls -lh windows/ 2>/dev/null

echo
echo "======================================================================"
echo "[*] Kali attacker-box tools (run FROM Kali; not for target transfer)"
echo "======================================================================"
if command -v pipx >/dev/null 2>&1; then
    for pkg in certipy-ad bloodyAD coercer; do
        echo "[*] pipx install $pkg"
        pipx install "$pkg" 2>/dev/null || pipx upgrade "$pkg" 2>/dev/null || echo "[-] $pkg: pipx install/upgrade failed"
    done
else
    echo "[-] pipx not found. On Kali: sudo apt install certipy-ad bloodyad coercer"
    echo "    (or: sudo apt install pipx; pipx install certipy-ad bloodyAD coercer)"
fi

echo "[*] RustHound-CE (BloodHound CE collector; prebuilt Linux x86_64 gnu binary -> linux/)"
if ! command -v rusthound-ce >/dev/null 2>&1; then
    gh_asset "g0h4n/RustHound-CE" "rusthound-ce-Linux-gnu.*\.tar\.gz$" rusthound-ce.tar.gz "arm|aarch|musl|sha256"
    if [ -f rusthound-ce.tar.gz ]; then
        mkdir -p rusthound_tmp && tar -xzf rusthound-ce.tar.gz -C rusthound_tmp 2>/dev/null
        found=$(find rusthound_tmp -type f -name 'rusthound-ce*' ! -name '*.sha256' | head -1)
        [ -n "$found" ] && cp "$found" linux/rusthound-ce && chmod +x linux/rusthound-ce && echo "[+] rusthound-ce -> linux/rusthound-ce"
        rm -rf rusthound_tmp rusthound-ce.tar.gz
    fi
else
    echo "[+] rusthound-ce already installed on PATH"
fi
