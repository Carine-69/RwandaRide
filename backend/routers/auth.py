from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from database import get_db
from models import User, Driver
from schemas import UserRegister, UserLogin, UserResponse
from jose import jwt, JWTError
from datetime import datetime, timedelta
from dotenv import load_dotenv
import os
import bcrypt

load_dotenv()

router = APIRouter(prefix="/auth", tags=["Authentication"])

JWT_SECRET = os.getenv("JWT_SECRET")

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

# Helper — encrypt password
def hash_password(password: str):
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

# Helper — check password
def verify_password(plain: str, hashed: str):
    return bcrypt.checkpw(plain.encode('utf-8'), hashed.encode('utf-8'))

# Helper — create login token
def create_token(user_id: int, role: str):
    data = {
        "sub": str(user_id),
        "role": role,
        "exp": datetime.utcnow() + timedelta(days=7)
    }
    return jwt.encode(data, JWT_SECRET, algorithm="HS256")

# Helper — get current logged in user from token
def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        user_id = int(payload.get("sub"))
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    return user


# ─── REGISTER ───────────────────────────────────
@router.post("/register", response_model=UserResponse)
def register(user: UserRegister, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.phone == user.phone).first()
    if existing:
        raise HTTPException(status_code=400, detail="Phone already registered")

    new_user = User(
        name=user.name,
        phone=user.phone,
        email=user.email,
        password=hash_password(user.password),
        role=user.role
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    if user.role == "driver":
        if not user.license_number or not user.vehicle_type or not user.vehicle_plate:
            raise HTTPException(status_code=400, detail="Drivers must provide license, vehicle type and plate")

        new_driver = Driver(
            user_id=new_user.id,
            license_number=user.license_number,
            vehicle_type=user.vehicle_type,
            vehicle_plate=user.vehicle_plate,
            status="offline"
        )
        db.add(new_driver)
        db.commit()

    return new_user


# ─── LOGIN ──────────────────────────────────────
@router.post("/login")
def login(credentials: UserLogin, db: Session = Depends(get_db)):
    if not credentials.phone and not credentials.email:
        raise HTTPException(status_code=400, detail="Provide phone or email")

    if credentials.phone:
        user = db.query(User).filter(User.phone == credentials.phone).first()
    else:
        user = db.query(User).filter(User.email == credentials.email).first()

    if not user or not verify_password(credentials.password, user.password):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = create_token(user.id, user.role)

    return {
        "access_token": token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "name": user.name,
            "role": user.role
        }
    }

# ─── DRIVER: GO ONLINE / OFFLINE ────────────────
@router.patch("/driver/status")
def update_driver_status(status: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.role != "driver":
        raise HTTPException(status_code=403, detail="Only drivers can update status")

    if status not in ["online", "offline"]:
        raise HTTPException(status_code=400, detail="Status must be 'online' or 'offline'")

    driver = db.query(Driver).filter(Driver.user_id == current_user.id).first()
    if not driver:
        raise HTTPException(status_code=404, detail="Driver profile not found")

    driver.status = status
    db.commit()
    return {"message": f"You are now {status}", "status": status}