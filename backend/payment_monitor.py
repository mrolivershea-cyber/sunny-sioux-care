import logging
from datetime import datetime, timedelta
from motor.motor_asyncio import AsyncIOMotorClient
from paypal_service import PayPalService
from email_service import EmailService
from models import InvoiceRequest
import os

logger = logging.getLogger(__name__)


class PaymentMonitorService:
    def __init__(self, db, paypal_service: PayPalService, email_service: EmailService):
        self.db = db
        self.paypal_service = paypal_service
        self.email_service = email_service

    async def check_pending_payments(self):
        """Check for pending registrations and create fallback invoices"""
        try:
            logger.info("Starting payment monitoring check...")
            
            # Find registrations older than 10 minutes with pending status
            ten_minutes_ago = datetime.utcnow() - timedelta(minutes=10)
            
            pending_registrations = await self.db.enrollment_registrations.find({
                "payment_status": "pending",
                "created_at": {"$lt": ten_minutes_ago}
            }).to_list(100)
            
            logger.info(f"Found {len(pending_registrations)} pending registrations")
            
            for registration in pending_registrations:
                try:
                    # Create PayPal invoice
                    result = self.paypal_service.create_invoice(
                        customer_email=registration['email'],
                        description=f"{registration['plan_name']} - Monthly Enrollment",
                        amount=registration['plan_price']
                    )
                    
                    if result.get('success'):
                        # Save invoice record
                        invoice_obj = InvoiceRequest(
                            customer_email=registration['email'],
                            customer_name=registration['name'],
                            customer_phone=registration['phone'],
                            customer_address=registration['address'],
                            description=f"{registration['plan_name']} - Fallback Invoice",
                            amount=registration['plan_price'],
                            paypal_invoice_id=result.get('invoice_id'),
                            paypal_invoice_url=result.get('invoice_url'),
                            status='sent'
                        )
                        
                        await self.db.invoice_requests.insert_one(invoice_obj.model_dump())
                        
                        # Update registration status
                        await self.db.enrollment_registrations.update_one(
                            {"id": registration['id']},
                            {"$set": {
                                "payment_status": "invoice_sent",
                                "updated_at": datetime.utcnow()
                            }}
                        )
                        
                        # Send email notification
                        if result.get('invoice_url'):
                            self.email_service.send_invoice_confirmation(
                                customer_email=registration['email'],
                                description=f"{registration['plan_name']} - Monthly Enrollment",
                                amount=registration['plan_price'],
                                invoice_url=result.get('invoice_url')
                            )
                        
                        logger.info(f"✅ Fallback invoice created for registration: {registration['id']}")
                    else:
                        logger.error(f"❌ Failed to create invoice for {registration['id']}: {result.get('error')}")
                        
                except Exception as e:
                    logger.error(f"❌ Error processing registration {registration.get('id')}: {str(e)}")
                    continue
            
            logger.info("✅ Payment monitoring check completed")
            
        except Exception as e:
            logger.error(f"❌ Error in payment monitoring: {str(e)}")
