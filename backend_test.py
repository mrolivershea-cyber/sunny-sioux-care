#!/usr/bin/env python3
"""
Backend API Testing for SunnySiouxCare.com
Tests the contact form and PayPal invoice creation endpoints
"""

import requests
import json
import os
from datetime import datetime
from motor.motor_asyncio import AsyncIOMotorClient
import asyncio

# Configuration
BACKEND_URL = "https://sunshine-daycare.preview.emergentagent.com/api"
MONGO_URL = "mongodb://localhost:27017"
DB_NAME = "test_database"

class BackendTester:
    def __init__(self):
        self.backend_url = BACKEND_URL
        self.mongo_client = None
        self.db = None
        self.test_results = []
        
    async def setup_db(self):
        """Setup MongoDB connection"""
        try:
            self.mongo_client = AsyncIOMotorClient(MONGO_URL)
            self.db = self.mongo_client[DB_NAME]
            print("✅ MongoDB connection established")
            return True
        except Exception as e:
            print(f"❌ MongoDB connection failed: {e}")
            return False
    
    async def cleanup_db(self):
        """Cleanup MongoDB connection"""
        if self.mongo_client:
            self.mongo_client.close()
    
    def log_result(self, test_name, success, message, details=None):
        """Log test result"""
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{status}: {test_name} - {message}")
        
        self.test_results.append({
            "test": test_name,
            "success": success,
            "message": message,
            "details": details,
            "timestamp": datetime.now().isoformat()
        })
    
    async def test_contact_form_api(self):
        """Test the contact form API endpoint"""
        print("\n🧪 Testing Contact Form API...")
        
        # Test data as specified in the request
        test_data = {
            "name": "John Doe",
            "email": "john@example.com",
            "phone": "(712) 555-1234",
            "message": "I'm interested in enrolling my child"
        }
        
        try:
            # Make API request
            response = requests.post(
                f"{self.backend_url}/contact",
                json=test_data,
                headers={"Content-Type": "application/json"},
                timeout=30
            )
            
            print(f"Response Status: {response.status_code}")
            print(f"Response Body: {response.text}")
            
            if response.status_code == 200:
                response_data = response.json()
                
                # Check if response has success=true
                if response_data.get("success") == True:
                    self.log_result(
                        "Contact API Response", 
                        True, 
                        "API returned success=true"
                    )
                    
                    # Verify MongoDB storage
                    await self.verify_contact_in_db(test_data)
                    
                else:
                    self.log_result(
                        "Contact API Response", 
                        False, 
                        f"API returned success={response_data.get('success')}"
                    )
            else:
                self.log_result(
                    "Contact API Response", 
                    False, 
                    f"HTTP {response.status_code}: {response.text}"
                )
                
        except requests.exceptions.RequestException as e:
            self.log_result(
                "Contact API Request", 
                False, 
                f"Request failed: {str(e)}"
            )
        except Exception as e:
            self.log_result(
                "Contact API Test", 
                False, 
                f"Unexpected error: {str(e)}"
            )
    
    async def verify_contact_in_db(self, test_data):
        """Verify contact submission was saved to MongoDB"""
        try:
            # Query the contact_submissions collection
            contact = await self.db.contact_submissions.find_one(
                {"email": test_data["email"]},
                sort=[("created_at", -1)]  # Get the most recent
            )
            
            if contact:
                # Verify the data matches
                if (contact.get("name") == test_data["name"] and 
                    contact.get("email") == test_data["email"] and
                    contact.get("phone") == test_data["phone"] and
                    contact.get("message") == test_data["message"]):
                    
                    self.log_result(
                        "Contact DB Storage", 
                        True, 
                        "Contact submission correctly saved to MongoDB"
                    )
                else:
                    self.log_result(
                        "Contact DB Storage", 
                        False, 
                        "Contact data in DB doesn't match submitted data"
                    )
            else:
                self.log_result(
                    "Contact DB Storage", 
                    False, 
                    "Contact submission not found in MongoDB"
                )
                
        except Exception as e:
            self.log_result(
                "Contact DB Verification", 
                False, 
                f"DB verification failed: {str(e)}"
            )
    
    async def test_paypal_invoice_api(self):
        """Test the PayPal invoice creation API endpoint"""
        print("\n🧪 Testing PayPal Invoice API...")
        
        # Test data as specified in the request
        test_data = {
            "customerEmail": "test@example.com",
            "description": "Monthly Tuition - Test",
            "amount": 50.00
        }
        
        try:
            # Make API request
            response = requests.post(
                f"{self.backend_url}/create-invoice",
                json=test_data,
                headers={"Content-Type": "application/json"},
                timeout=60  # PayPal API might take longer
            )
            
            print(f"Response Status: {response.status_code}")
            print(f"Response Body: {response.text}")
            
            if response.status_code == 200:
                response_data = response.json()
                
                # Check if response has success=true and invoiceUrl
                if (response_data.get("success") == True and 
                    response_data.get("invoiceUrl")):
                    
                    self.log_result(
                        "PayPal API Response", 
                        True, 
                        "API returned success=true with invoiceUrl"
                    )
                    
                    # Verify MongoDB storage
                    await self.verify_invoice_in_db(test_data, response_data)
                    
                else:
                    self.log_result(
                        "PayPal API Response", 
                        False, 
                        f"API response missing success=true or invoiceUrl. Got: {response_data}"
                    )
            else:
                self.log_result(
                    "PayPal API Response", 
                    False, 
                    f"HTTP {response.status_code}: {response.text}"
                )
                
        except requests.exceptions.RequestException as e:
            self.log_result(
                "PayPal API Request", 
                False, 
                f"Request failed: {str(e)}"
            )
        except Exception as e:
            self.log_result(
                "PayPal API Test", 
                False, 
                f"Unexpected error: {str(e)}"
            )
    
    async def verify_invoice_in_db(self, test_data, response_data):
        """Verify invoice request was saved to MongoDB"""
        try:
            # Query the invoice_requests collection
            invoice = await self.db.invoice_requests.find_one(
                {"customer_email": test_data["customerEmail"]},
                sort=[("created_at", -1)]  # Get the most recent
            )
            
            if invoice:
                # Verify the data matches
                if (invoice.get("customer_email") == test_data["customerEmail"] and 
                    invoice.get("description") == test_data["description"] and
                    invoice.get("amount") == test_data["amount"] and
                    invoice.get("paypal_invoice_url") == response_data.get("invoiceUrl")):
                    
                    self.log_result(
                        "Invoice DB Storage", 
                        True, 
                        "Invoice request correctly saved to MongoDB"
                    )
                else:
                    self.log_result(
                        "Invoice DB Storage", 
                        False, 
                        "Invoice data in DB doesn't match submitted data"
                    )
            else:
                self.log_result(
                    "Invoice DB Storage", 
                    False, 
                    "Invoice request not found in MongoDB"
                )
                
        except Exception as e:
            self.log_result(
                "Invoice DB Verification", 
                False, 
                f"DB verification failed: {str(e)}"
            )
    
    async def test_paypal_authentication(self):
        """Test PayPal authentication separately"""
        print("\n🧪 Testing PayPal Authentication...")
        
        try:
            import sys
            import os
            sys.path.append('/app/backend')
            
            # Load environment variables
            from dotenv import load_dotenv
            from pathlib import Path
            ROOT_DIR = Path('/app/backend')
            load_dotenv(ROOT_DIR / '.env')
            
            from paypal_service import PayPalService
            
            paypal_service = PayPalService()
            token = paypal_service.get_access_token()
            
            if token:
                self.log_result(
                    "PayPal Authentication", 
                    True, 
                    "Successfully obtained PayPal access token"
                )
            else:
                self.log_result(
                    "PayPal Authentication", 
                    False, 
                    "Failed to obtain PayPal access token"
                )
                
        except Exception as e:
            self.log_result(
                "PayPal Authentication", 
                False, 
                f"Authentication test failed: {str(e)}"
            )
    
    def print_summary(self):
        """Print test summary"""
        print("\n" + "="*60)
        print("🧪 TEST SUMMARY")
        print("="*60)
        
        total_tests = len(self.test_results)
        passed_tests = sum(1 for result in self.test_results if result["success"])
        failed_tests = total_tests - passed_tests
        
        print(f"Total Tests: {total_tests}")
        print(f"Passed: {passed_tests}")
        print(f"Failed: {failed_tests}")
        print(f"Success Rate: {(passed_tests/total_tests)*100:.1f}%" if total_tests > 0 else "No tests run")
        
        if failed_tests > 0:
            print("\n❌ FAILED TESTS:")
            for result in self.test_results:
                if not result["success"]:
                    print(f"  - {result['test']}: {result['message']}")
        
        print("\n" + "="*60)

async def main():
    """Main test runner"""
    print("🚀 Starting Backend API Tests for SunnySiouxCare.com")
    print(f"Backend URL: {BACKEND_URL}")
    print(f"MongoDB URL: {MONGO_URL}")
    
    tester = BackendTester()
    
    # Setup database connection
    if not await tester.setup_db():
        print("❌ Cannot proceed without database connection")
        return
    
    try:
        # Run all tests
        await tester.test_contact_form_api()
        await tester.test_paypal_invoice_api()
        await tester.test_paypal_authentication()
        
    finally:
        # Cleanup
        await tester.cleanup_db()
    
    # Print summary
    tester.print_summary()

if __name__ == "__main__":
    asyncio.run(main())