# AI Crash Analysis Tool
# Quick log analyzer for Smart AI debugging

param(
    [string]$LogPath = "lua\ai\logs",
    [string]$Action = "summary"
)

Write-Host "=== Smart AI Crash Analysis Tool ===" -ForegroundColor Cyan
Write-Host ""

# Find latest log files
$errorLogs = Get-ChildItem -Path $LogPath -Filter "ai-errors-*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
$debugLogs = Get-ChildItem -Path $LogPath -Filter "ai-debug-*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
$perfLogs = Get-ChildItem -Path $LogPath -Filter "ai-perf-*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending

if (-not $errorLogs -and -not $debugLogs -and -not $perfLogs) {
    Write-Host "No log files found in $LogPath" -ForegroundColor Yellow
    Write-Host "Make sure AI_DEBUG_MODE is enabled in smart-ai.lua" -ForegroundColor Yellow
    exit
}

switch ($Action) {
    "summary" {
        Write-Host "Latest Logs:" -ForegroundColor Green
        Write-Host ""
        
        if ($errorLogs) {
            $latest = $errorLogs[0]
            Write-Host "Error Log: $($latest.Name)" -ForegroundColor Red
            Write-Host "  Modified: $($latest.LastWriteTime)"
            Write-Host "  Size: $([math]::Round($latest.Length/1KB, 2)) KB"
            
            $content = Get-Content $latest.FullName -Raw
            $errorCount = ([regex]::Matches($content, "=== ERROR IN:")).Count
            Write-Host "  Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
            Write-Host ""
        }
        
        if ($debugLogs) {
            $latest = $debugLogs[0]
            Write-Host "Debug Log: $($latest.Name)" -ForegroundColor Yellow
            Write-Host "  Modified: $($latest.LastWriteTime)"
            Write-Host "  Size: $([math]::Round($latest.Length/1KB, 2)) KB"
            Write-Host ""
        }
        
        if ($perfLogs) {
            $latest = $perfLogs[0]
            Write-Host "Performance Log: $($latest.Name)" -ForegroundColor Cyan
            Write-Host "  Modified: $($latest.LastWriteTime)"
            Write-Host "  Size: $([math]::Round($latest.Length/1KB, 2)) KB"
            Write-Host ""
        }
    }
    
    "errors" {
        if (-not $errorLogs) {
            Write-Host "No error logs found!" -ForegroundColor Green
            exit
        }
        
        $latest = $errorLogs[0]
        Write-Host "Analyzing: $($latest.Name)" -ForegroundColor Yellow
        Write-Host ""
        
        $content = Get-Content $latest.FullName -Raw
        $errors = [regex]::Matches($content, "=== ERROR IN: (.+?) ===[\s\S]*?(?=\[|\z)")
        
        if ($errors.Count -eq 0) {
            Write-Host "No errors found! All good!" -ForegroundColor Green
            exit
        }
        
        Write-Host "Found $($errors.Count) errors:" -ForegroundColor Red
        Write-Host ""
        
        $errorSummary = @{}
        foreach ($error in $errors) {
            $funcName = $error.Groups[1].Value
            if (-not $errorSummary.ContainsKey($funcName)) {
                $errorSummary[$funcName] = 0
            }
            $errorSummary[$funcName]++
        }
        
        Write-Host "Error Summary (by function):" -ForegroundColor Yellow
        $errorSummary.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
            Write-Host "  $($_.Key): " -NoNewline
            Write-Host "$($_.Value) times" -ForegroundColor Red
        }
        Write-Host ""
        
        Write-Host "Most Recent Error:" -ForegroundColor Yellow
        Write-Host ""
        $lastError = $errors[$errors.Count - 1].Value
        Write-Host $lastError -ForegroundColor Red
    }
    
    "performance" {
        if (-not $perfLogs) {
            Write-Host "No performance logs found!" -ForegroundColor Yellow
            Write-Host "Enable trackPerformance in ai-debug-logger.lua" -ForegroundColor Yellow
            exit
        }
        
        $latest = $perfLogs[0]
        Write-Host "Performance Report: $($latest.Name)" -ForegroundColor Cyan
        Write-Host ""
        
        Get-Content $latest.FullName | Write-Host
    }
    
    "tail" {
        if ($debugLogs) {
            $latest = $debugLogs[0]
            Write-Host "Last 50 lines of: $($latest.Name)" -ForegroundColor Yellow
            Write-Host ""
            Get-Content $latest.FullName -Tail 50
        } else {
            Write-Host "No debug logs found!" -ForegroundColor Yellow
        }
    }
    
    "clean" {
        Write-Host "Cleaning old log files..." -ForegroundColor Yellow
        
        $allLogs = Get-ChildItem -Path $LogPath -Filter "ai-*.log" -ErrorAction SilentlyContinue
        $oldLogs = $allLogs | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }
        
        if ($oldLogs) {
            Write-Host "Removing $($oldLogs.Count) log files older than 7 days..."
            $oldLogs | Remove-Item -Force
            Write-Host "Done!" -ForegroundColor Green
        } else {
            Write-Host "No old logs to clean." -ForegroundColor Green
        }
    }
    
    "watch" {
        if ($errorLogs) {
            $latest = $errorLogs[0]
            Write-Host "Watching: $($latest.Name)" -ForegroundColor Yellow
            Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
            Write-Host ""
            
            Get-Content $latest.FullName -Wait -Tail 20
        } else {
            Write-Host "No error logs to watch!" -ForegroundColor Yellow
        }
    }
    
    default {
        Write-Host "Unknown action: $Action" -ForegroundColor Red
        Write-Host ""
        Write-Host "Available actions:" -ForegroundColor Yellow
        Write-Host "  summary     - Show latest logs and basic stats (default)"
        Write-Host "  errors      - Analyze errors in detail"
        Write-Host "  performance - Show performance report"
        Write-Host "  tail        - Show last 50 lines of debug log"
        Write-Host "  watch       - Watch error log in real-time"
        Write-Host "  clean       - Remove logs older than 7 days"
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor Cyan
        Write-Host "  .\analyze-ai-logs.ps1"
        Write-Host "  .\analyze-ai-logs.ps1 -Action errors"
        Write-Host "  .\analyze-ai-logs.ps1 -Action watch"
    }
}

Write-Host ""
Write-Host "Analysis complete!" -ForegroundColor Green
