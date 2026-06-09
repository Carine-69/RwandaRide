from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from database import get_db
from models import User, Driver
from schemas import UserCreate, UserResponse, LoginRequest
import bcrypt
import jwt
import os
from datetime import datetime, timedelta

router = APIRouter(prefix="/auth", tags=["Auth"])
security = HTTPBearer()

JWT_SECRET = os.getenv("JWT_SECRET", "rwandaride_secret_key_2026")
JWT_ALGORITHM = "HS256"
JWT_EXPIRY_DAYS = 7

def create_token(user_id: int) -> str:
    payload = {
        "sub": str(user_id),
        "exp": datetime.utcnow() + timedelta(days=JWT_EXPIRY_DAYS),
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)

def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db),
) -> User:
    try:
        payload = jwt.decode(credentials.credentials, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        user_id = int(payload["sub"])
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    return user

@router.post("/register")
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    if user_data.role == "driver":
        if not user_data.license_number or not user_data.vehicle_plate or not user_data.vehicle_type:
            raise HTTPException(status_code=400, detail="Drivers must provide license, plate and vehicle type")

    existing = db.query(User).filter(User.phone == user_data.phone).first()
    if existing:
        raise HTTPException(status_code=400, detail="Phone number already registered")

    if user_data.email:
        existing_email = db.query(User).filter(User.email == user_data.email).first()
        if existing_email:
            raise HTTPException(status_code=400, detail="Email already registered")

    hashed = bcrypt.hashpw(user_data.password.encode(), bcrypt.gensalt()).decode()

    user = User(
        name=user_data.name,
        phone=user_data.phone,
        email=user_data.email,
        password=hashed,
        role=user_data.role,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    if user_data.role == "driver":
        driver = Driver(
            user_id=user.id,
            license_number=user_data.license_number,
            vehicle_plate=user_data.vehicle_plate,
            vehicle_type=user_data.vehicle_type,
        )
        db.add(driver)
        db.commit()

    token = create_token(user.id)
    return {
        "access_token": token,
        "user": {
            "id": user.id,
            "name": user.name,
            "phone": user.phone,
            "email": user.email,
            "role": user.role,
            "created_at": str(user.created_at),
        }
    }

@router.post("/login")
def login(data: LoginRequest, db: Session = Depends(get_db)):
    user = None
    if data.phone:
        user = db.query(User).filter(User.phone == data.phone).first()
    elif data.email:
        user = db.query(User).filter(User.email == data.email).first()

    if not user:
        raise HTTPException(status_code=401, detail="User not found")

    if not bcrypt.checkpw(data.password.encode(), user.password.encode()):
        raise HTTPException(status_code=401, detail="Wrong password")

    token = create_token(user.id)
    return {
        "access_token": token,
        "user": {
            "id": user.id,
            "name": user.name,
            "phone": user.phone,
            "email": user.email,
            "role": user.role,
            "created_at": str(user.created_at),
        }
    }

@router.get("/me")
def get_me(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    driver_info = None
    if current_user.role == "driver":
        driver = db.query(Driver).filter(Driver.user_id == current_user.id).first()
        if driver:
            driver_info = {
                "license_number": driver.license_number,
                "vehicle_plate": driver.vehicle_plate,
                "vehicle_type": driver.vehicle_type,
                "is_online": driver.is_online,
            }
    return {
        "id": current_user.id,
        "name": current_user.name,
        "phone": current_user.phone,
        "email": current_user.email,
        "role": current_user.role,
        "created_at": str(current_user.created_at),
        "driver_info": driver_info,
    }

@router.patch("/driver/status")
def update_driver_status(
    status: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != "driver":
        raise HTTPException(status_code=403, detail="Only drivers can update status")
    driver = db.query(Driver).filter(Driver.user_id == current_user.id).first()
    if not driver:
        raise HTTPException(status_code=404, detail="Driver profile not found")
    driver.is_online = status == "online"
    db.commit()
    return {"message": f"Status updated to {status}"}