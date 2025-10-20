#!/usr/bin/env python3
"""
Debug PayPal authentication and invoice creation
"""

import sys
import os
sys.path.append('/app/backend')

from dotenv import load_dotenv
from pathlib import Path

# Load environment variables
ROOT_DIR = Path('/app/backend')
load_dotenv(ROOT_DIR / '.env')

from paypal_service import PayPalService
import requests

def test_paypal_credentials():
    """Test PayPal credentials and authentication"""
    print("🔍 Debugging PayPal Integration...")
    
    # Check environment variables
    client_id = os.environ.get('PAYPAL_CLIENT_ID')
    client_secret = os.environ.get('PAYPAL_CLIENT_SECRET')
    mode = os.environ.get('PAYPAL_MODE', 'sandbox')
    
    print(f"Client ID: {client_id[:10]}..." if client_id else "Client ID: None")
    print(f"Client Secret: {client_secret[:10]}..." if client_secret else "Client Secret: None")
    print(f"Mode: {mode}")
    
    if not client_id or not client_secret:
        print("❌ PayPal credentials not found in environment")
        return False
    
    # Test authentication directly
    paypal_service = PayPalService()
    print(f"Base URL: {paypal_service.base_url}")
    
    # Try to get access token
    token = paypal_service.get_access_token()
    
    if token:
        print(f"✅ Successfully obtained access token: {token[:20]}...")
        return True
    else:
        print("❌ Failed to obtain access token")
        
        # Try manual authentication to see the error
        try:
            url = f"{paypal_service.base_url}/v1/oauth2/token"
            headers = {
                'Accept': 'application/json',
                'Accept-Language': 'en_US',
            }
            data = {'grant_type': 'client_credentials'}
            
            response = requests.post(
                url,
                headers=headers,
                data=data,
                auth=(client_id, client_secret)
            )
            
            print(f"Auth Response Status: {response.status_code}")
            print(f"Auth Response Body: {response.text}")
            
        except Exception as e:
            print(f"Auth Request Error: {e}")
        
        return False

if __name__ == "__main__":
    test_paypal_credentials()