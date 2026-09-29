import json
import time
import hashlib
from typing import List, Optional
from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, String, Float
from sqlalchemy.orm import declarative_base, sessionmaker
import os

# Get the absolute path to the Backend directory
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATABASE_URL = f"sqlite:///{os.path.join(BASE_DIR, 'queue.db')}"

# ------------------------------------------------------------------------------
# 1. DATABASE & BLOCKCHAIN SETUP
# ------------------------------------------------------------------------------
DATABASE_URL = "sqlite:///./queue.db"

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class TokenDB(Base):
    __tablename__ = "tokens"

    id = Column(String, primary_key=True, index=True)
    tokenNumber = Column(Integer)
    formattedToken = Column(String)
    userName = Column(String)
    userPhone = Column(String)
    departmentId = Column(String)
    departmentName = Column(String)
    status = Column(String, default="waiting")  # waiting, serving, completed, skipped
    bookedTime = Column(String)
    isSyncedBlockchain = Column(String, default="pending")

class BlockDB(Base):
    __tablename__ = "blockchain"

    id = Column(Integer, primary_key=True, autoincrement=True)
    blockIndex = Column(Integer)
    timestamp = Column(Float)
    eventType = Column(String)
    tokenId = Column(String)
    dataJson = Column(String)
    previousHash = Column(String)
    hash = Column(String)

Base.metadata.create_all(bind=engine)

def db():
    return SessionLocal()

# Blockchain Helper Functions
def calculate_hash(index: int, prev_hash: str, timestamp: float, event_type: str, data_json: str) -> str:
    payload = f"{index}{prev_hash}{timestamp}{event_type}{data_json}"
    return hashlib.sha256(payload.encode('utf-8')).hexdigest()

def add_block(session, event_type: str, token_id: str, data: dict):
    last_block = session.query(BlockDB).order_by(BlockDB.id.desc()).first()
    
    if last_block:
        index = last_block.blockIndex + 1
        prev_hash = last_block.hash
    else:
        index = 0
        prev_hash = "0000000000000000000000000000000000000000000000000000000000000000"

    timestamp = time.time()
    data_json = json.dumps(data)
    curr_hash = calculate_hash(index, prev_hash, timestamp, event_type, data_json)

    new_block = BlockDB(
        blockIndex=index,
        timestamp=timestamp,
        eventType=event_type,
        tokenId=token_id,
        dataJson=data_json,
        previousHash=prev_hash,
        hash=curr_hash
    )
    session.add(new_block)

def token_to_dict(t: TokenDB) -> dict:
    return {
        "id": t.id,
        "tokenNumber": t.tokenNumber,
        "formattedToken": t.formattedToken,
        "userName": t.userName,
        "userPhone": t.userPhone,
        "departmentId": t.departmentId,
        "departmentName": t.departmentName,
        "status": t.status,
        "bookedTime": t.bookedTime,
        "isSyncedBlockchain": t.isSyncedBlockchain
    }

# ------------------------------------------------------------------------------
# 2. FASTAPI APP & WEBSOCKET MANAGER
# ------------------------------------------------------------------------------
app = FastAPI(title="Smart Queue System Backend")

# Enable CORS for Flutter Web cross-origin requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)

    async def broadcast(self, message: str):
        # Iterate over copy to prevent mutation issues during disconnection
        for connection in list(self.active_connections):
            try:
                await connection.send_text(message)
            except Exception:
                self.disconnect(connection)

manager = ConnectionManager()

@app.websocket("/ws/queue")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            await websocket.receive_text()  # Keep connection active
    except WebSocketDisconnect:
        manager.disconnect(websocket)

# ------------------------------------------------------------------------------
# 3. PYDANTIC SCHEMAS
# ------------------------------------------------------------------------------
class TokenCreateSchema(BaseModel):
    userName: str
    userPhone: str
    departmentId: Optional[str] = "dept-1"

class OfflineTokenSchema(BaseModel):
    userName: str
    userPhone: str
    departmentId: Optional[str] = "dept-1"
    offlineCreatedAt: Optional[str] = None

# ------------------------------------------------------------------------------
# 4. API ENDPOINTS
# ------------------------------------------------------------------------------

@app.get("/tokens")
def get_all_tokens():
    s = db()
    try:
        tokens = s.query(TokenDB).all()
        return [token_to_dict(t) for t in tokens]
    finally:
        s.close()

@app.post("/tokens")
async def create_token(data: TokenCreateSchema):
    s = db()
    try:
        count = s.query(TokenDB).count()
        next_num = count + 1
        token_id = f"tok-{next_num}"
        formatted = f"A-{next_num:03d}"
        booked_time = time.strftime("%Y-%m-%d %H:%M:%S")

        new_token = TokenDB(
            id=token_id,
            tokenNumber=next_num,
            formattedToken=formatted,
            userName=data.userName,
            userPhone=data.userPhone,
            departmentId=data.departmentId,
            departmentName="General Enquiries",
            status="waiting",
            bookedTime=booked_time,
            isSyncedBlockchain="synced"
        )
        s.add(new_token)
        
        # Add block to audit ledger
        add_block(s, "TOKEN_CREATED", token_id, token_to_dict(new_token))
        s.commit()
        s.refresh(new_token)

        # Broadcast update as valid JSON string over WebSockets
        event_payload = json.dumps({"event": "TOKEN_CREATED", "data": token_to_dict(new_token)})
        await manager.broadcast(event_payload)

        return token_to_dict(new_token)
    except Exception as e:
        s.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        s.close()

@app.post("/tokens/sync-offline")
async def sync_offline_tokens(tokens: List[OfflineTokenSchema]):
    s = db()
    synced_results = []
    try:
        for item in tokens:
            count = s.query(TokenDB).count()
            next_num = count + 1
            token_id = f"tok-{next_num}"
            formatted = f"A-{next_num:03d}"
            booked_time = item.offlineCreatedAt or time.strftime("%Y-%m-%d %H:%M:%S")

            new_token = TokenDB(
                id=token_id,
                tokenNumber=next_num,
                formattedToken=formatted,
                userName=item.userName,
                userPhone=item.userPhone,
                departmentId=item.departmentId,
                departmentName="General Enquiries",
                status="waiting",
                bookedTime=booked_time,
                isSyncedBlockchain="synced"
            )
            s.add(new_token)
            add_block(s, "OFFLINE_TOKEN_SYNCED", token_id, token_to_dict(new_token))
            synced_results.append(token_to_dict(new_token))

        s.commit()

        # Broadcast update for all synced tokens
        event_payload = json.dumps({"event": "TOKENS_SYNCED", "count": len(synced_results)})
        await manager.broadcast(event_payload)

        return {"status": "success", "syncedCount": len(synced_results)}
    except Exception as e:
        s.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        s.close()

@app.post("/queue/call-next/{department_id}")
async def call_next_token(department_id: str):
    s = db()
    try:
        # Find earliest waiting token
        next_token = s.query(TokenDB).filter(
            TokenDB.status == "waiting"
        ).order_by(TokenDB.tokenNumber.asc()).first()

        if not next_token:
            raise HTTPException(status_code=404, detail="No waiting tokens in line.")

        next_token.status = "serving"
        add_block(s, "TOKEN_CALLED", next_token.id, {"tokenId": next_token.id, "status": "serving"})
        s.commit()
        s.refresh(next_token)

        event_payload = json.dumps({"event": "TOKEN_CALLED", "data": token_to_dict(next_token)})
        await manager.broadcast(event_payload)

        return token_to_dict(next_token)
    except HTTPException:
        raise
    except Exception as e:
        s.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        s.close()

@app.patch("/tokens/{token_id}/status")
async def update_token_status(token_id: str, status: str):
    s = db()
    try:
        token = s.query(TokenDB).filter(TokenDB.id == token_id).first()
        if not token:
            raise HTTPException(status_code=404, detail="Token not found.")

        token.status = status
        add_block(s, f"TOKEN_{status.upper()}", token_id, {"tokenId": token_id, "status": status})
        s.commit()
        s.refresh(token)

        event_payload = json.dumps({"event": "STATUS_UPDATED", "tokenId": token_id, "status": status})
        await manager.broadcast(event_payload)

        return token_to_dict(token)
    except HTTPException:
        raise
    except Exception as e:
        s.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        s.close()

@app.post("/tokens/{token_id}/skip")
async def skip_token(token_id: str):
    s = db()
    try:
        token = s.query(TokenDB).filter(TokenDB.id == token_id).first()
        if not token:
            raise HTTPException(status_code=404, detail="Token not found")

        token.status = "skipped"
        add_block(s, "TOKEN_SKIPPED", token_id, {"tokenId": token_id, "status": "skipped"})
        s.commit()

        event_payload = json.dumps({"event": "TOKEN_SKIPPED", "tokenId": token_id})
        await manager.broadcast(event_payload)

        return {"success": True}
    except HTTPException:
        raise
    except Exception as e:
        s.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        s.close()

@app.get("/blockchain")
def get_blockchain():
    s = db()
    try:
        blocks = s.query(BlockDB).order_by(BlockDB.id.asc()).all()
        return [
            {
                "id": b.id,
                "blockIndex": b.blockIndex,
                "timestamp": b.timestamp,
                "eventType": b.eventType,
                "tokenId": b.tokenId,
                "dataJson": json.loads(b.dataJson) if b.dataJson else {},
                "previousHash": b.previousHash,
                "hash": b.hash
            }
            for b in blocks
        ]
    finally:
        s.close()