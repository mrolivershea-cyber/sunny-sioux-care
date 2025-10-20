#!/usr/bin/env python3
"""
Debug PayPal invoice creation in detail
"""

import sys
import os
sys.path.append('/app/backend')

from dotenv import load_dotenv
from pathlib import Path
import requests
import json

# Load environment variables
ROOT_DIR = Path('/app/backend')
load_dotenv(ROOT_DIR / '.env')

from paypal_service import PayPalService

def test_invoice_creation():
    """Test PayPal invoice creation step by step"""
    print("🔍 Debugging PayPal Invoice Creation...")
    
    paypal_service = PayPalService()
    
    # Get access token
    token = paypal_service.get_access_token()
    if not token:
        print("❌ Failed to get access token")
        return
    
    print(f"✅ Got access token: {token[:20]}...")
    
    # Test invoice creation manually
    url = f"{paypal_service.base_url}/v2/invoicing/invoices"
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'{paypal_service.token_type} {paypal_service.access_token}'
    }
    
    # Create invoice payload
    invoice_data = {
        "detail": {
            "currency_code": "USD",
            "note": "Monthly Tuition - Test"
        },
        "invoicer": {
            "name": {
                "given_name": "Sunny Sioux Care",
                "surname": "Team"
            },
            "address": {
                "address_line_1": "2110 Summit St, Unit B1",
                "admin_area_2": "Sioux City",
                "admin_area_1": "IA",
                "postal_code": "51104",
                "country_code": "US"
            },
            "email_address": "info@sunnysiouxcare.com"
        },
        "primary_recipients": [
            {
                "billing_info": {
                    "email_address": "test@example.com"
                }
            }
        ],
        "items": [
            {
                "name": "Monthly Tuition - Test",
                "quantity": "1",
                "unit_amount": {
                    "currency_code": "USD",
                    "value": "50.00"
                },
                "unit_of_measure": "QUANTITY"
            }
        ],
        "configuration": {
            "allow_tip": False,
            "tax_calculated_after_discount": True,
            "tax_inclusive": False
        }
    }
    
    print("📤 Sending invoice creation request...")
    print(f"URL: {url}")
    print(f"Headers: {headers}")
    print(f"Payload: {json.dumps(invoice_data, indent=2)}")
    
    try:
        response = requests.post(url, headers=headers, json=invoice_data)
        
        print(f"📥 Response Status: {response.status_code}")
        print(f"📥 Response Headers: {dict(response.headers)}")
        print(f"📥 Response Body: {response.text}")
        
        if response.status_code == 201:
            invoice = response.json()
            invoice_id = invoice.get('id')
            print(f"✅ Invoice created with ID: {invoice_id}")
            
            # Try to send the invoice
            if invoice_id:
                send_url = f"{paypal_service.base_url}/v2/invoicing/invoices/{invoice_id}/send"
                send_response = requests.post(send_url, headers=headers, json={})
                
                print(f"📤 Send invoice status: {send_response.status_code}")
                print(f"📤 Send invoice response: {send_response.text}")
            else:
                print("❌ No invoice ID returned")
        else:
            print(f"❌ Invoice creation failed: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Error during invoice creation: {e}")

if __name__ == "__main__":
    test_invoice_creation()