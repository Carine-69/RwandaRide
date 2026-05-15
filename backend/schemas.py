from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

# ─── USER SCHEMAS ───────────────────────────────

class UserRegister(BaseModel):
    name: str
    phone: str
    email: Optional[EmailStr] = None
    password: str
    role: str = "rider"
    # Driver specific fields
    license_number: Optional[str] = None
    vehicle_type: Optional[str] = None
    vehicle_plate: Optional[str] = None

class UserLogin(BaseModel):
    phone: Optional[str] = None
    email: Optional[EmailStr] = None
    password: str

class UserResponse(BaseModel):
    id: int
    name: str
    phone: str
    email: Optional[str] = None
    role: str
    created_at: datetime

    class Config:
        from_attributes = True

# ─── TRIP SCHEMAS ───────────────────────────────

class TripCreate(BaseModel):
    pickup_location: str
    destination: str
    pickup_lat: Optional[float] = None
    pickup_lng: Optional[float] = None
    dest_lat: Optional[float] = None
    dest_lng: Optional[float] = None
    vehicle_type: str = "moto" # default is moto since it's most common in Rwanda

class TripResponse(BaseModel):
    id: int
    rider_id: int
    driver_id: Optional[int] = None
    pickup_location: str
    destination: str
    fare: Optional[float] = None
    status: str
    created_at: datetime

    class Config:
        from_attributes = True

# ─── PAYMENT SCHEMAS ────────────────────────────

class PaymentCreate(BaseModel):
    trip_id: int
    amount: float
    method: str

class PaymentResponse(BaseModel):
    id: int
    trip_id: int
    amount: float
    method: str
    status: str
    created_at: datetime

    class Config:
        from_attributes = True

#_____Driver Info_____________________________________
class DriverInfo(BaseModel):
    name: str
    phone: str
    vehicle_type: str
    vehicle_plate: str

    class Config:
        from_attributes = True

class TripDetailResponse(BaseModel):
    id: int
    rider_id: int
    driver_id: Optional[int] = None
    pickup_location: str
    destination: str
    fare: Optional[float] = None
    status: str
    vehicle_type: Optional[str] = None
    distance: Optional[float] = None
    created_at: datetime
    driver: Optional[DriverInfo] = None

    class Config:
        from_attributes = True