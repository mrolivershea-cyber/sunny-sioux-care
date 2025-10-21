# Sunny Sioux Care - Childcare Center Website

![Sunny Sioux Care](https://img.shields.io/badge/status-production-green)
![License](https://img.shields.io/badge/license-MIT-blue)

Professional childcare center website with integrated PayPal payments, automated invoice generation, and comprehensive management system.

## 🌟 Features

### Frontend (React)
- **Modern UI/UX** - Built with React 19 & Shadcn UI
- **Responsive Design** - Mobile-first approach with Tailwind CSS
- **Age-Based Programs** - Infant Care, Toddler & Preschool, School-Age Care
- **Interactive Components** - Photo gallery, testimonials, FAQ accordion
- **Contact Forms** - Easy communication with staff

### Payment Integration
- **PayPal Direct Links** - Instant payment for monthly plans
  - Infant Care: $1,200/month
  - Toddler & Preschool: $950/month
  - School-Age Care: $600/month
- **Custom Invoicing** - Create custom invoices through PayPal API
- **Donate Button** - Accept donations from satisfied families
- **Smart Fallback** - Automatic invoice generation if payment fails

### Backend (FastAPI)
- **RESTful API** - Fast and modern Python backend
- **MongoDB Database** - Scalable NoSQL data storage
- **Payment Monitoring** - Automated cron job checks payments every 10 minutes
- **Email Notifications** - Automated email system (optional)
- **Data Management** - Complete enrollment and invoice tracking

## 🏗️ Tech Stack

### Frontend
- React 19.0.0
- React Router v7
- Shadcn UI (Radix UI components)
- Tailwind CSS
- Axios
- Sonner (toast notifications)

### Backend
- FastAPI (Python 3.11)
- MongoDB with Motor (async)
- APScheduler (cron jobs)
- Pydantic (data validation)
- PayPal REST API v2

### Infrastructure
- Nginx (web server)
- PM2 (process manager)
- Let's Encrypt (SSL)
- MongoDB (database)

## 📦 Installation

### Prerequisites
- Node.js 18+ and Yarn
- Python 3.11+
- MongoDB 7.0+
- Nginx

### Quick Start

1. **Clone the repository**
```bash
git clone https://github.com/YOUR_USERNAME/sunny-sioux-care.git
cd sunny-sioux-care
```

2. **Install Frontend**
```bash
cd frontend
yarn install
cp .env.example .env
# Edit .env with your backend URL
yarn build
```

3. **Install Backend**
```bash
cd ../backend
python3.11 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your credentials
```

4. **Start Services**
```bash
# Start MongoDB
sudo systemctl start mongod

# Start Backend (with PM2)
pm2 start ecosystem.config.js

# Configure Nginx (see DEPLOYMENT_GUIDE.md)
```

## ⚙️ Configuration

### Frontend (.env)
```env
REACT_APP_BACKEND_URL=https://sunnysiouxcare.com
```

### Backend (.env)
```env
MONGO_URL=mongodb://localhost:27017
DB_NAME=sunnysiouxcare_production
PAYPAL_CLIENT_ID=your_client_id
PAYPAL_CLIENT_SECRET=your_client_secret
PAYPAL_MODE=live
EMAIL_ENABLED=false
```

## 🚀 Deployment

Full deployment instructions available in [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

### Quick Deploy
1. Set up Ubuntu 22.04 server
2. Install dependencies
3. Configure environment variables
4. Set up Nginx with SSL
5. Start services with PM2

## 📖 Documentation

- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Complete deployment instructions
- **[CREDENTIALS_AND_CONFIG.md](CREDENTIALS_AND_CONFIG.md)** - All credentials and configuration
- **[EMAIL_SETUP_INSTRUCTIONS.md](EMAIL_SETUP_INSTRUCTIONS.md)** - Email server setup
- **[contracts.md](contracts.md)** - API contracts and endpoints

## 🔐 Security

- HTTPS enforced with Let's Encrypt SSL
- Environment variables for sensitive data
- MongoDB authentication
- CORS configuration
- Security headers in Nginx

## 🤝 Contributing

This is a private project for Sunny Sioux Care. For questions or support, please contact the development team.

## 📝 License

Proprietary - All rights reserved to Sunny Sioux Care

## 📞 Contact

**Sunny Sioux Care**
- Address: 2110 Summit St, Sioux City, IA 51104
- Email: info@sunnysiouxcare.com
- Website: https://sunnysiouxcare.com

## 🏆 Features Highlights

### Automated Payment System
- ✅ Direct PayPal payment links for each plan
- ✅ Custom invoice generation
- ✅ Automatic fallback invoices (10-minute check)
- ✅ Complete payment tracking in MongoDB

### Smart Registration Flow
1. User selects a plan
2. Fills registration form (name, email, phone, address)
3. Redirected to PayPal for payment
4. If payment fails → automatic invoice sent after 10 minutes

### Admin Features
- MongoDB database with all registrations
- Invoice tracking and status updates
- Contact form submissions
- Email notifications (when enabled)

## 🛠️ Development

### Local Development

**Frontend**
```bash
cd frontend
yarn start  # Runs on http://localhost:3000
```

**Backend**
```bash
cd backend
source venv/bin/activate
uvicorn server:app --reload --host 0.0.0.0 --port 8001
```

### Testing
See [test_result.md](test_result.md) for test results and coverage.

## 📊 Project Structure

```
sunny-sioux-care/
├── frontend/               # React application
│   ├── src/
│   │   ├── components/    # React components
│   │   ├── mock.js        # Static data
│   │   ├── App.js
│   │   └── index.css
│   ├── package.json
│   └── .env
│
├── backend/               # FastAPI application
│   ├── server.py          # Main application
│   ├── models.py          # Pydantic models
│   ├── paypal_service.py  # PayPal integration
│   ├── email_service.py   # Email service
│   ├── payment_monitor.py # Cron job
│   ├── requirements.txt
│   └── .env
│
└── docs/                  # Documentation
```

## 🎯 Roadmap

- [x] Basic website with programs
- [x] PayPal payment integration
- [x] Custom invoice generation
- [x] Automated payment monitoring
- [x] Registration system
- [ ] Admin dashboard
- [ ] Parent portal
- [ ] Online scheduling
- [ ] Photo gallery management

## 💡 Support

For technical support or questions:
1. Check documentation in `/docs` folder
2. Review [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
3. Check backend logs: `pm2 logs sunnysiouxcare-backend`

---

Built with ❤️ for Sunny Sioux Care families
