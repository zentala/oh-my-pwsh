# ============================================
# PROXY GUARD - clear dead HTTP_PROXY/HTTPS_PROXY
# ============================================
# HTTP_PROXY/HTTPS_PROXY pointed at a dead local proxy fail CLOSED for every
# CLI tool that honors them (Node, curl, Claude Code) — not just the traffic
# meant to be proxied. See internal-domains/docs/STRATEGIES.md, ADR 003.
# Runs a fast TCP probe once per shell start; clears the vars for this
# session if nothing answers. No background service required.

function Test-ProxyGuardPort {
    param([string]$HostName, [int]$Port, [int]$TimeoutMs = 200)
    try {
        $client = [System.Net.Sockets.TcpClient]::new()
        $result = $client.BeginConnect($HostName, $Port, $null, $null)
        $ok = $result.AsyncWaitHandle.WaitOne($TimeoutMs) -and $client.Connected
        $client.Close()
        return [bool]$ok
    } catch {
        return $false
    }
}

function Invoke-ProxyGuard {
    foreach ($name in 'HTTP_PROXY', 'HTTPS_PROXY') {
        $val = [Environment]::GetEnvironmentVariable($name)
        if (-not $val) { continue }
        try { $uri = [Uri]$val } catch { continue }
        if (-not (Test-ProxyGuardPort -HostName $uri.Host -Port $uri.Port)) {
            Write-Host "⚠ $name=$val unreachable, clearing for this session" -ForegroundColor Yellow
            Remove-Item "Env:$name" -ErrorAction SilentlyContinue
        }
    }
}

Invoke-ProxyGuard
