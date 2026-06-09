from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import Payment, Trip, Driver
from schemas import PaymentCreate, PaymentResponse
from routers.auth import get_current_user
from models import User
from typing import List

router = APIRouter(prefix="/payments", tags=["Payments"])

@router.post("/", response_model=PaymentResponse)
def create_payment(payment: PaymentCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.role != "rider":
        raise HTTPException(status_code=403, detail="Only riders can make payments")
    trip = db.query(Trip).filter(Trip.id == payment.trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")
    if trip.rider_id != current_user.id:
        raise HTTPException(status_code=403, detail="This is not your trip")
    # use trip fare if payment amount is 0
    amount = payment.amount if payment.amount > 0 else (trip.fare or 0)
    new_payment = Payment(
        trip_id=payment.trip_id,
        user_id=current_user.id,
        amount=amount,
        method=payment.method,
        status="pending"
    )
    db.add(new_payment)
    db.commit()
    db.refresh(new_payment)
    return new_payment

@router.get("/my-payments", response_model=List[PaymentResponse])
def my_payments(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.role != "rider":
        raise HTTPException(status_code=403, detail="Only riders can view their payments")
    return db.query(Payment).filter(Payment.user_id == current_user.id).all()

@router.get("/wallet")
def driver_wallet(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.role != "driver":
        raise HTTPException(status_code=403, detail="Only drivers can view wallet")
    driver = db.query(Driver).filter(Driver.user_id == current_user.id).first()
    if not driver:
        raise HTTPException(status_code=404, detail="Driver profile not found")

    pending_payments = db.query(Payment).join(Trip).filter(
        Trip.driver_id == driver.id,
        Payment.status == "pending"
    ).all()

    completed_payments = db.query(Payment).join(Trip).filter(
        Trip.driver_id == driver.id,
        Payment.status == "completed"
    ).all()

    total_earned = sum(p.amount for p in completed_payments if p.amount)
    commission = total_earned * 0.15
    net = total_earned - commission

    return {
        "pending_payments": [
            {"id": p.id, "amount": p.amount, "method": p.method, "trip_id": p.trip_id}
            for p in pending_payments
        ],
        "total_trips": len(completed_payments),
        "gross_earnings": round(total_earned, 2),
        "commission": round(commission, 2),
        "net_earnings": round(net, 2),
        "currency": "RWF"
    }

@router.patch("/{payment_id}/confirm")
def confirm_payment(payment_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.role != "driver":
        raise HTTPException(status_code=403, detail="Only drivers can confirm payments")
    payment = db.query(Payment).filter(Payment.id == payment_id).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Payment not found")
    payment.status = "completed"
    # update trip status to paid so it moves to history
    trip = db.query(Trip).filter(Trip.id == payment.trip_id).first()
    if trip:
        trip.status = "paid"
    db.commit()
    db.refresh(payment)
    return {"message": "Payment confirmed", "payment_id": payment.id, "status": "completed"}

@router.get("/", response_model=List[PaymentResponse])
def get_payments(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return db.query(Payment).all()