from pydantic import BaseModel, Field
from typing import Optional
from typing import List

# Модель для получения информации о пользователе
class UserRequest(BaseModel):
    tg_id: int
    function: str

# Модель для запроса информации о пользователе
class InfoRequest(BaseModel):
    tg_id: int
    fields: List[str]

# Модель для старта с Telegram
class TgStart(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    full_name: Optional[str] = None
    username: Optional[str] = None
    user_id: int
    is_premium: Optional[bool] = None
    language_code: Optional[str] = None

# Модель для создания работника
class InitWorker(BaseModel):
    tg_id: int
    username: str
    full_name: Optional[str] = None
    key: str

# Модель ключа
class KeyModel(BaseModel):
    key: str

class AdminModel(BaseModel):
    tg_id: int

class Auction(BaseModel):
    id: int
    tg_id: int
    lot_type: str
    long: int
    natural_color: str
    now_color: str
    type: str
    age: int
    weight: int
    description: str
    price: int
    period: int
    step: int
    views: int
    status: int
    high_price: int

class GetAuctionsRequest(BaseModel):
    tg_id: int

class SortParameters(BaseModel):
    trade_type: Optional[str] = None
    trade_status: Optional[str] = None
    min_price: Optional[int] = None
    max_price: Optional[int] = None
    min_length: Optional[int] = None
    max_length: Optional[int] = None
    natural_hair_colors: Optional[List[str]] = Field(default_factory=list)
    current_hair_colors: Optional[List[str]] = Field(default_factory=list)
    hair_types: Optional[List[str]] = Field(default_factory=list)
    countries: Optional[List[str]] = Field(default_factory=list)
    regions: Optional[List[str]] = Field(default_factory=list)
    min_donor_age: Optional[int] = None
    max_donor_age: Optional[int] = None
    min_weight: Optional[int] = None
    max_weight: Optional[int] = None
    tg_id: Optional[int] = None  # Добавляем tg_id для получения региона и страны пользователя

class Lot(BaseModel):
    id: int
    tg_id: int
    lot_type: str
    long: int
    natural_color: str
    now_color: str
    type: str
    age: int
    weight: int
    description: Optional[str]
    price: int
    period: int
    step: int
    views: int
    status: int
    high_price: int

class SortResponse(BaseModel):
    lots: List[int]

class LotDetailResponse(BaseModel):
    lot: Lot

class LotData(BaseModel):
    tg_id: int
    amount: str
    length: str
    age: str
    weight: str
    description: str
    price: str
    natural_color: str
    current_color: str
    hair_type: str
    auction_duration: str

class SortByRequest(BaseModel):
    sort_by: str
    lots: List[int]

class LotShortInfoRequest(BaseModel):
    number: int
    userId: int

class LotShortInfoResponse(BaseModel):
    like: int
    step: int
    period: int
    lot_type: str
    status: str
    long: int
    weight: int
    views: int

class LikeRequest(BaseModel):
    userId: int  # tg_id пользователя
    lot_id: int

class LikeResponse(BaseModel):
    success: bool
    message: str

class LotID(BaseModel):
    lot_id: int
class LotDataFull(BaseModel):
    id: int
    tg_id: int
    lot_type: Optional[str] = None
    long: Optional[int] = None
    natural_color: Optional[str] = None
    now_color: Optional[str] = None
    type: Optional[str] = None
    age: Optional[int] = None
    weight: Optional[int] = None
    description: Optional[str] = None
    price: Optional[int] = None
    period: Optional[int] = None
    step: Optional[int] = None
    views: Optional[int] = 0
    status: Optional[int] = 0
    high_price: Optional[int] = 0