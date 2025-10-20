#!/usr/bin/env python3
"""
Test getting invoice details from PayPal
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

def test_get_invoice_details():
    """Test getting invoice details"""
    print("🔍 Testing PayPal get invoice details...")
    
    paypal_service = PayPalService()
    
    # Get access token
    token = paypal_service.get_access_token()
    if not token:
        print("❌ Failed to get access token")
        return
    
    print(f"✅ Got access token")
    
    # Use a recent invoice ID from the logs
    invoice_id = "INV2-FPKZ-SVK9-LZH7-N4W3"
    
    print(f"🔍 Getting details for invoice: {invoice_id}")
    
    invoice_details = paypal_service.get_invoice_details(invoice_id)
    
    if invoice_details:
        print(f"✅ Got invoice details:")
        print(f"Status: {invoice_details.get('status')}")
        print(f"Full response: {invoice_details}")
        
        # Check for recipient_view_url in metadata
        metadata = invoice_details.get('metadata', {})
        recipient_view_url = metadata.get('recipient_view_url')
        
        if recipient_view_url:
            print(f"✅ Found recipient view URL: {recipient_view_url}")
        else:
            print("❌ No recipient_view_url found in metadata")
        
        # Also check links
        print(f"Links: {invoice_details.get('links', [])}")
        payment_link = None
        for link in invoice_details.get('links', []):
            print(f"  Link: {link.get('rel')} -> {link.get('href')}")
            if link.get('rel') == 'payer-view':
                payment_link = link.get('href')
        
        if payment_link:
            print(f"✅ Found payment link: {payment_link}")
        else:
            print("❌ No payer-view link found")
    else:
        print("❌ Failed to get invoice details")

if __name__ == "__main__":
    test_get_invoice_details()