from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import Payment, Trip, Driver
from schemas import PaymentCreate, PaymentResponse
from routers.auth import get_current_user
from models import User
from typing import List

router = APIRouter(prefix="/payments", tags=["Payments"])

# ─── MAKE A PAYMENT ─────────────────────────────
@router.post("/", response_model=PaymentResponse)
def create_payment(payment: PaymentCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.role != "rider":
        raise HTTPException(status_code=403, detail="Only riders can make payments")

    trip = db.query(Trip).filter(Trip.id == payment.trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")
    if trip.rider_id != current_user.id:
        raise HTTPException(status_code=403, detail="This is not your trip")

    new_payment = Payment(
        trip_id=payment.trip_id,
        user_id=current_user.id,
        amount=payment.amount,
        method=payment.method,
        status="completed"
    )
    db.add(new_payment)
    db.commit()
    db.refresh(new_payment)
    return new_payment

# ─── RIDER: MY PAYMENTS ─────────────────────────
@router.get("/my-payments", response_model=List[PaymentResponse])
def my_payments(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.role != "rider":
        raise HTTPException(status_code=403, detail="Only riders can view their payments")
    return db.query(Payment).filter(Payment.user_id == current_user.id).all()

# ─── DRIVER: MY EARNINGS ────────────────────────
@router.get("/my-earnings")
def my_earnings(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.role != "driver":
        raise HTTPException(status_code=403, detail="Only drivers can view earnings")

    driver = db.query(Driver).filter(Driver.user_id == current_user.id).first()
    if not driver:
        raise HTTPException(status_code=404, detail="Driver profile not found")

    # Get all completed trips for this driver
    completed_trips = db.query(Trip).filter(
        Trip.driver_id == driver.id,
        Trip.status == "completed"
    ).all()

    total_earnings = sum(trip.fare for trip in completed_trips if trip.fare)
    commission = total_earnings * 0.15  # RwandaRide takes 15%
    driver_earnings = total_earnings - commission

    return {
        "total_trips": len(completed_trips),
        "gross_earnings": round(total_earnings, 2),
        "commission_15_percent": round(commission, 2),
        "net_earnings": round(driver_earnings, 2),
        "currency": "RWF"
    }

# ─── GET ALL PAYMENTS (admin) ───────────────────
@router.get("/", response_model=List[PaymentResponse])
def get_payments(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return db.query(Payment).all()