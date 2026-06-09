from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import Trip, Driver
from schemas import TripCreate, TripResponse, TripDetailResponse
from routers.auth import get_current_user
from models import User
from typing import List
import math
from datetime import datetime

router = APIRouter(prefix="/trips", tags=["Trips"])

def calculate_fare(pickup_lat, pickup_lng, dest_lat, dest_lng, vehicle_type):
    R = 6371
    lat1, lon1 = math.radians(pickup_lat), math.radians(pickup_lng)
    lat2, lon2 = math.radians(dest_lat), math.radians(dest_lng)
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
    distance = R * 2 * math.asin(math.sqrt(a))
    rates = {"moto": 200, "economy": 350, "standard": 500, "xl": 700}
    base_fare = 500
    rate = rates.get(vehicle_type, 350)
    fare = base_fare + (distance * rate)
    return round(fare, 2), round(distance, 2)

@router.post("/", response_model=TripResponse)
def create_trip(trip: TripCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.role != "rider":
        raise HTTPException(status_code=403, detail="Only riders can book trips")
    fare = None
    distance = None
    if trip.pickup_lat and trip.pickup_lng and trip.dest_lat and trip.dest_lng:
        fare, distance = calculate_fare(trip.pickup_lat, trip.pickup_lng, trip.dest_lat, trip.dest_lng, trip.vehicle_type)
    new_trip = Trip(
        rider_id=current_user.id,
        pickup_location=trip.pickup_location,
        destination=trip.destination,
        pickup_lat=trip.pickup_lat,
        pickup_lng=trip.pickup_lng,
        dest_lat=trip.dest_lat,
        dest_lng=trip.dest_lng,
        vehicle_type=trip.vehicle_type,
        fare=fare,
        distance=distance,
        status="requested"
    )
    db.add(new_trip)
    db.commit()
    db.refresh(new_trip)
    return new_trip

@router.get("/my-trips", response_model=List[TripResponse])
def my_trips(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.role != "rider":
        raise HTTPException(status_code=403, detail="Only riders can view trip history")
    return db.query(Trip).filter(Trip.rider_id == current_user.id).order_by(Trip.created_at.desc()).all()

@router.get("/available", response_model=List[TripResponse])
def available_trips(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.role != "driver":
        raise HTTPException(status_code=403, detail="Only drivers can view available trips")
    driver = db.query(Driver).filter(Driver.user_id == current_user.id).first()
    if not driver:
        raise HTTPException(status_code=404, detail="Driver profile not found")
    return db.query(Trip).filter(
        Trip.vehicle_type == driver.vehicle_type,
        Trip.status == "requested"
    ).all()

@router.get("/driver-trips", response_model=List[TripResponse])
def get_driver_trips(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.role != "driver":
        raise HTTPException(status_code=403, detail="Only drivers can view their trips")
    driver = db.query(Driver).filter(Driver.user_id == current_user.id).first()
    if not driver:
        raise HTTPException(status_code=404, detail="Driver profile not found")
    return db.query(Trip).filter(
        Trip.driver_id == driver.id,
        Trip.status.in_(['accepted', 'driver_arrived', 'ongoing', 'completed', 'paid'])
    ).order_by(Trip.created_at.desc()).all()

@router.patch("/{trip_id}/accept", response_model=TripResponse)
def accept_trip(trip_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.role != "driver":
        raise HTTPException(status_code=403, detail="Only drivers can accept trips")
    driver = db.query(Driver).filter(Driver.user_id == current_user.id).first()
    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")
    if trip.status != "requested":
        raise HTTPException(status_code=400, detail="Trip is no longer available")
    trip.driver_id = driver.id
    trip.status = "accepted"
    db.commit()
    db.refresh(trip)
    return trip

@router.patch("/{trip_id}/complete", response_model=TripResponse)
def complete_trip(trip_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.role != "driver":
        raise HTTPException(status_code=403, detail="Only drivers can complete trips")
    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")
    trip.status = "completed"
    trip.completed_at = datetime.utcnow()
    db.commit()
    db.refresh(trip)
    return trip

@router.patch("/{trip_id}/cancel", response_model=TripResponse)
def cancel_trip(trip_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")
    if trip.status not in ["requested", "accepted"]:
        raise HTTPException(status_code=400, detail="Trip cannot be cancelled")
    trip.status = "cancelled"
    db.commit()
    db.refresh(trip)
    return trip

@router.get("/", response_model=List[TripResponse])
def get_trips(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return db.query(Trip).all()

@router.get("/{trip_id}/detail")
def get_trip_detail(trip_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")
    driver_info = None
    if trip.driver_id:
        driver = db.query(Driver).filter(Driver.id == trip.driver_id).first()
        if driver:
            driver_user = db.query(User).filter(User.id == driver.user_id).first()
            driver_info = {
                "name": driver_user.name,
                "phone": driver_user.phone,
                "vehicle_type": driver.vehicle_type,
                "vehicle_plate": driver.vehicle_plate
            }
    return {
        "id": trip.id,
        "rider_id": trip.rider_id,
        "driver_id": trip.driver_id,
        "pickup_location": trip.pickup_location,
        "destination": trip.destination,
        "fare": trip.fare,
        "status": trip.status,
        "vehicle_type": trip.vehicle_type,
        "distance": trip.distance,
        "created_at": str(trip.created_at),
        "started_at": str(trip.started_at) if trip.started_at else None,
        "completed_at": str(trip.completed_at) if trip.completed_at else None,
        "driver": driver_info
    }

@router.get("/{trip_id}/invoice")
def get_invoice(trip_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")
    rider = db.query(User).filter(User.id == trip.rider_id).first()
    driver_info = None
    if trip.driver_id:
        driver = db.query(Driver).filter(Driver.id == trip.driver_id).first()
        if driver:
            driver_user = db.query(User).filter(User.id == driver.user_id).first()
            driver_info = {
                "name": driver_user.name,
                "phone": driver_user.phone,
                "vehicle_type": driver.vehicle_type,
                "vehicle_plate": driver.vehicle_plate
            }
    return {
        "invoice_number": f"RWR-{trip.id:05d}",
        "date": trip.created_at.strftime("%Y-%m-%d %H:%M"),
        "rider_name": rider.name,
        "driver": driver_info,
        "pickup_location": trip.pickup_location,
        "destination": trip.destination,
        "distance_km": trip.distance,
        "fare": trip.fare,
        "status": trip.status,
        "currency": "RWF"
    }

@router.patch("/{trip_id}/status")
def update_status(trip_id: int, status: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")
    trip.status = status
    if status == 'ongoing':
        trip.started_at = datetime.utcnow()
    if status == 'completed':
        trip.completed_at = datetime.utcnow()
    db.commit()
    db.refresh(trip)
    return {
        "id": trip.id,
        "status": trip.status,
        "started_at": str(trip.started_at) if trip.started_at else None,
        "completed_at": str(trip.completed_at) if trip.completed_at else None,
    }