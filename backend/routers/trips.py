from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import Trip, Driver
from schemas import TripCreate, TripResponse, TripDetailResponse
from routers.auth import get_current_user
from models import User
from typing import List
import math

router = APIRouter(prefix="/trips", tags=["Trips"])

# ─── FARE CALCULATION ───────────────────────────
def calculate_fare(pickup_lat, pickup_lng, dest_lat, dest_lng, vehicle_type):
    # Haversine formula — calculates distance between two GPS points
    R = 6371  # Earth radius in km
    lat1, lon1 = math.radians(pickup_lat), math.radians(pickup_lng)
    lat2, lon2 = math.radians(dest_lat), math.radians(dest_lng)
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
    distance = R * 2 * math.asin(math.sqrt(a))

    # Price per km in RWF per vehicle type
    rates = {
        "moto": 200,
        "economy": 350,
        "standard": 500,
        "xl": 700
    }
    base_fare = 500  # base fare in RWF
    rate = rates.get(vehicle_type, 350)
    fare = base_fare + (distance * rate)
    return round(fare, 2), round(distance, 2)

# ─── RIDER: REQUEST A RIDE ──────────────────────
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

# ─── RIDER: MY TRIP HISTORY ─────────────────────
@router.get("/my-trips", response_model=List[TripResponse])
def my_trips(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.role != "rider":
        raise HTTPException(status_code=403, detail="Only riders can view trip history")
    return db.query(Trip).filter(Trip.rider_id == current_user.id).all()

# ─── DRIVER: SEE AVAILABLE TRIPS ────────────────
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

# ─── DRIVER: ACCEPT A TRIP ──────────────────────
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

# ─── DRIVER: COMPLETE A TRIP ────────────────────
@router.patch("/{trip_id}/complete", response_model=TripResponse)
def complete_trip(trip_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.role != "driver":
        raise HTTPException(status_code=403, detail="Only drivers can complete trips")

    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")
    if trip.status != "accepted":
        raise HTTPException(status_code=400, detail="Trip is not ongoing")

    trip.status = "completed"
    db.commit()
    db.refresh(trip)
    return trip

# ─── RIDER: CANCEL A TRIP ───────────────────────
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

# ─── GET ALL TRIPS (admin) ───────────────────────
@router.get("/", response_model=List[TripResponse])
def get_trips(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return db.query(Trip).all()

# ─── GET ONE TRIP ───────────────────────────────
@router.get("/{trip_id}/detail", response_model=TripDetailResponse)
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
        "created_at": trip.created_at,
        "driver": driver_info
    }

# ─── UPDATE TRIP STATUS ─────────────────────────
@router.patch("/{trip_id}/status")
def update_status(trip_id: int, status: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")
    trip.status = status
    db.commit()
    return {"message": f"Trip status updated to {status}"}