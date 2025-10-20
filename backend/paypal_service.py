import os
import requests
import logging
from typing import Optional, Dict, Any

logger = logging.getLogger(__name__)


class PayPalService:
    def __init__(self):
        self.client_id = os.environ.get('PAYPAL_CLIENT_ID')
        self.client_secret = os.environ.get('PAYPAL_CLIENT_SECRET')
        self.mode = os.environ.get('PAYPAL_MODE', 'sandbox')
        
        # Set API base URL based on mode
        if self.mode == 'live':
            self.base_url = 'https://api-m.paypal.com'
        else:
            self.base_url = 'https://api-m.sandbox.paypal.com'
        
        self.access_token = None
        self.token_type = None

    def get_access_token(self) -> Optional[str]:
        """Get OAuth access token from PayPal"""
        try:
            url = f"{self.base_url}/v1/oauth2/token"
            headers = {
                'Accept': 'application/json',
                'Accept-Language': 'en_US',
            }
            data = {'grant_type': 'client_credentials'}
            
            response = requests.post(
                url,
                headers=headers,
                data=data,
                auth=(self.client_id, self.client_secret)
            )
            
            if response.status_code == 200:
                data = response.json()
                self.access_token = data.get('access_token')
                self.token_type = data.get('token_type')
                logger.info("Successfully obtained PayPal access token")
                return self.access_token
            else:
                logger.error(f"Failed to get PayPal token: {response.status_code} - {response.text}")
                return None
                
        except Exception as e:
            logger.error(f"Error getting PayPal access token: {str(e)}")
            return None

    def create_invoice(self, customer_email: str, description: str, amount: float) -> Dict[str, Any]:
        """Create a PayPal invoice"""
        try:
            # Get access token if not already obtained
            if not self.access_token:
                token = self.get_access_token()
                if not token:
                    return {
                        'success': False,
                        'error': 'Failed to authenticate with PayPal'
                    }

            url = f"{self.base_url}/v2/invoicing/invoices"
            headers = {
                'Content-Type': 'application/json',
                'Authorization': f'{self.token_type} {self.access_token}'
            }
            
            # Create invoice payload
            invoice_data = {
                "detail": {
                    "currency_code": "USD",
                    "note": description
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
                            "email_address": customer_email
                        }
                    }
                ],
                "items": [
                    {
                        "name": description,
                        "quantity": "1",
                        "unit_amount": {
                            "currency_code": "USD",
                            "value": str(amount)
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
            
            # Create draft invoice
            response = requests.post(url, headers=headers, json=invoice_data)
            
            if response.status_code == 201:
                invoice = response.json()
                invoice_id = invoice.get('id')
                logger.info(f"Successfully created PayPal invoice: {invoice_id}")
                
                # Send the invoice
                send_result = self.send_invoice(invoice_id)
                
                if send_result['success']:
                    # Get invoice details to retrieve payment link
                    invoice_details = self.get_invoice_details(invoice_id)
                    
                    if invoice_details:
                        # Find the payment link
                        payment_link = None
                        for link in invoice_details.get('links', []):
                            if link.get('rel') == 'payer-view':
                                payment_link = link.get('href')
                                break
                        
                        return {
                            'success': True,
                            'invoice_id': invoice_id,
                            'invoice_url': payment_link,
                            'message': 'Invoice created and sent successfully'
                        }
                
                return send_result
            else:
                logger.error(f"Failed to create invoice: {response.status_code} - {response.text}")
                return {
                    'success': False,
                    'error': f'PayPal API error: {response.status_code}'
                }
                
        except Exception as e:
            logger.error(f"Error creating PayPal invoice: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }

    def send_invoice(self, invoice_id: str) -> Dict[str, Any]:
        """Send an invoice to the recipient"""
        try:
            url = f"{self.base_url}/v2/invoicing/invoices/{invoice_id}/send"
            headers = {
                'Content-Type': 'application/json',
                'Authorization': f'{self.token_type} {self.access_token}'
            }
            
            response = requests.post(url, headers=headers, json={})
            
            if response.status_code == 202:
                logger.info(f"Successfully sent invoice: {invoice_id}")
                return {'success': True}
            else:
                logger.error(f"Failed to send invoice: {response.status_code} - {response.text}")
                return {
                    'success': False,
                    'error': f'Failed to send invoice: {response.status_code}'
                }
                
        except Exception as e:
            logger.error(f"Error sending invoice: {str(e)}")
            return {'success': False, 'error': str(e)}

    def get_invoice_details(self, invoice_id: str) -> Optional[Dict]:
        """Get invoice details"""
        try:
            url = f"{self.base_url}/v2/invoicing/invoices/{invoice_id}"
            headers = {
                'Content-Type': 'application/json',
                'Authorization': f'{self.token_type} {self.access_token}'
            }
            
            response = requests.get(url, headers=headers)
            
            if response.status_code == 200:
                return response.json()
            else:
                logger.error(f"Failed to get invoice details: {response.status_code}")
                return None
                
        except Exception as e:
            logger.error(f"Error getting invoice details: {str(e)}")
            return None