# SunnySiouxCare.com - Backend Integration Contracts

## Overview
This document outlines the API contracts and integration plan for transitioning from mock data to backend implementation.

## Current Mock Data (frontend/src/mock.js)
All data is currently mocked in the frontend and needs to be replaced with API calls.

---

## API Endpoints to Implement

### 1. Contact Form Submission
**Endpoint:** `POST /api/contact`

**Request Body:**
```json
{
  "name": "string",
  "email": "string",
  "phone": "string (optional)",
  "message": "string"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Thank you! We'll get back to you soon."
}
```

**Frontend Location:** `/app/frontend/src/components/Contact.jsx`
**Mock Behavior:** Currently shows success toast without backend call

---

### 2. PayPal Invoice Creation
**Endpoint:** `POST /api/create-invoice`

**Request Body:**
```json
{
  "customerEmail": "string",
  "description": "string",
  "amount": "number"
}
```

**Response:**
```json
{
  "success": true,
  "invoiceId": "string",
  "invoiceUrl": "string",
  "message": "Invoice created successfully"
}
```

**Frontend Location:** `/app/frontend/src/components/PayPalInvoice.jsx`
**Mock Behavior:** Currently shows success toast without actual PayPal API call

**PayPal Integration Requirements:**
- Use PayPal REST API v2
- Client ID: `BAAD4_uy0d2f3T_jOAmrV5zg-3_Y7KLgTIo15fF2CwYHDiuVS7l3awu3_VpZdia9IXiGVauzSwhNh3R6mI`
- Store Client Secret in backend .env file
- Generate OAuth token for API calls
- Create invoice and return payment URL

---

## Environment Variables

### Backend (.env)
```
PAYPAL_CLIENT_ID=BAAD4_uy0d2f3T_jOAmrV5zg-3_Y7KLgTIo15fF2CwYHDiuVS7l3awu3_VpZdia9IXiGVauzSwhNh3R6mI
PAYPAL_CLIENT_SECRET=[TO BE PROVIDED BY USER]
PAYPAL_MODE=sandbox  # or 'live' for production
```

---

## MongoDB Collections

### 1. Contact Submissions
**Collection Name:** `contact_submissions`

**Schema:**
```python
{
  "id": "string (UUID)",
  "name": "string",
  "email": "string",
  "phone": "string (optional)",
  "message": "string",
  "status": "string (new/contacted/resolved)",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### 2. Invoice Requests
**Collection Name:** `invoice_requests`

**Schema:**
```python
{
  "id": "string (UUID)",
  "customer_email": "string",
  "description": "string",
  "amount": "float",
  "paypal_invoice_id": "string (optional)",
  "paypal_invoice_url": "string (optional)",
  "status": "string (pending/sent/paid/cancelled)",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

---

## Backend Implementation Steps

### Phase 1: Contact Form API
1. Create Pydantic models for contact submission
2. Implement POST /api/contact endpoint
3. Validate input data
4. Store in MongoDB
5. Send email notification (optional)
6. Return success response

### Phase 2: PayPal Integration
1. Install PayPal SDK or use requests library
2. Create PayPal service module
3. Implement OAuth token generation
4. Implement invoice creation function
5. Create POST /api/create-invoice endpoint
6. Store invoice record in MongoDB
7. Return invoice URL to frontend

### Phase 3: Frontend Integration
1. Remove mock functions from Contact.jsx
2. Replace with axios calls to /api/contact
3. Remove mock functions from PayPalInvoice.jsx
4. Replace with axios calls to /api/create-invoice
5. Handle loading states and errors
6. Display invoice URL to user

---

## Frontend Changes Required

### Contact.jsx
- Import axios
- Replace mock setTimeout with actual API call
- Add error handling
- Add loading state during submission

### PayPalInvoice.jsx
- Import axios
- Replace mock setTimeout with actual API call
- Display invoice URL after creation
- Add error handling
- Add loading state during submission

---

## Testing Checklist

### Contact Form
- [ ] Valid submission stores in database
- [ ] Email validation works
- [ ] Error handling for API failures
- [ ] Success message displays correctly

### PayPal Invoice
- [ ] Valid invoice creates in PayPal
- [ ] Invoice URL is returned
- [ ] Invoice record stored in database
- [ ] Amount validation works
- [ ] Email validation works
- [ ] Error handling for PayPal API failures

---

## Notes
- All mock data in mock.js (siteInfo, programs, features, testimonials, faqs, galleryImages) will remain static and doesn't need backend
- Only Contact form and PayPal invoice need backend integration
- PayPal Client Secret must be obtained from PayPal Developer Dashboard
- Use PayPal Sandbox for testing, switch to Live mode for production
