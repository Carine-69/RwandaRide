# RwandaRide 🚗

A full-stack ride-hailing mobile application built for the Rwandan market, connecting riders and drivers in real time.

## Tech Stack

**Backend**
- Python / FastAPI
- PostgreSQL
- SQLAlchemy ORM
- JWT Authentication
- bcrypt password hashing

**Frontend**
- Flutter / Dart
- Google Maps Flutter
- Provider state management
- Geolocator & Geocoding

## Features

### Rider
- Register and login
- Book a ride using Google Maps (tap to set pickup and destination)
- Auto-calculated fare based on GPS coordinates and vehicle type
- Real-time trip status updates (every 5 seconds)
- View driver info, vehicle plate, and phone number
- Multiple payment options: Cash, MTN Mobile Money, Airtel Money
- USSD payment codes auto-generated
- Invoice and receipt generation
- Trip history

### Driver
- Register and login with vehicle info
- Go online/offline
- Accept available trips
- Trip status flow: Accepted → Arrived at Pickup → Journey Started → Completed
- Wallet with real-time trip tracking
- Payment confirmation system
- Trip history with receipts
- Earnings summary with 15% commission breakdown

## Vehicle Types & Rates

| Vehicle | Rate |
|---------|------|
| Moto | 200 RWF/km |
| Economy | 350 RWF/km |
| Standard | 500 RWF/km |
| XL | 700 RWF/km |

Base fare: 500 RWF. Platform commission: 15%.

## Payment Flow

Trip completed
→ Rider sees invoice with fare
→ Rider chooses payment method
→ Cash: pays driver directly
→ MTN MoMo: dials 1828DRIVER_NUMBERAMOUNT#
→ Airtel: dials 1821DRIVER_NUMBERAMOUNT#
→ Rider taps "I Have Paid"
→ Driver sees payment notification
→ Driver confirms → Both get receipts
→ Driver wallet balance updates

## Trip Status Flow

## Setup & Installation

### Backend

```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install fastapi uvicorn sqlalchemy psycopg2-binary bcrypt PyJWT python-dotenv
```

Create PostgreSQL database:
```bash
sudo -u postgres psql
CREATE DATABASE rwandaride;
\q
```

Add columns:
```sql
ALTER TABLE trips ADD COLUMN started_at TIMESTAMP;
ALTER TABLE trips ADD COLUMN completed_at TIMESTAMP;
```

Create `.env`:

DATABASE_URL=postgresql://postgres:rwanda123@localhost/rwandaride
JWT_SECRET=rwandaride_secret_key_2026

Run:
```bash
uvicorn main:app --reload
```

API runs at `http://127.0.0.1:8000`

### Flutter App

```bash
cd RwandaRide
flutter pub get
flutter run
```

Add your Google Maps API key to `web/index.html`:
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY&libraries=places"></script>
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /auth/register | Register rider or driver |
| POST | /auth/login | Login |
| GET | /auth/me | Get current user |
| POST | /trips/ | Book a trip |
| GET | /trips/my-trips | Rider trip history |
| GET | /trips/available | Available trips for driver |
| GET | /trips/driver-trips | Driver trip history |
| PATCH | /trips/{id}/accept | Accept a trip |
| PATCH | /trips/{id}/status | Update trip status |
| GET | /trips/{id}/invoice | Get trip invoice |
| POST | /payments/ | Create payment |
| GET | /payments/wallet | Driver wallet |
| PATCH | /payments/{id}/confirm | Confirm payment |

## Project Structure

rwandaride/
├── backend/
│   ├── main.py
│   ├── database.py
│   ├── models.py
│   ├── schemas.py
│   └── routers/
│       ├── auth.py
│       ├── trips.py
│       └── payments.py
└── RwandaRide/
└── lib/
├── main.dart
├── config/
├── models/
├── providers/
├── screens/
│   ├── auth/
│   ├── rider/
│   └── driver/
├── services/
└── widgets/

## Developer

**Carine UMUGABEKAZI**
Software Engineering Student — African Leadership University, Kigali
bashcd ~/Desktop/rwandaride
