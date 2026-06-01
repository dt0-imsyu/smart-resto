from fastapi import Depends, FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session, joinedload

from .ai_service import chat_with_waiter, suggest_upsell
from .database import Base, engine, get_db
from .models import MenuItem, Order, OrderItem
from .schemas import (
    AiChatRequest,
    AiChatResponse,
    AiUpsellRequest,
    AiUpsellResponse,
    MenuItemRead,
    OrderCreate,
    OrderRead,
)


Base.metadata.create_all(bind=engine)

app = FastAPI(title="SmartResto API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/api/v1/menu", response_model=list[MenuItemRead])
def get_menu(
    category: str | None = Query(default=None),
    db: Session = Depends(get_db),
):
    query = db.query(MenuItem).filter(MenuItem.is_available.is_(True))
    if category:
        query = query.filter(MenuItem.category == category)
    return query.order_by(MenuItem.category, MenuItem.title).all()


@app.post("/api/v1/orders", response_model=OrderRead, status_code=201)
def create_order(payload: OrderCreate, db: Session = Depends(get_db)):
    if not payload.items:
        raise HTTPException(status_code=400, detail="Order must contain at least one item.")

    requested_ids = {item.menu_item_id for item in payload.items}
    menu_items = (
        db.query(MenuItem)
        .filter(MenuItem.id.in_(requested_ids), MenuItem.is_available.is_(True))
        .all()
    )
    menu_by_id = {item.id: item for item in menu_items}
    missing_ids = requested_ids - set(menu_by_id)
    if missing_ids:
        raise HTTPException(
            status_code=400,
            detail=f"Menu items are unavailable or missing: {sorted(missing_ids)}",
        )

    total_price = sum(menu_by_id[item.menu_item_id].price * item.quantity for item in payload.items)
    order = Order(user_id=payload.user_id, total_price=total_price, status="created")
    for item in payload.items:
        order.items.append(OrderItem(menu_item_id=item.menu_item_id, quantity=item.quantity))

    db.add(order)
    db.commit()
    db.refresh(order)
    return (
        db.query(Order)
        .options(joinedload(Order.items).joinedload(OrderItem.menu_item))
        .filter(Order.id == order.id)
        .one()
    )


@app.post("/api/v1/ai/chat", response_model=AiChatResponse)
def ai_chat(payload: AiChatRequest, db: Session = Depends(get_db)):
    answer, source = chat_with_waiter(db, payload.user_message, payload.current_cart)
    return AiChatResponse(answer=answer, source=source)


@app.post("/api/v1/ai/upsell", response_model=AiUpsellResponse)
def ai_upsell(payload: AiUpsellRequest, db: Session = Depends(get_db)):
    upsell_items, source = suggest_upsell(db, payload.current_cart)
    return AiUpsellResponse(upsell_items=upsell_items, source=source)
