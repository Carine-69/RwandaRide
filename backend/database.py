from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv
import os

#load environment
load_dotenv()

#get database url from .env
DATABASE_URL = os.getenv("DATABASE_URL")

#connect to postgres
engine = create_engine(DATABASE_URL)

# each session gets its won database session
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


#base for all our models
Base = declarative_base()

#get database sessions
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
