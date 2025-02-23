<#
===================================================================================
TITAN AGENT PROXY RUNNER
===================================================================================

DESCRIPTION:
    This script runs the Titan Agent through a SOCKS5 proxy connection. It will also
    ensure that any child processes (like controllers) launched by the agent will
    use the same proxy configuration.

USAGE:
    Run this script directly in PowerShell as Administrator:
       > .\titannet-proxy.ps1

FEATURES:
    - Automatic proxy configuration for agent and controller processes
    - Proxy connection testing before startup
    - Real-time console output
    - Automatic cleanup on exit
    - No system-wide proxy changes

REQUIREMENTS:
    - Windows PowerShell 5.1 or later
    - Administrator privileges (handled by run_proxy.bat)
    - Active SOCKS5 proxy connection

CONFIGURATION:
    Edit these values at the top of the script if needed:
    - PROXY_HOST: Proxy server address
    - PROXY_PORT: Proxy server port
    - PROXY_USER: Proxy username
    - PROXY_PASS: Proxy password
    - WORKING_DIR: Agent working directory
    - SERVER_URL: Titan server URL
    - KEY: Agent key

===================================================================================
#>

# Proxy configuration
$PROXY_HOST = "HOST"
$PROXY_PORT = "PORT"
$PROXY_USER = "USERNAME"
$PROXY_PASS = "PASS"

# Agent configuration from run.bat
$WORKING_DIR = "YOURWORKINGDIR"
$SERVER_URL = "TITANNETSERVERURL"
$KEY = "NODEKEY"

# Function to check if running as administrator
function Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($user)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to test proxy connectivity
function Test-ProxyConnection {
    Write-Host "Testing proxy connection to $PROXY_HOST`:$PROXY_PORT..." -NoNewline
    
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connectResult = $tcpClient.BeginConnect($PROXY_HOST, [int]$PROXY_PORT, $null, $null)
        $waitResult = $connectResult.AsyncWaitHandle.WaitOne(3000, $false)
        
        if ($waitResult) {
            $tcpClient.EndConnect($connectResult)
            Write-Host "SUCCESS" -ForegroundColor Green
            return $true
        } else {
            Write-Host "FAILED (Timeout)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "FAILED ($($_.Exception.Message))" -ForegroundColor Red
        return $false
    } finally {
        if ($tcpClient -ne $null) {
            $tcpClient.Close()
        }
    }
}

# Check for admin rights
if (-not (Test-Administrator)) {
    Write-Host "This script requires administrator privileges. Please run as administrator."
    exit 1
}

# Test proxy connection before proceeding
if (-not (Test-ProxyConnection)) {
    Write-Host "Proxy connection test failed. Please check your proxy settings and try again."
    exit 1
}

try {
    Write-Host "Configuring proxy for agent and controller processes: $PROXY_HOST`:$PROXY_PORT"

    # Get absolute path for agent.exe
    $agentPath = Join-Path -Path $WORKING_DIR -ChildPath "agent.exe"
    Write-Host "Starting agent at: $agentPath"
    
    # Start agent.exe with proper parameters
    if (Test-Path $agentPath) {
        Write-Host "Starting $agentPath through proxy..."
        
        # Set proxy environment variables for the process
        $env:HTTPS_PROXY = "socks5://$PROXY_USER`:$PROXY_PASS@$PROXY_HOST`:$PROXY_PORT"
        $env:HTTP_PROXY = "socks5://$PROXY_USER`:$PROXY_PASS@$PROXY_HOST`:$PROXY_PORT"
        $env:ALL_PROXY = "socks5://$PROXY_USER`:$PROXY_PASS@$PROXY_HOST`:$PROXY_PORT"

        # Start the process
        $arguments = "--working-dir=`"$WORKING_DIR`" --server-url=$SERVER_URL --key=$KEY"
        $process = Start-Process -FilePath $agentPath -ArgumentList $arguments -WorkingDirectory $WORKING_DIR -NoNewWindow -PassThru
        
        Write-Host "Agent process started with proxy configuration"
        Write-Host "Process ID: $($process.Id)"
        Write-Host "Press Ctrl+C to exit..."
        
        # Wait for the process to exit
        $process.WaitForExit()
        
        if ($process.ExitCode -ne 0) {
            Write-Host "Agent process exited with code: $($process.ExitCode)" -ForegroundColor Red
        }

        # Clean up environment variables
        Remove-Item Env:\HTTPS_PROXY -ErrorAction SilentlyContinue
        Remove-Item Env:\HTTP_PROXY -ErrorAction SilentlyContinue
        Remove-Item Env:\ALL_PROXY -ErrorAction SilentlyContinue
        
    } else {
        throw "Agent executable not found at: $agentPath"
    }

} catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
    # Clean up environment variables in case of error
    Remove-Item Env:\HTTPS_PROXY -ErrorAction SilentlyContinue
    Remove-Item Env:\HTTP_PROXY -ErrorAction SilentlyContinue
    Remove-Item Env:\ALL_PROXY -ErrorAction SilentlyContinue
} 
