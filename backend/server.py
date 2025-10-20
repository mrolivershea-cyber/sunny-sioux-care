from fastapi import FastAPI, APIRouter, HTTPException
from dotenv import load_dotenv
from starlette.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
import os
import logging
from pathlib import Path
from pydantic import BaseModel, Field, ConfigDict
from typing import List
import uuid
from datetime import datetime, timezone
from apscheduler.schedulers.asyncio import AsyncIOScheduler

from models import (
    ContactSubmission,
    ContactSubmissionCreate,
    ContactResponse,
    EnrollmentRegistration,
    EnrollmentRegistrationCreate,
    EnrollmentResponse,
    InvoiceRequest,
    InvoiceRequestCreate,
    InvoiceResponse
)
from paypal_service import PayPalService
from email_service import EmailService
from payment_monitor import PaymentMonitorService


ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# MongoDB connection
mongo_url = os.environ['MONGO_URL']
client = AsyncIOMotorClient(mongo_url)
db = client[os.environ['DB_NAME']]

# Initialize PayPal service
paypal_service = PayPalService()

# Initialize Email service
email_service = EmailService()

# Initialize Payment Monitor
payment_monitor = PaymentMonitorService(db, paypal_service, email_service)

# Initialize scheduler for automatic invoice creation
scheduler = AsyncIOScheduler()

async def check_payments_job():
    """Background job to check pending payments"""
    await payment_monitor.check_pending_payments()

# Schedule job to run every 10 minutes
scheduler.add_job(check_payments_job, 'interval', minutes=10, id='payment_monitor')
scheduler.start()

logger.info("✅ Payment monitoring scheduler started (runs every 10 minutes)")

# Create the main app without a prefix
app = FastAPI()

# Create a router with the /api prefix
api_router = APIRouter(prefix="/api")


# Define Models
class StatusCheck(BaseModel):
    model_config = ConfigDict(extra="ignore")  # Ignore MongoDB's _id field
    
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    client_name: str
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

class StatusCheckCreate(BaseModel):
    client_name: str

# Add your routes to the router instead of directly to app
@api_router.get("/")
async def root():
    return {"message": "Hello World"}

@api_router.post("/status", response_model=StatusCheck)
async def create_status_check(input: StatusCheckCreate):
    status_dict = input.model_dump()
    status_obj = StatusCheck(**status_dict)
    
    # Convert to dict and serialize datetime to ISO string for MongoDB
    doc = status_obj.model_dump()
    doc['timestamp'] = doc['timestamp'].isoformat()
    
    _ = await db.status_checks.insert_one(doc)
    return status_obj

@api_router.get("/status", response_model=List[StatusCheck])
async def get_status_checks():
    # Exclude MongoDB's _id field from the query results
    status_checks = await db.status_checks.find({}, {"_id": 0}).to_list(1000)
    
    # Convert ISO string timestamps back to datetime objects
    for check in status_checks:
        if isinstance(check['timestamp'], str):
            check['timestamp'] = datetime.fromisoformat(check['timestamp'])
    
    return status_checks


# Contact Form Endpoint
@api_router.post("/contact", response_model=ContactResponse)
async def create_contact_submission(input: ContactSubmissionCreate):
    try:
        # Create contact submission object
        contact_dict = input.model_dump()
        contact_obj = ContactSubmission(**contact_dict)
        
        # Save to database
        await db.contact_submissions.insert_one(contact_obj.model_dump())
        
        logger.info(f"Contact submission created: {contact_obj.id}")
        
        # Send email notification to admin
        email_service.send_contact_notification(
            name=contact_obj.name,
            email=contact_obj.email,
            phone='',
            message=contact_obj.message
        )
        
        return ContactResponse(
            success=True,
            message="Thank you! We'll get back to you soon."
        )
    except Exception as e:
        logger.error(f"Error creating contact submission: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


# Enrollment Registration Endpoint
@api_router.post("/register-enrollment", response_model=EnrollmentResponse)
async def create_enrollment(input: EnrollmentRegistrationCreate):
    try:
        # Create enrollment registration object
        enrollment_dict = {
            "name": input.name,
            "email": input.email,
            "phone": input.phone,
            "address": input.address,
            "plan_name": input.planName,
            "plan_price": input.planPrice
        }
        enrollment_obj = EnrollmentRegistration(**enrollment_dict)
        
        # Save to database
        await db.enrollment_registrations.insert_one(enrollment_obj.model_dump())
        
        logger.info(f"Enrollment registration created: {enrollment_obj.id}")
        logger.info(f"⏰ Payment monitor will check status in 10 minutes")
        
        return EnrollmentResponse(
            success=True,
            message="Registration successful!",
            registrationId=enrollment_obj.id
        )
    except Exception as e:
        logger.error(f"Error creating enrollment registration: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


# PayPal Invoice Creation Endpoint
@api_router.post("/create-invoice", response_model=InvoiceResponse)
async def create_invoice(input: InvoiceRequestCreate):
    try:
        # Create invoice request in PayPal
        result = paypal_service.create_invoice(
            customer_email=input.customerEmail,
            description=input.description,
            amount=input.amount
        )
        
        if not result.get('success'):
            raise HTTPException(
                status_code=400,
                detail=result.get('error', 'Failed to create invoice')
            )
        
        # Save invoice request to database
        invoice_obj = InvoiceRequest(
            customer_email=input.customerEmail,
            customer_name=input.customerName or '',
            customer_phone=input.customerPhone or '',
            customer_address=input.customerAddress or '',
            description=input.description,
            amount=input.amount,
            paypal_invoice_id=result.get('invoice_id'),
            paypal_invoice_url=result.get('invoice_url'),
            status='sent'
        )
        
        await db.invoice_requests.insert_one(invoice_obj.model_dump())
        
        logger.info(f"Invoice created: {invoice_obj.id} - PayPal ID: {result.get('invoice_id')}")
        
        # Send confirmation email to customer
        if result.get('invoice_url'):
            email_service.send_invoice_confirmation(
                customer_email=input.customerEmail,
                description=input.description,
                amount=input.amount,
                invoice_url=result.get('invoice_url')
            )
        
        return InvoiceResponse(
            success=True,
            message="Invoice created! Check your email for the payment link.",
            invoiceUrl=result.get('invoice_url'),
            invoiceId=result.get('invoice_id')
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating invoice: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

# Include the router in the main app
app.include_router(api_router)

app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=os.environ.get('CORS_ORIGINS', '*').split(','),
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("shutdown")
async def shutdown_db_client():
    scheduler.shutdown()
    client.close()
    logger.info("✅ Scheduler and database connections closed")