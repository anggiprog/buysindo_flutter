$file = "lib/core/network/api_service.dart"
$content = (Get-Content $file -Raw)

# Replace deleteAllChat print
$content = $content -replace "print\(\s*\n\s*'\[ApiService\] deleteAllChat: Status code: \[32m\`\{response\.statusCode\}\[0m',\s*\n\s*\);", "AppLogger.logDebug(`n        '[ApiService] deleteAllChat: Status code: `${response.statusCode}',`n      );"

# Replace getChatMessages print
$content = $content -replace "print\(\s*\n\s*'\[ApiService\] getChatMessages: Status code: \[32m\`\{response\.statusCode\}\[0m',\s*\n\s*\);", "AppLogger.logDebug(`n        '[ApiService] getChatMessages: Status code: `${response.statusCode}',`n      );"

# Replace sendChatMessage print
$content = $content -replace "print\(\s*\n\s*'\[ApiService\] sendChatMessage: Status code: \[32m\`\{response\.statusCode\}\[0m',\s*\n\s*\);", "AppLogger.logDebug(`n        '[ApiService] sendChatMessage: Status code: `${response.statusCode}',`n      );"

# Replace getPaket print
$content = $content -replace "print\('\[ApiService\] getPaket: ERROR: \`\$e'\);", "AppLogger.logError('[ApiService] getPaket: ERROR', e);"

Set-Content $file -Value $content
Write-Host "✅ Replacements complete!"
