#!/usr/bin/env python3
import re

file_path = "lib/core/network/api_service.dart"

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace deleteAllChat print with AppLogger
content = re.sub(
    r"print\(\s*\n\s*'\[ApiService\] deleteAllChat: Status code: \[32m\$\{response\.statusCode\}\[0m',\s*\n\s*\);",
    "AppLogger.logDebug(\n        '[ApiService] deleteAllChat: Status code: ${response.statusCode}',\n      );",
    content
)

# Replace getChatMessages print with AppLogger
content = re.sub(
    r"print\(\s*\n\s*'\[ApiService\] getChatMessages: Status code: \[32m\$\{response\.statusCode\}\[0m',\s*\n\s*\);",
    "AppLogger.logDebug(\n        '[ApiService] getChatMessages: Status code: ${response.statusCode}',\n      );",
    content
)

# Replace sendChatMessage print with AppLogger
content = re.sub(
    r"print\(\s*\n\s*'\[ApiService\] sendChatMessage: Status code: \[32m\$\{response\.statusCode\}\[0m',\s*\n\s*\);",
    "AppLogger.logDebug(\n        '[ApiService] sendChatMessage: Status code: ${response.statusCode}',\n      );",
    content
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ All print() statements replaced with AppLogger!")
