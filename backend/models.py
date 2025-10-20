from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime
import uuid


class ContactSubmission(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    email: EmailStr
    message: str
    status: str = "new"
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class ContactSubmissionCreate(BaseModel):
    name: str
    email: EmailStr
    message: str


class EnrollmentRegistration(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    email: EmailStr
    phone: str
    address: str
    plan_name: str
    plan_price: float
    payment_status: str = "pending"
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class EnrollmentRegistrationCreate(BaseModel):
    name: str
    email: EmailStr
    phone: str
    address: str
    planName: str
    planPrice: float


class InvoiceRequest(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    customer_email: EmailStr
    customer_name: Optional[str] = None
    customer_phone: Optional[str] = None
    customer_address: Optional[str] = None
    description: str
    amount: float
    paypal_invoice_id: Optional[str] = None
    paypal_invoice_url: Optional[str] = None
    status: str = "pending"
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class InvoiceRequestCreate(BaseModel):
    customerEmail: EmailStr
    customerName: Optional[str] = None
    customerPhone: Optional[str] = None
    customerAddress: Optional[str] = None
    description: str
    amount: float


class ContactResponse(BaseModel):
    success: bool
    message: str


class EnrollmentResponse(BaseModel):
    success: bool
    message: str
    registrationId: str


class InvoiceResponse(BaseModel):
    success: bool
    message: str
    invoiceUrl: Optional[str] = None
    invoiceId: Optional[str] = None