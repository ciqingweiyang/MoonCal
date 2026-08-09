///|
pub fn DateTime::DateTime(
  year : Int,
  month : Int,
  day : Int,
  hour? : Int = 0,
  minute? : Int = 0,
  second? : Int = 0,
  is_date? : Bool = false,
  is_utc? : Bool = false,
) -> DateTime {
  DateTime::{ year, month, day, hour, minute, second, is_date, is_utc }
}

///|
pub fn is_leap_year(year : Int) -> Bool {
  year % 400 == 0 || (year % 4 == 0 && year % 100 != 0)
}

///|
pub fn days_in_month(year : Int, month : Int) -> Int {
  match month {
    1 | 3 | 5 | 7 | 8 | 10 | 12 => 31
    4 | 6 | 9 | 11 => 30
    2 => if is_leap_year(year) { 29 } else { 28 }
    _ => 0
  }
}

///|
pub fn is_valid_date(year : Int, month : Int, day : Int) -> Bool {
  year >= 1 &&
  month >= 1 &&
  month <= 12 &&
  day >= 1 &&
  day <= days_in_month(year, month)
}

///|
pub fn DateTime::is_valid(self : DateTime) -> Bool {
  is_valid_date(self.year, self.month, self.day) &&
  self.hour >= 0 &&
  self.hour <= 23 &&
  self.minute >= 0 &&
  self.minute <= 59 &&
  self.second >= 0 &&
  self.second <= 60
}

///|
pub fn DateTime::date_key(self : DateTime) -> Int {
  date_number(self.year, self.month, self.day)
}

///|

///|
pub fn DateTime::compare(self : DateTime, other : DateTime) -> Int {
  let date_cmp = self.date_key().compare(other.date_key())
  if date_cmp != 0 {
    return date_cmp
  }
  let self_seconds = self.hour * 3600 + self.minute * 60 + self.second
  let other_seconds = other.hour * 3600 + other.minute * 60 + other.second
  self_seconds.compare(other_seconds)
}

///|
pub fn DateTime::before(self : DateTime, other : DateTime) -> Bool {
  self.compare(other) < 0
}

///|
pub fn DateTime::after(self : DateTime, other : DateTime) -> Bool {
  self.compare(other) > 0
}

///|
pub fn DateTime::same_day(self : DateTime, other : DateTime) -> Bool {
  self.year == other.year && self.month == other.month && self.day == other.day
}

///|
pub fn DateTime::add_days(self : DateTime, days : Int) -> DateTime {
  let (year, month, day) = civil_from_date_number(self.date_key() + days)
  DateTime::{
    year,
    month,
    day,
    hour: self.hour,
    minute: self.minute,
    second: self.second,
    is_date: self.is_date,
    is_utc: self.is_utc,
  }
}

///|
pub fn DateTime::add_seconds(self : DateTime, seconds : Int) -> DateTime {
  let total = self.hour * 3600 + self.minute * 60 + self.second + seconds
  let mut day_delta = total / 86400
  let mut second_of_day = total % 86400
  if second_of_day < 0 {
    second_of_day = second_of_day + 86400
    day_delta = day_delta - 1
  }
  let shifted = self.add_days(day_delta)
  DateTime::{
    year: shifted.year,
    month: shifted.month,
    day: shifted.day,
    hour: second_of_day / 3600,
    minute: second_of_day % 3600 / 60,
    second: second_of_day % 60,
    is_date: self.is_date,
    is_utc: self.is_utc,
  }
}

///|
pub fn DateTime::seconds_until(self : DateTime, other : DateTime) -> Int {
  let day_part = self.days_until(other) * 86400
  let self_time = self.hour * 3600 + self.minute * 60 + self.second
  let other_time = other.hour * 3600 + other.minute * 60 + other.second
  day_part + other_time - self_time
}

///|
pub fn DateTime::add_months(self : DateTime, months : Int) -> DateTime {
  let zero_based = self.year * 12 + (self.month - 1) + months
  let new_year = zero_based / 12
  let new_month = zero_based % 12 + 1
  let max_day = days_in_month(new_year, new_month)
  let new_day = if self.day > max_day { max_day } else { self.day }
  DateTime::{
    year: new_year,
    month: new_month,
    day: new_day,
    hour: self.hour,
    minute: self.minute,
    second: self.second,
    is_date: self.is_date,
    is_utc: self.is_utc,
  }
}

///|
pub fn DateTime::add_years(self : DateTime, years : Int) -> DateTime {
  let new_year = self.year + years
  let max_day = days_in_month(new_year, self.month)
  let new_day = if self.day > max_day { max_day } else { self.day }
  DateTime::{
    year: new_year,
    month: self.month,
    day: new_day,
    hour: self.hour,
    minute: self.minute,
    second: self.second,
    is_date: self.is_date,
    is_utc: self.is_utc,
  }
}

///|
pub fn DateTime::days_until(self : DateTime, other : DateTime) -> Int {
  other.date_key() - self.date_key()
}

///|
pub fn DateTime::months_until(self : DateTime, other : DateTime) -> Int {
  (other.year - self.year) * 12 + (other.month - self.month)
}

///|
pub fn DateTime::years_until(self : DateTime, other : DateTime) -> Int {
  other.year - self.year
}

///|
pub fn DateTime::weekday(self : DateTime) -> Weekday {
  match positive_mod(self.date_key() - 1, 7) {
    0 => MO
    1 => TU
    2 => WE
    3 => TH
    4 => FR
    5 => SA
    _ => SU
  }
}

///|
pub fn DateTime::format(self : DateTime) -> String {
  let date = "\{pad4(self.year)}-\{pad2(self.month)}-\{pad2(self.day)}"
  if self.is_date {
    date
  } else {
    let suffix = if self.is_utc { "Z" } else { "" }
    date +
    "T\{pad2(self.hour)}:\{pad2(self.minute)}:\{pad2(self.second)}\{suffix}"
  }
}

///|
pub fn DateTime::to_ics_value(self : DateTime) -> String {
  let date = "\{pad4(self.year)}\{pad2(self.month)}\{pad2(self.day)}"
  if self.is_date {
    date
  } else {
    let suffix = if self.is_utc { "Z" } else { "" }
    date +
    "T\{pad2(self.hour)}\{pad2(self.minute)}\{pad2(self.second)}\{suffix}"
  }
}

///|
pub impl Show for DateTime with fn to_string(self) {
  self.format()
}

///|
fn date_number(year : Int, month : Int, day : Int) -> Int {
  let mut total = (year - 1) * 365
  total = total + (year - 1) / 4
  total = total - (year - 1) / 100
  total = total + (year - 1) / 400
  for m in 1..<month {
    total = total + days_in_month(year, m)
  }
  total + day
}

///|
fn civil_from_date_number(number : Int) -> (Int, Int, Int) {
  let mut year = number / 366 + 1
  while date_number(year + 1, 1, 1) <= number {
    year = year + 1
  }
  while date_number(year, 1, 1) > number {
    year = year - 1
  }
  let mut month = 1
  while month < 12 && date_number(year, month + 1, 1) <= number {
    month = month + 1
  }
  let day = number - date_number(year, month, 1) + 1
  (year, month, day)
}

///|
fn positive_mod(value : Int, divisor : Int) -> Int {
  let raw = value % divisor
  if raw < 0 {
    raw + divisor
  } else {
    raw
  }
}

///|
fn pad2(n : Int) -> String {
  if n < 10 {
    "0\{n}"
  } else {
    "\{n}"
  }
}

///|
fn pad4(n : Int) -> String {
  if n < 10 {
    "000\{n}"
  } else if n < 100 {
    "00\{n}"
  } else if n < 1000 {
    "0\{n}"
  } else {
    "\{n}"
  }
}

///|
fn parse_digits(input : String, start : Int, len : Int) -> Int? {
  if start < 0 || len <= 0 || start + len > input.length() {
    return None
  }
  let mut value = 0
  for i in start..<(start + len) {
    match input.get_char(i) {
      Some(c) if c >= '0' && c <= '9' =>
        value = value * 10 + (c.to_int() - '0'.to_int())
      _ => return None
    }
  }
  Some(value)
}

///|
pub fn parse_datetime(
  value : String,
  is_date_hint? : Bool = false,
) -> Result[DateTime, MoonCalError] {
  let raw = value.trim().to_owned()
  if raw.length() == 8 || is_date_hint {
    match
      (
        parse_digits(raw, 0, 4),
        parse_digits(raw, 4, 2),
        parse_digits(raw, 6, 2),
      ) {
      (Some(year), Some(month), Some(day)) if raw.length() == 8 &&
        is_valid_date(year, month, day) =>
        Ok(DateTime(year, month, day, is_date=true))
      _ => Err(InvalidDateTime(value=raw))
    }
  } else {
    let has_utc = raw.has_suffix("Z")
    let core = if has_utc { raw[:raw.length() - 1].to_owned() } else { raw }
    if core.length() != 15 || !core[8:9].to_owned().equal_ignore_ascii_case("T") {
      return Err(InvalidDateTime(value~))
    }
    match
      (
        parse_digits(core, 0, 4),
        parse_digits(core, 4, 2),
        parse_digits(core, 6, 2),
        parse_digits(core, 9, 2),
        parse_digits(core, 11, 2),
        parse_digits(core, 13, 2),
      ) {
      (
        Some(year),
        Some(month),
        Some(day),
        Some(hour),
        Some(minute),
        Some(second),
      ) if is_valid_date(year, month, day) &&
        hour >= 0 &&
        hour <= 23 &&
        minute >= 0 &&
        minute <= 59 &&
        second >= 0 &&
        second <= 60 =>
        Ok(
          DateTime(
            year,
            month,
            day,
            hour~,
            minute~,
            second~,
            is_date=false,
            is_utc=has_utc,
          ),
        )
      _ => Err(InvalidDateTime(value~))
    }
  }
}
