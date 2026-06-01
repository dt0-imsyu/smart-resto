from datetime import datetime

from pydantic import BaseModel, Field


class MenuItemRead(BaseModel):
    id: int
    title: str
    description: str
    price: float
    category: str
    ingredients: str
    calories: int
    is_available: bool

    model_config = {"from_attributes": True}


class OrderItemCreate(BaseModel):
    menu_item_id: int
    quantity: int = Field(gt=0)


class OrderCreate(BaseModel):
    user_id: str = "guest"
    items: list[OrderItemCreate]


class OrderItemRead(BaseModel):
    id: int
    menu_item_id: int
    quantity: int
    menu_item: MenuItemRead

    model_config = {"from_attributes": True}


class OrderRead(BaseModel):
    id: int
    user_id: str
    total_price: float
    status: str
    created_at: datetime
    items: list[OrderItemRead]

    model_config = {"from_attributes": True}


class AiChatRequest(BaseModel):
    user_message: str = Field(min_length=1)
    current_cart: list[int] = []


class AiChatResponse(BaseModel):
    answer: str
    source: str


class AiUpsellRequest(BaseModel):
    current_cart: list[int] = []


class UpsellItem(BaseModel):
    id: int
    title: str
    reason: str


class AiUpsellResponse(BaseModel):
    upsell_items: list[UpsellItem]
    source: str
