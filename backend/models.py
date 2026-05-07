from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    phone = Column(String, unique=True, nullable=False)
    email = Column(String, unique=True)
    password = Column(String, nullable=False)
    role = Column(String, default="rider")
    created_at = Column(DateTime, default=datetime.utcnow)

class Driver(Base):
    __tablename__ = "drivers"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    license_number = Column(String, unique=True, nullable=False)
    vehicle_type = Column(String, nullable=False)
    vehicle_plate = Column(String, unique=True, nullable=False)
    status = Column(String, default="offline")
    created_at = Column(DateTime, default=datetime.utcnow)

class Trip(Base):
    __tablename__ = "trips"

    id = Column(Integer, primary_key=True, index=True)
    rider_id = Column(Integer, ForeignKey("users.id"))
    driver_id = Column(Integer, ForeignKey("drivers.id"))
    pickup_location = Column(String, nullable=False)
    destination = Column(String, nullable=False)
    vehicle_type = Column(String, default="moto")
    pickup_lat = Column(Float)
    pickup_lng = Column(Float)
    dest_lat = Column(Float)
    dest_lng = Column(Float)
    distance = Column(Float)
    fare = Column(Float)
    status = Column(String, default="requested")
    created_at = Column(DateTime, default=datetime.utcnow)

class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True, index=True)
    trip_id = Column(Integer, ForeignKey("trips.id"))
    user_id = Column(Integer, ForeignKey("users.id"))
    amount = Column(Float, nullable=False)
    method = Column(String, nullable=False)
    status = Column(String, default="pending")
    transaction_id = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)