#!/bin/bash
# Verification script untuk check registration subdomain fix

echo "🔍 Verification Script untuk Subdomain Registration Fix"
echo "=========================================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}1. Checking Flutter register_screen.dart changes${NC}"
echo "   Looking for 'adminUserId' usage instead of 'adminId'..."

if grep -q "appConfig.adminUserId" /e/projek_flutter/buysindo/buysindo_app/lib/ui/auth/register_screen.dart; then
    echo -e "${GREEN}✓ Found appConfig.adminUserId${NC}"
else
    echo -e "${RED}✗ NOT found appConfig.adminUserId${NC}"
fi

if grep -q "Waiting for subdomain config" /e/projek_flutter/buysindo/buysindo_app/lib/ui/auth/register_screen.dart; then
    echo -e "${GREEN}✓ Found waiting logic for subdomain config${NC}"
else
    echo -e "${RED}✗ Waiting logic NOT found${NC}"
fi

echo ""
echo -e "${YELLOW}2. Checking app_config.dart has proper initialization${NC}"

if grep -q "initializeApp" /e/projek_flutter/buysindo/buysindo_app/lib/core/app_config.dart; then
    echo -e "${GREEN}✓ initializeApp method exists${NC}"
else
    echo -e "${RED}✗ initializeApp NOT found${NC}"
fi

if grep -q "getConfigBySubdomain" /e/projek_flutter/buysindo/buysindo_app/lib/core/app_config.dart; then
    echo -e "${GREEN}✓ getConfigBySubdomain endpoint call exists${NC}"
else
    echo -e "${RED}✗ getConfigBySubdomain NOT found${NC}"
fi

echo ""
echo -e "${YELLOW}3. Checking Backend Laravel configuration${NC}"

if grep -q "admin_user_tokens" /c/xampp/htdocs/buysindo/app/Http/Controllers/Api/AuthController.php; then
    echo -e "${GREEN}✓ Backend validates admin tokens${NC}"
else
    echo -e "${RED}✗ Token validation NOT found${NC}"
fi

echo ""
echo -e "${YELLOW}4. Database Checks Needed${NC}"
echo "   Please run these SQL queries to verify database setup:"
echo ""
echo "   Query 1 - Check nabilacell mapping:"
echo "   SELECT subdomain, admin_user_id FROM applications WHERE subdomain='nabilacell';"
echo "   Expected: nabilacell -> 123"
echo ""
echo "   Query 2 - Check admin 123 has tokens:"
echo "   SELECT COUNT(*) FROM admin_user_tokens WHERE admin_user_id=123;"
echo "   Expected: >= 1"
echo ""
echo "   Query 3 - Check all subdomains:"
echo "   SELECT id, subdomain, admin_user_id, name FROM applications ORDER BY subdomain;"
echo ""

echo -e "${YELLOW}5. Testing Steps${NC}"
echo "   1. Build Flutter web app: flutter build web"
echo "   2. Deploy to nabilacell.bukatoko.online"
echo "   3. Open browser console (F12)"
echo "   4. Go to registration page"
echo "   5. Look for logs:"
echo "      ✓ 'Got subdomain-based adminUserId: 123' (Good)"
echo "      ✓ 'Using adminUserId: 123' (Good)"
echo "      ✗ 'Config still default (1050)' (Bad - fix not working)"
echo ""
echo "6. Register new user and verify:"
echo "   SELECT admin_user_id FROM users WHERE email='test@example.com';"
echo "   Expected: 123 (not 1050)"
echo ""
