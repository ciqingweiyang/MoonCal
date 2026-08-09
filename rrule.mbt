///|
pub fn RRule::RRule(
  freq : Frequency,
  interval? : Int = 1,
  count? : Int,
  until? : DateTime,
  byday? : Array[Weekday] = [],
  bymonthday? : Array[Int] = [],
  bymonth? : Array[Int] = [],
) -> RRule {
  RRule::{ freq, interval, count, until, byday, bymonthday, bymonth }
}

///|
pub fn frequency_to_string(freq : Frequency) -> String {
  match freq {
    Daily => "DAILY"
    Weekly => "WEEKLY"
    Monthly => "MONTHLY"
    Yearly => "YEARLY"
  }
}

///|
pub fn weekday_to_string(day : Weekday) -> String {
  match day {
    MO => "MO"
    TU => "TU"
    WE => "WE"
    TH => "TH"
    FR => "FR"
    SA => "SA"
    SU => "SU"
  }
}

///|
pub fn parse_weekday(value : String) -> Weekday? {
  match value.to_upper() {
    "MO" => Some(MO)
    "TU" => Some(TU)
    "WE" => Some(WE)
    "TH" => Some(TH)
    "FR" => Some(FR)
    "SA" => Some(SA)
    "SU" => Some(SU)
    _ => None
  }
}

///|
pub fn parse_frequency(value : String) -> Frequency? {
  match value.to_upper() {
    "DAILY" => Some(Daily)
    "WEEKLY" => Some(Weekly)
    "MONTHLY" => Some(Monthly)
    "YEARLY" => Some(Yearly)
    _ => None
  }
}

///|
pub fn parse_rrule(input : String) -> Result[RRule, MoonCalError] {
  let raw = input.trim().to_owned()
  if raw.is_empty() {
    return Err(InvalidRRule(value=raw, message="RRULE is empty"))
  }
  let mut freq : Frequency? = None
  let mut interval = 1
  let mut count : Int? = None
  let mut until : DateTime? = None
  let byday : Array[Weekday] = []
  let bymonthday : Array[Int] = []
  let bymonth : Array[Int] = []
  for part_view in raw.split(";").to_array() {
    let part = part_view.to_owned().trim().to_owned()
    if part.is_empty() {
      return Err(InvalidRRule(value=raw, message="empty RRULE part"))
    }
    match part.split_once("=") {
      Some((key_view, value_view)) => {
        let key = key_view.to_owned().trim().to_upper()
        let value = value_view.to_owned().trim().to_owned()
        if key == "FREQ" {
          match parse_frequency(value) {
            Some(parsed) => freq = Some(parsed)
            None =>
              return Err(
                InvalidRRule(value=raw, message="unsupported FREQ value"),
              )
          }
        } else if key == "INTERVAL" {
          match parse_positive_int(value) {
            Some(n) if n > 0 => interval = n
            _ =>
              return Err(
                InvalidRRule(value=raw, message="INTERVAL must be positive"),
              )
          }
        } else if key == "COUNT" {
          match parse_positive_int(value) {
            Some(n) if n > 0 => count = Some(n)
            _ =>
              return Err(
                InvalidRRule(value=raw, message="COUNT must be positive"),
              )
          }
        } else if key == "UNTIL" {
          match parse_datetime(value) {
            Ok(dt) => until = Some(dt)
            Err(_) =>
              return Err(
                InvalidRRule(
                  value=raw,
                  message="UNTIL must be DATE-TIME or DATE",
                ),
              )
          }
        } else if key == "BYDAY" {
          match parse_byday_list(value) {
            Ok(days) => byday.append(days)
            Err(err) => return Err(err)
          }
        } else if key == "BYMONTHDAY" {
          match
            parse_int_list(
              value,
              min=-31,
              max=31,
              context="BYMONTHDAY",
              source=raw,
            ) {
            Ok(values) => bymonthday.append(values)
            Err(err) => return Err(err)
          }
        } else if key == "BYMONTH" {
          match
            parse_int_list(value, min=1, max=12, context="BYMONTH", source=raw) {
            Ok(values) => bymonth.append(values)
            Err(err) => return Err(err)
          }
        } else {
          return Err(
            InvalidRRule(value=raw, message="unsupported RRULE part: \{key}"),
          )
        }
      }
      None =>
        return Err(
          InvalidRRule(value=raw, message="RRULE part must contain '='"),
        )
    }
  }
  match freq {
    Some(freq) =>
      Ok(RRule::{ freq, interval, count, until, byday, bymonthday, bymonth })
    None => Err(InvalidRRule(value=raw, message="FREQ is required"))
  }
}

///|
fn parse_byday_list(value : String) -> Result[Array[Weekday], MoonCalError] {
  let days : Array[Weekday] = []
  for item_view in value.split(",").to_array() {
    let item = item_view.to_owned().trim().to_owned()
    if item.is_empty() {
      return Err(InvalidRRule(value~, message="BYDAY contains an empty item"))
    }
    match parse_weekday(item) {
      Some(day) => days.push(day)
      None =>
        return Err(
          InvalidRRule(value~, message="BYDAY supports MO,TU,WE,TH,FR,SA,SU"),
        )
    }
  }
  Ok(days)
}

///|
fn parse_int_list(
  value : String,
  min~ : Int,
  max~ : Int,
  context~ : String,
  source~ : String,
) -> Result[Array[Int], MoonCalError] {
  let values : Array[Int] = []
  for item_view in value.split(",").to_array() {
    let item = item_view.to_owned().trim().to_owned()
    match parse_signed_int(item) {
      Some(n) if n >= min && n <= max && n != 0 => values.push(n)
      _ =>
        return Err(
          InvalidRRule(
            value=source,
            message="\{context} contains an out-of-range value",
          ),
        )
    }
  }
  Ok(values)
}

///|
fn parse_positive_int(value : String) -> Int? {
  let raw = value.trim().to_owned()
  if raw.is_empty() {
    return None
  }
  let mut result = 0
  for c in raw {
    if c < '0' || c > '9' {
      return None
    }
    result = result * 10 + (c.to_int() - '0'.to_int())
  }
  Some(result)
}

///|
fn parse_signed_int(value : String) -> Int? {
  let raw = value.trim().to_owned()
  if raw.is_empty() {
    return None
  }
  let negative = raw.has_prefix("-")
  let body = if negative { raw[1:].to_owned() } else { raw }
  match parse_positive_int(body) {
    Some(n) => if negative { Some(0 - n) } else { Some(n) }
    None => None
  }
}

///|
fn contains_weekday(days : Array[Weekday], day : Weekday) -> Bool {
  for item in days {
    if item == day {
      return true
    }
  }
  false
}

///|
fn contains_int(values : Array[Int], needle : Int) -> Bool {
  for value in values {
    if value == needle {
      return true
    }
  }
  false
}

///|
fn matches_month_day_filter(values : Array[Int], dt : DateTime) -> Bool {
  if values.is_empty() {
    return true
  }
  let dim = days_in_month(dt.year, dt.month)
  for value in values {
    if value > 0 && value == dt.day {
      return true
    }
    if value < 0 && dim + value + 1 == dt.day {
      return true
    }
  }
  false
}

///|
fn rrule_matches_start(
  rule : RRule,
  start : DateTime,
  candidate : DateTime,
) -> Bool {
  if candidate.before(start) {
    return false
  }
  if !rule.bymonth.is_empty() && !contains_int(rule.bymonth, candidate.month) {
    return false
  }
  match rule.freq {
    Daily => {
      let diff = start.days_until(candidate)
      diff >= 0 &&
      diff % rule.interval == 0 &&
      matches_month_day_filter(rule.bymonthday, candidate)
    }
    Weekly => {
      let diff = start.days_until(candidate)
      let week_ok = diff >= 0 && diff / 7 % rule.interval == 0
      let weekday_ok = if rule.byday.is_empty() {
        candidate.weekday() == start.weekday()
      } else {
        contains_weekday(rule.byday, candidate.weekday())
      }
      week_ok &&
      weekday_ok &&
      matches_month_day_filter(rule.bymonthday, candidate)
    }
    Monthly => {
      let diff = start.months_until(candidate)
      let day_ok = if rule.bymonthday.is_empty() {
        candidate.day == start.day
      } else {
        matches_month_day_filter(rule.bymonthday, candidate)
      }
      diff >= 0 && diff % rule.interval == 0 && day_ok
    }
    Yearly => {
      let diff = start.years_until(candidate)
      let month_ok = if rule.bymonth.is_empty() {
        candidate.month == start.month
      } else {
        contains_int(rule.bymonth, candidate.month)
      }
      let day_ok = if rule.bymonthday.is_empty() {
        candidate.day == start.day
      } else {
        matches_month_day_filter(rule.bymonthday, candidate)
      }
      diff >= 0 && diff % rule.interval == 0 && month_ok && day_ok
    }
  }
}
