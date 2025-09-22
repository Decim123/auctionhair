from pydantic import BaseModel, Field
from typing import Any, Dict, Optional
from typing import List
from datetime import datetime

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
    period: datetime
    step: int
    views: int
    status: int
    high_price: int

class Ask(BaseModel):
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
    period: datetime
    step: int
    views: int
    status: int
    high_price: int

class GetAuctionsRequest(BaseModel):
    tg_id: int

class GetAsksRequest(BaseModel):
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
    like: Optional[bool] = None
    people: Optional[bool] = None

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
    period: datetime
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
    period: Optional[datetime] = None
    step: Optional[int] = None
    views: Optional[int] = 0
    status: Optional[int] = 0
    high_price: Optional[int] = 0
    country: Optional[str] = None
    city: Optional[str] = None

class TradeRequest(BaseModel):
    lot_ids: List[int]
    tg_id: Optional[int] = None
    sort_by: Optional[str] = "default"

class MessageBase(BaseModel):
    sender_id: int
    receiver_id: int
    lot_id: int
    content: str

class MessageOut(MessageBase):
    id: int
    timestamp: str
    is_read: bool
class LotTradeRequest(BaseModel):
    lot_id: int
    user_id: int
    tg_id: int

class LotTradeResponse(BaseModel):
    avatar_url: str
    rating: int
    username: str
    price: int
    trader_id: int

class LotDetail(BaseModel):
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
    period: datetime
    step: int
    views: int
    status: int
    high_price: int
    country: str
    city: str

class LotDetailResponse(BaseModel):
    lot: LotDetail

class WalletAskModel(BaseModel):
    tg_id: int
    action: int
    amount: int
    lot_id: Optional[int] = None
    price: Optional[int] = None
    message: Optional[str] = None

class Card(BaseModel):
    id: int
    number: str
    system: str
    logo: str

class TransactionResponseModel(BaseModel):
    cards: List[Card]
    balance: float

class AddCardModel(BaseModel):
    tg_id: int
    number: str
    system: str
    logo: str

class PhoneUpdate(BaseModel):
    tg_id: int
    phone: str = Field(..., alias="номер телефона")


class EmailUpdate(BaseModel):
    tg_id: int
    email: str


class Settings(BaseModel):
    number: str
    email: str
    lang: str

class NotifySwitch(BaseModel):
    tg_id: int
    number: int
    value: bool


class Statistic(BaseModel):
    reg_date: str
    lots_created_up: int
    lots_created_down: int
    lots_created_requested: int
    lots_rejected_up: int
    lots_rejected_down: int
    lots_rejected_requested: int
    lots_sold_up: int
    lots_sold_down: int
    lots_sold_requested: int
    lots_in_up: int
    lots_in_down: int
    lots_in_requested: int
    lots_fail_up: int
    lots_fail_down: int
    lots_fail_requested: int
    lots_argue: int
    lots_argue_win: int
    lots_argue_lose: int


class ProfileViewResponse(BaseModel):
    username: str
    rating: int

class SetRatingRequest(BaseModel):
    tg_id: int
    receiver_id: int
    rating: int

class SetRatingResponse(BaseModel):
    average_rating: int

class TempDeleteRequest(BaseModel):
    tg_id: int
    media_id: int

class TempDeleteRequest(BaseModel):
    tg_id: int
    media_id: int

class ChangeUsernameRequest(BaseModel):
    tg_id: int
    username: str

class PhoneRequest(BaseModel):
    tg_id: int
    phone: str

class PhoneCheckRequest(BaseModel):
    tg_id: int
    phone: str

class ChangeBetRequest(BaseModel):
    tg_id: int
    lot_id: int
    amount: int

class AutoBetRequest(BaseModel):
    tg_id: int
    lot_id: int
    auto_step: int
    auto_limit: int

class ChatBtnRequest(BaseModel):
    lotId: int
    userId: int

class ChooseWinnerRequest(BaseModel):
    userId: int
    userId2: int
    lotId: int

class ChooseWinnerResponse(BaseModel):
    lotStatus: str

class WalletChatRequest(BaseModel):
    tg_id: int
    lotId: int
    action: Optional[int] = None

class WalletChatResponse(BaseModel):
    balance: int
    frozen_funds: int
    is_first: int
    price: int
    lotStatus: Optional[int] = None

class SendProveRequest(BaseModel):
    tg_id: int
    lotId: int
    photo: str
    action: int

class SendProveResponse(BaseModel):
    lotStatus: str

class LotRecieveRequest(BaseModel):
    lotId: int
    userId: int
    userId2: int

class LotRecieveResponse(BaseModel):
    lotStatus: str