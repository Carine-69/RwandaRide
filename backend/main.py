from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine
import models
from routers import auth, trips, payments

# Create all tables
models.Base.metadata.create_all(bind=engine)

# Create the app
app = FastAPI(
    title="RwandaRide API",
    description="Backend API for RwandaRide - Rwanda's ride hailing platform",
    version="1.0.0"
)

# Allow Flutter app to talk to our API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register all routers
app.include_router(auth.router)
app.include_router(trips.router)
app.include_router(payments.router)

# Home route
@app.get("/")
def home():
    return {
        "message": "Welcome to RwandaRide API 🚗",
        "version": "1.0.0",
        "status": "running"
    }