///|
pub fn Duration::Duration(
  negative? : Bool = false,
  weeks? : Int = 0,
  days? : Int = 0,
  hours? : Int = 0,
  minutes? : Int = 0,
  seconds? : Int = 0,
) -> Duration {
  Duration::{ negative, weeks, days, hours, minutes, seconds }
}

///|
pub fn Duration::is_zero(self : Duration) -> Bool {
  self.weeks == 0 &&
  self.days == 0 &&
  self.hours == 0 &&
  self.minutes == 0 &&
  self.seconds == 0
}

///|
pub fn Duration::total_seconds(self : Duration) -> Int {
  let value = self.weeks * 7 * 86400 +
    self.days * 86400 +
    self.hours * 3600 +
    self.minutes * 60 +
    self.seconds
  if self.negative {
    0 - value
  } else {
    value
  }
}

///|
pub fn Duration::apply(self : Duration, start : DateTime) -> DateTime {
  start.add_seconds(self.total_seconds())
}

///|
pub fn Duration::format(self : Duration) -> String {
  let b = StringBuilder()
  if self.negative {
    b.write_string("-")
  }
  b.write_string("P")
  if self.weeks != 0 {
    b.write_string("\{self.weeks}W")
  } else {
    if self.days != 0 {
      b.write_string("\{self.days}D")
    }
    if self.hours != 0 || self.minutes != 0 || self.seconds != 0 {
      b.write_string("T")
      if self.hours != 0 {
        b.write_string("\{self.hours}H")
      }
      if self.minutes != 0 {
        b.write_string("\{self.minutes}M")
      }
      if self.seconds != 0 {
        b.write_string("\{self.seconds}S")
      }
    }
    if self.days == 0 &&
      self.hours == 0 &&
      self.minutes == 0 &&
      self.seconds == 0 {
      b.write_string("T0S")
    }
  }
  b.to_string()
}

///|
pub impl Show for Duration with fn to_string(self) {
  self.format()
}

///|
pub fn parse_duration(input : String) -> Result[Duration, MoonCalError] {
  let raw = input.trim().to_owned()
  if raw.is_empty() {
    return Err(
      InvalidProperty(line=0, name="DURATION", message="duration is empty"),
    )
  }
  let negative = raw.has_prefix("-")
  let positive = if negative {
    raw[1:].to_owned()
  } else if raw.has_prefix("+") {
    raw[1:].to_owned()
  } else {
    raw
  }
  if !positive.has_prefix("P") || positive.length() < 2 {
    return Err(
      InvalidProperty(
        line=0,
        name="DURATION",
        message="duration must start with P",
      ),
    )
  }
  let mut weeks = 0
  let mut days = 0
  let mut hours = 0
  let mut minutes = 0
  let mut seconds = 0
  let mut in_time = false
  let mut number = ""
  let mut saw_component = false
  for i in 1..<positive.length() {
    match positive.get_char(i) {
      Some('T') => {
        if in_time || !number.is_empty() {
          return Err(
            InvalidProperty(line=0, name="DURATION", message="bad T marker"),
          )
        }
        in_time = true
      }
      Some(c) if c >= '0' && c <= '9' => number = number + c.to_string()
      Some('W') => {
        if in_time || saw_component || number.is_empty() {
          return Err(
            InvalidProperty(
              line=0,
              name="DURATION",
              message="W must be the only date component",
            ),
          )
        }
        weeks = match parse_positive_int(number) {
          Some(n) => n
          None =>
            return Err(
              InvalidProperty(line=0, name="DURATION", message="bad week value"),
            )
        }
        number = ""
        saw_component = true
      }
      Some('D') => {
        if in_time || number.is_empty() {
          return Err(
            InvalidProperty(
              line=0,
              name="DURATION",
              message="bad day component",
            ),
          )
        }
        days = match parse_positive_int(number) {
          Some(n) => n
          None =>
            return Err(
              InvalidProperty(line=0, name="DURATION", message="bad day value"),
            )
        }
        number = ""
        saw_component = true
      }
      Some('H') => {
        if !in_time || number.is_empty() {
          return Err(
            InvalidProperty(
              line=0,
              name="DURATION",
              message="bad hour component",
            ),
          )
        }
        hours = match parse_positive_int(number) {
          Some(n) => n
          None =>
            return Err(
              InvalidProperty(line=0, name="DURATION", message="bad hour value"),
            )
        }
        number = ""
        saw_component = true
      }
      Some('M') => {
        if !in_time || number.is_empty() {
          return Err(
            InvalidProperty(
              line=0,
              name="DURATION",
              message="bad minute component",
            ),
          )
        }
        minutes = match parse_positive_int(number) {
          Some(n) => n
          None =>
            return Err(
              InvalidProperty(
                line=0,
                name="DURATION",
                message="bad minute value",
              ),
            )
        }
        number = ""
        saw_component = true
      }
      Some('S') => {
        if !in_time || number.is_empty() {
          return Err(
            InvalidProperty(
              line=0,
              name="DURATION",
              message="bad second component",
            ),
          )
        }
        seconds = match parse_positive_int(number) {
          Some(n) => n
          None =>
            return Err(
              InvalidProperty(
                line=0,
                name="DURATION",
                message="bad second value",
              ),
            )
        }
        number = ""
        saw_component = true
      }
      _ =>
        return Err(
          InvalidProperty(
            line=0,
            name="DURATION",
            message="unexpected character",
          ),
        )
    }
  }
  if !number.is_empty() || !saw_component {
    return Err(
      InvalidProperty(
        line=0,
        name="DURATION",
        message="duration has trailing number or no component",
      ),
    )
  }
  let duration = Duration(negative~, weeks~, days~, hours~, minutes~, seconds~)
  Ok(duration)
}
