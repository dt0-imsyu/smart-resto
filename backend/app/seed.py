import json

from .database import Base, SessionLocal, engine
from .models import MenuItem, Order, OrderItem


MENU_ITEMS = [
    {
        "title": "Пицца Маргарита",
        "description": "Классическая пицца с томатным соусом, моцареллой и свежим базиликом.",
        "price": 620,
        "category": "Пицца",
        "ingredients": ["тесто", "томаты", "моцарелла", "базилик", "оливковое масло"],
        "calories": 780,
    },
    {
        "title": "Пицца Пепперони",
        "description": "Пикантная пицца с пепперони, моцареллой и насыщенным томатным соусом.",
        "price": 740,
        "category": "Пицца",
        "ingredients": ["тесто", "пепперони", "моцарелла", "томатный соус", "орегано"],
        "calories": 920,
    },
    {
        "title": "Пицца Четыре сыра",
        "description": "Сливочная пицца с моцареллой, горгонзолой, пармезаном и чеддером.",
        "price": 790,
        "category": "Пицца",
        "ingredients": ["тесто", "моцарелла", "горгонзола", "пармезан", "чеддер"],
        "calories": 980,
    },
    {
        "title": "Суши Филадельфия",
        "description": "Ролл с лососем, сливочным сыром, огурцом и рисом.",
        "price": 560,
        "category": "Суши",
        "ingredients": ["лосось", "сливочный сыр", "огурец", "рис", "нори"],
        "calories": 430,
    },
    {
        "title": "Ролл Калифорния",
        "description": "Ролл с крабом, авокадо, огурцом и икрой масаго.",
        "price": 520,
        "category": "Суши",
        "ingredients": ["краб", "авокадо", "огурец", "рис", "масаго"],
        "calories": 410,
    },
    {
        "title": "Сет Сакура",
        "description": "Ассорти роллов с лососем, тунцом, креветкой и острым соусом.",
        "price": 1490,
        "category": "Суши",
        "ingredients": ["лосось", "тунец", "креветка", "рис", "спайси соус"],
        "calories": 1120,
    },
    {
        "title": "Стейк из лосося",
        "description": "Обжаренный лосось с лимонным соусом и овощами гриль.",
        "price": 1180,
        "category": "Горячее",
        "ingredients": ["лосось", "лимон", "цукини", "перец", "оливковое масло"],
        "calories": 640,
    },
    {
        "title": "Паста Карбонара",
        "description": "Спагетти с беконом, сливочным соусом, пармезаном и черным перцем.",
        "price": 690,
        "category": "Горячее",
        "ingredients": ["спагетти", "бекон", "сливки", "пармезан", "яйцо"],
        "calories": 860,
    },
    {
        "title": "Салат Цезарь с курицей",
        "description": "Салат романо, куриная грудка, сухарики, пармезан и соус Цезарь.",
        "price": 510,
        "category": "Салаты",
        "ingredients": ["курица", "романо", "пармезан", "сухарики", "соус Цезарь"],
        "calories": 470,
    },
    {
        "title": "Греческий салат",
        "description": "Овощной салат с фетой, оливками и легкой заправкой.",
        "price": 460,
        "category": "Салаты",
        "ingredients": ["томаты", "огурец", "фета", "оливки", "оливковое масло"],
        "calories": 320,
    },
    {
        "title": "Картофель фри с трюфельным соусом",
        "description": "Хрустящий картофель фри с ароматным трюфельным соусом.",
        "price": 290,
        "category": "Закуски",
        "ingredients": ["картофель", "соль", "трюфельный соус"],
        "calories": 520,
    },
    {
        "title": "Кола",
        "description": "Охлажденный газированный напиток, 330 мл.",
        "price": 180,
        "category": "Напитки",
        "ingredients": ["газированная вода", "сахар", "карамель", "кофеин"],
        "calories": 139,
    },
    {
        "title": "Домашний лимонад",
        "description": "Освежающий лимонад с лимоном, мятой и легкой сладостью.",
        "price": 260,
        "category": "Напитки",
        "ingredients": ["лимон", "мята", "сахар", "газированная вода"],
        "calories": 110,
    },
    {
        "title": "Вино Шато",
        "description": "Красное сухое вино с ягодным ароматом, бокал 150 мл.",
        "price": 540,
        "category": "Напитки",
        "ingredients": ["красный виноград"],
        "calories": 125,
    },
    {
        "title": "Тирамису",
        "description": "Итальянский десерт с маскарпоне, кофе и печеньем савоярди.",
        "price": 390,
        "category": "Десерты",
        "ingredients": ["маскарпоне", "кофе", "савоярди", "какао", "яйцо"],
        "calories": 460,
    },
    {
        "title": "Чизкейк Нью-Йорк",
        "description": "Кремовый чизкейк на песочной основе с ягодным соусом.",
        "price": 410,
        "category": "Десерты",
        "ingredients": ["сливочный сыр", "печенье", "сливки", "ягодный соус"],
        "calories": 520,
    },
]


def seed_database() -> int:
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        db.query(OrderItem).delete()
        db.query(Order).delete()
        db.query(MenuItem).delete()
        for item in MENU_ITEMS:
            db.add(
                MenuItem(
                    **{
                        **item,
                        "ingredients": json.dumps(item["ingredients"], ensure_ascii=False),
                        "is_available": True,
                    }
                )
            )
        db.commit()
        return len(MENU_ITEMS)
    finally:
        db.close()


if __name__ == "__main__":
    count = seed_database()
    print(f"Seeded {count} menu items into SmartResto database.")
