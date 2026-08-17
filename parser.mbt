///|
pub fn unfold_lines(
  input : String,
) -> Result[Array[(Int, String)], MoonCalError] {
  let normalized = input
    .replace_all(old="\r\n", new="\n")
    .replace_all(old="\r", new="\n")
  let physical = normalized.split("\n").to_array()
  let logical : Array[(Int, String)] = []
  let mut current = ""
  let mut current_line = 1
  let mut has_current = false
  for i, line_view in physical {
    let line = line_view.to_owned()
    if line.is_empty() && i == physical.length() - 1 {
      continue
    }
    if line.has_prefix(" ") || line.has_prefix("\t") {
      if !has_current {
        return Err(
          InvalidLine(
            line=i + 1,
            message="folded continuation without a previous line",
          ),
        )
      }
      current = current + line[1:].to_owned()
    } else {
      if has_current {
        logical.push((current_line, current))
      }
      current = line
      current_line = i + 1
      has_current = true
    }
  }
  if has_current && !current.is_empty() {
    logical.push((current_line, current))
  }
  Ok(logical)
}

///|
pub fn parse_property_line(
  line : String,
  line_number : Int,
) -> Result[IcsProperty, MoonCalError] {
  match line.split_once(":") {
    Some((head_view, value_view)) => {
      let head = head_view.to_owned()
      let parts = head.split(";").to_array()
      if parts.length() == 0 {
        return Err(
          InvalidLine(line=line_number, message="property name is empty"),
        )
      }
      let name = parts[0].to_owned().trim().to_owned().to_upper()
      if name.is_empty() {
        return Err(
          InvalidLine(line=line_number, message="property name is empty"),
        )
      }
      let params : Map[String, String] = Map([])
      for i in 1..<parts.length() {
        let raw = parts[i].to_owned()
        match raw.split_once("=") {
          Some((key_view, val_view)) => {
            let key = key_view.to_owned().trim().to_owned().to_upper()
            let val = unquote_param_value(val_view.to_owned().trim().to_owned())
            if key.is_empty() {
              return Err(
                InvalidProperty(
                  line=line_number,
                  name~,
                  message="parameter key is empty",
                ),
              )
            }
            params.set(key, val)
          }
          None =>
            return Err(
              InvalidProperty(
                line=line_number,
                name~,
                message="parameter must use KEY=VALUE",
              ),
            )
        }
      }
      Ok(IcsProperty::{
        name,
        params,
        value: value_view.to_owned(),
        line: line_number,
      })
    }
    None =>
      Err(
        InvalidLine(line=line_number, message="property line must contain ':'"),
      )
  }
}

///|
pub fn parse_properties(
  input : String,
) -> Result[Array[IcsProperty], MoonCalError] {
  match unfold_lines(input) {
    Ok(lines) => {
      let props : Array[IcsProperty] = []
      for pair in lines {
        let (line_number, line) = pair
        match parse_property_line(line, line_number) {
          Ok(prop) => props.push(prop)
          Err(err) => return Err(err)
        }
      }
      Ok(props)
    }
    Err(err) => Err(err)
  }
}

///|
pub fn parse_calendar(input : String) -> Result[Calendar, MoonCalError] {
  let props = match parse_properties(input) {
    Ok(props) => props
    Err(err) => return Err(err)
  }
  let events : Array[Event] = []
  let tasks : Array[Task] = []
  let freebusy : Array[FreeBusy] = []
  let top_props : Array[IcsProperty] = []
  let mut current_event : Array[IcsProperty] = []
  let mut current_task : Array[IcsProperty] = []
  let mut current_freebusy : Array[IcsProperty] = []
  let mut in_calendar = false
  let mut closed_calendar = false
  let mut in_event = false
  let mut in_task = false
  let mut in_freebusy = false
  let mut version : String? = None
  let mut prodid : String? = None
  for prop in props {
    if prop.name == "BEGIN" && prop.value.to_upper() == "VCALENDAR" {
      if in_calendar {
        return Err(InvalidCalendar(message="nested VCALENDAR is not supported"))
      }
      in_calendar = true
      continue
    }
    if prop.name == "END" && prop.value.to_upper() == "VCALENDAR" {
      if in_event {
        return Err(
          InvalidCalendar(message="VEVENT was not closed before END:VCALENDAR"),
        )
      }
      if in_task {
        return Err(
          InvalidCalendar(message="VTODO was not closed before END:VCALENDAR"),
        )
      }
      if in_freebusy {
        return Err(
          InvalidCalendar(
            message="VFREEBUSY was not closed before END:VCALENDAR",
          ),
        )
      }
      if !in_calendar {
        return Err(
          InvalidCalendar(message="END:VCALENDAR without BEGIN:VCALENDAR"),
        )
      }
      closed_calendar = true
      in_calendar = false
      continue
    }
    if !in_calendar {
      if !closed_calendar {
        return Err(
          InvalidCalendar(message="properties must be inside VCALENDAR"),
        )
      }
      return Err(
        InvalidCalendar(
          message="trailing properties after END:VCALENDAR are not supported",
        ),
      )
    }
    if prop.name == "BEGIN" && prop.value.to_upper() == "VEVENT" {
      if in_event || in_task || in_freebusy {
        return Err(
          InvalidCalendar(message="nested calendar component is not supported"),
        )
      }
      in_event = true
      current_event = []
      continue
    }
    if prop.name == "END" && prop.value.to_upper() == "VEVENT" {
      if !in_event {
        return Err(InvalidCalendar(message="END:VEVENT without BEGIN:VEVENT"))
      }
      match parse_event(current_event) {
        Ok(event) => events.push(event)
        Err(err) => return Err(err)
      }
      current_event = []
      in_event = false
      continue
    }
    if prop.name == "BEGIN" && prop.value.to_upper() == "VTODO" {
      if in_event || in_task || in_freebusy {
        return Err(
          InvalidCalendar(message="nested calendar component is not supported"),
        )
      }
      in_task = true
      current_task = []
      continue
    }
    if prop.name == "END" && prop.value.to_upper() == "VTODO" {
      if !in_task {
        return Err(InvalidCalendar(message="END:VTODO without BEGIN:VTODO"))
      }
      match parse_task(current_task) {
        Ok(task) => tasks.push(task)
        Err(err) => return Err(err)
      }
      current_task = []
      in_task = false
      continue
    }
    if prop.name == "BEGIN" && prop.value.to_upper() == "VFREEBUSY" {
      if in_event || in_task || in_freebusy {
        return Err(
          InvalidCalendar(message="nested calendar component is not supported"),
        )
      }
      in_freebusy = true
      current_freebusy = []
      continue
    }
    if prop.name == "END" && prop.value.to_upper() == "VFREEBUSY" {
      if !in_freebusy {
        return Err(
          InvalidCalendar(message="END:VFREEBUSY without BEGIN:VFREEBUSY"),
        )
      }
      match parse_freebusy(current_freebusy) {
        Ok(item) => freebusy.push(item)
        Err(err) => return Err(err)
      }
      current_freebusy = []
      in_freebusy = false
      continue
    }
    if in_event {
      current_event.push(prop)
    } else if in_task {
      current_task.push(prop)
    } else if in_freebusy {
      current_freebusy.push(prop)
    } else {
      top_props.push(prop)
      if prop.name == "VERSION" {
        version = Some(prop.value)
      } else if prop.name == "PRODID" {
        prodid = Some(prop.value)
      }
    }
  }
  if in_event {
    return Err(InvalidCalendar(message="VEVENT missing END:VEVENT"))
  }
  if in_task {
    return Err(InvalidCalendar(message="VTODO missing END:VTODO"))
  }
  if in_freebusy {
    return Err(InvalidCalendar(message="VFREEBUSY missing END:VFREEBUSY"))
  }
  if in_calendar || !closed_calendar {
    return Err(InvalidCalendar(message="VCALENDAR missing END:VCALENDAR"))
  }
  Ok(Calendar::{
    version,
    prodid,
    events,
    tasks,
    freebusy,
    properties: top_props,
  })
}

///|
pub fn parse_event(props : Array[IcsProperty]) -> Result[Event, MoonCalError] {
  let mut uid : String? = None
  let mut start : DateTime? = None
  let mut end : DateTime? = None
  let mut summary = ""
  let mut description : String? = None
  let mut location : String? = None
  let mut status : String? = None
  let mut url : String? = None
  let categories : Array[String] = []
  let mut created : DateTime? = None
  let mut last_modified : DateTime? = None
  let mut sequence : Int? = None
  let mut rrule : RRule? = None
  let mut duration : Duration? = None
  let rdate : Array[DateTime] = []
  let exdate : Array[DateTime] = []
  for prop in props {
    if prop.name == "UID" {
      uid = Some(prop.value)
    } else if prop.name == "DTSTART" {
      match parse_property_datetime(prop) {
        Ok(dt) => start = Some(dt)
        Err(err) => return Err(err)
      }
    } else if prop.name == "DTEND" {
      match parse_property_datetime(prop) {
        Ok(dt) => end = Some(dt)
        Err(err) => return Err(err)
      }
    } else if prop.name == "SUMMARY" {
      summary = unescape_text(prop.value)
    } else if prop.name == "DESCRIPTION" {
      description = Some(unescape_text(prop.value))
    } else if prop.name == "LOCATION" {
      location = Some(unescape_text(prop.value))
    } else if prop.name == "STATUS" {
      status = Some(prop.value.to_upper())
    } else if prop.name == "URL" {
      url = Some(prop.value)
    } else if prop.name == "CATEGORIES" {
      categories.append(parse_text_list(prop.value))
    } else if prop.name == "CREATED" {
      match parse_property_datetime(prop) {
        Ok(dt) => created = Some(dt)
        Err(err) => return Err(err)
      }
    } else if prop.name == "LAST-MODIFIED" {
      match parse_property_datetime(prop) {
        Ok(dt) => last_modified = Some(dt)
        Err(err) => return Err(err)
      }
    } else if prop.name == "SEQUENCE" {
      match parse_positive_int(prop.value) {
        Some(n) => sequence = Some(n)
        None =>
          return Err(
            InvalidProperty(
              line=prop.line,
              name=prop.name,
              message="SEQUENCE must be a non-negative integer",
            ),
          )
      }
    } else if prop.name == "RRULE" {
      match parse_rrule(prop.value) {
        Ok(rule) => rrule = Some(rule)
        Err(err) => return Err(err)
      }
    } else if prop.name == "DURATION" {
      match parse_duration(prop.value) {
        Ok(value) => duration = Some(value)
        Err(_) =>
          return Err(
            InvalidProperty(
              line=prop.line,
              name=prop.name,
              message="invalid DURATION value",
            ),
          )
      }
    } else if prop.name == "RDATE" {
      match parse_datetime_list(prop) {
        Ok(values) => rdate.append(values)
        Err(err) => return Err(err)
      }
    } else if prop.name == "EXDATE" {
      match parse_datetime_list(prop) {
        Ok(values) => exdate.append(values)
        Err(err) => return Err(err)
      }
    }
  }
  let uid = match uid {
    Some(value) if !value.trim().is_empty() => value
    _ => return Err(MissingEventField(field="UID"))
  }
  let start = match start {
    Some(value) => value
    None => return Err(MissingEventField(field="DTSTART"))
  }
  if end is Some(value) {
    if value.before(start) {
      return Err(
        InvalidProperty(
          line=0,
          name="DTEND",
          message="DTEND must not be before DTSTART",
        ),
      )
    }
  }
  if end is Some(_) && duration is Some(_) {
    return Err(
      InvalidProperty(
        line=0,
        name="DURATION",
        message="VEVENT must not contain both DTEND and DURATION",
      ),
    )
  }
  Ok(Event::{
    uid,
    start,
    end,
    summary,
    description,
    location,
    status,
    url,
    categories,
    created,
    last_modified,
    sequence,
    rrule,
    duration,
    rdate,
    exdate,
    raw: props,
  })
}

///|
pub fn parse_task(props : Array[IcsProperty]) -> Result[Task, MoonCalError] {
  let mut uid : String? = None
  let mut start : DateTime? = None
  let mut due : DateTime? = None
  let mut completed : DateTime? = None
  let mut created : DateTime? = None
  let mut last_modified : DateTime? = None
  let mut summary = ""
  let mut description : String? = None
  let mut status : String? = None
  let mut priority : Int? = None
  let mut percent_complete : Int? = None
  let categories : Array[String] = []
  let mut url : String? = None
  let related_to : Array[String] = []
  for prop in props {
    if prop.name == "UID" {
      uid = Some(prop.value)
    } else if prop.name == "DTSTART" {
      match parse_property_datetime(prop) {
        Ok(dt) => start = Some(dt)
        Err(err) => return Err(err)
      }
    } else if prop.name == "DUE" {
      match parse_property_datetime(prop) {
        Ok(dt) => due = Some(dt)
        Err(err) => return Err(err)
      }
    } else if prop.name == "COMPLETED" {
      match parse_property_datetime(prop) {
        Ok(dt) => completed = Some(dt)
        Err(err) => return Err(err)
      }
    } else if prop.name == "CREATED" {
      match parse_property_datetime(prop) {
        Ok(dt) => created = Some(dt)
        Err(err) => return Err(err)
      }
    } else if prop.name == "LAST-MODIFIED" {
      match parse_property_datetime(prop) {
        Ok(dt) => last_modified = Some(dt)
        Err(err) => return Err(err)
      }
    } else if prop.name == "SUMMARY" {
      summary = unescape_text(prop.value)
    } else if prop.name == "DESCRIPTION" {
      description = Some(unescape_text(prop.value))
    } else if prop.name == "STATUS" {
      status = Some(prop.value.to_upper())
    } else if prop.name == "PRIORITY" {
      match parse_positive_int(prop.value) {
        Some(n) => priority = Some(n)
        None =>
          return Err(
            InvalidProperty(
              line=prop.line,
              name=prop.name,
              message="PRIORITY must be a non-negative integer",
            ),
          )
      }
    } else if prop.name == "PERCENT-COMPLETE" {
      match parse_positive_int(prop.value) {
        Some(n) => percent_complete = Some(n)
        None =>
          return Err(
            InvalidProperty(
              line=prop.line,
              name=prop.name,
              message="PERCENT-COMPLETE must be a non-negative integer",
            ),
          )
      }
    } else if prop.name == "CATEGORIES" {
      categories.append(parse_text_list(prop.value))
    } else if prop.name == "URL" {
      url = Some(prop.value)
    } else if prop.name == "RELATED-TO" {
      let value = prop.value.trim().to_owned()
      if !value.is_empty() {
        related_to.push(value)
      }
    }
  }
  let uid = match uid {
    Some(value) if !value.trim().is_empty() => value
    _ => return Err(MissingTaskField(field="UID"))
  }
  if start is Some(begin) {
    if due is Some(finish) {
      if finish.before(begin) {
        return Err(
          InvalidProperty(
            line=0,
            name="DUE",
            message="DUE must not be before DTSTART",
          ),
        )
      }
    }
  }
  Ok(Task::{
    uid,
    start,
    due,
    completed,
    created,
    last_modified,
    summary,
    description,
    status,
    priority,
    percent_complete,
    categories,
    url,
    related_to,
    raw: props,
  })
}

///|
pub fn parse_freebusy(
  props : Array[IcsProperty],
) -> Result[FreeBusy, MoonCalError] {
  let mut uid : String? = None
  let mut start : DateTime? = None
  let mut end : DateTime? = None
  let mut dtstamp : DateTime? = None
  let mut organizer : String? = None
  let attendees : Array[String] = []
  let comments : Array[String] = []
  let mut url : String? = None
  let periods : Array[FreeBusyPeriod] = []
  for prop in props {
    if prop.name == "UID" {
      uid = Some(prop.value)
    } else if prop.name == "DTSTART" {
      match parse_property_datetime(prop) {
        Ok(dt) => start = Some(dt)
        Err(err) => return Err(err)
      }
    } else if prop.name == "DTEND" {
      match parse_property_datetime(prop) {
        Ok(dt) => end = Some(dt)
        Err(err) => return Err(err)
      }
    } else if prop.name == "DTSTAMP" {
      match parse_property_datetime(prop) {
        Ok(dt) => dtstamp = Some(dt)
        Err(err) => return Err(err)
      }
    } else if prop.name == "ORGANIZER" {
      organizer = Some(prop.value)
    } else if prop.name == "ATTENDEE" {
      let value = prop.value.trim().to_owned()
      if !value.is_empty() {
        attendees.push(value)
      }
    } else if prop.name == "COMMENT" {
      comments.push(unescape_text(prop.value))
    } else if prop.name == "URL" {
      url = Some(prop.value)
    } else if prop.name == "FREEBUSY" {
      match parse_freebusy_periods(prop) {
        Ok(values) => periods.append(values)
        Err(err) => return Err(err)
      }
    }
  }
  if start is Some(begin) {
    if end is Some(finish) {
      if finish.before(begin) {
        return Err(
          InvalidProperty(
            line=0,
            name="DTEND",
            message="VFREEBUSY DTEND must not be before DTSTART",
          ),
        )
      }
    }
  }
  Ok(FreeBusy::{
    uid,
    start,
    end,
    dtstamp,
    organizer,
    attendees,
    comments,
    url,
    periods,
    raw: props,
  })
}

///|
fn parse_text_list(value : String) -> Array[String] {
  let values : Array[String] = []
  for item in value.split(",").to_array() {
    let text = unescape_text(item.to_owned().trim().to_owned())
    if !text.is_empty() {
      values.push(text)
    }
  }
  values
}

///|
fn parse_freebusy_periods(
  prop : IcsProperty,
) -> Result[Array[FreeBusyPeriod], MoonCalError] {
  let busy_type = match Map::get_from_string(prop.params, "FBTYPE") {
    Some(value) => value.to_upper()
    None => "BUSY"
  }
  let values : Array[FreeBusyPeriod] = []
  for item_view in prop.value.split(",").to_array() {
    let item = item_view.to_owned().trim().to_owned()
    if item.is_empty() {
      return Err(
        InvalidProperty(
          line=prop.line,
          name=prop.name,
          message="FREEBUSY contains an empty period",
        ),
      )
    }
    match item.split_once("/") {
      Some((start_view, end_view)) => {
        let start_text = start_view.to_owned().trim().to_owned()
        let end_text = end_view.to_owned().trim().to_owned()
        let start = match parse_datetime(start_text) {
          Ok(dt) => dt
          Err(_) =>
            return Err(
              InvalidProperty(
                line=prop.line,
                name=prop.name,
                message="FREEBUSY period start must be DATE or DATE-TIME",
              ),
            )
        }
        let finish = if end_text.has_prefix("P") ||
          end_text.has_prefix("+P") ||
          end_text.has_prefix("-P") {
          match parse_duration(end_text) {
            Ok(duration) =>
              if duration.negative {
                return Err(
                  InvalidProperty(
                    line=prop.line,
                    name=prop.name,
                    message="FREEBUSY duration must not be negative",
                  ),
                )
              } else {
                duration.apply(start)
              }
            Err(_) =>
              return Err(
                InvalidProperty(
                  line=prop.line,
                  name=prop.name,
                  message="FREEBUSY period duration is invalid",
                ),
              )
          }
        } else {
          match parse_datetime(end_text) {
            Ok(dt) => dt
            Err(_) =>
              return Err(
                InvalidProperty(
                  line=prop.line,
                  name=prop.name,
                  message="FREEBUSY period end must be DATE, DATE-TIME, or DURATION",
                ),
              )
          }
        }
        if finish.before(start) {
          return Err(
            InvalidProperty(
              line=prop.line,
              name=prop.name,
              message="FREEBUSY period end must not be before start",
            ),
          )
        }
        values.push(FreeBusyPeriod::{ start, end: finish, busy_type })
      }
      None =>
        return Err(
          InvalidProperty(
            line=prop.line,
            name=prop.name,
            message="FREEBUSY period must use start/end or start/duration",
          ),
        )
    }
  }
  Ok(values)
}

///|
fn parse_property_datetime(
  prop : IcsProperty,
) -> Result[DateTime, MoonCalError] {
  let value_type = Map::get_from_string(prop.params, "VALUE")
  let is_date = match value_type {
    Some(kind) => kind.to_upper() == "DATE"
    None => false
  }
  match parse_datetime(prop.value, is_date_hint=is_date) {
    Ok(dt) => Ok(dt)
    Err(_) =>
      Err(
        InvalidProperty(
          line=prop.line,
          name=prop.name,
          message="invalid DATE or DATE-TIME value",
        ),
      )
  }
}

///|
fn parse_datetime_list(
  prop : IcsProperty,
) -> Result[Array[DateTime], MoonCalError] {
  let value_type = Map::get_from_string(prop.params, "VALUE")
  let is_date = match value_type {
    Some(kind) => kind.to_upper() == "DATE"
    None => false
  }
  let values : Array[DateTime] = []
  for item_view in prop.value.split(",").to_array() {
    let item = item_view.to_owned().trim().to_owned()
    match parse_datetime(item, is_date_hint=is_date) {
      Ok(dt) => values.push(dt)
      Err(_) =>
        return Err(
          InvalidProperty(
            line=prop.line,
            name=prop.name,
            message="invalid date item in comma-separated list",
          ),
        )
    }
  }
  Ok(values)
}

///|
fn unquote_param_value(value : String) -> String {
  if value.length() >= 2 && value.has_prefix("\"") && value.has_suffix("\"") {
    value[1:value.length() - 1].to_owned()
  } else {
    value
  }
}

///|
pub fn unescape_text(value : String) -> String {
  value
  .replace_all(old="\\n", new="\n")
  .replace_all(old="\\N", new="\n")
  .replace_all(old="\\,", new=",")
  .replace_all(old="\\;", new=";")
  .replace_all(old="\\\\", new="\\")
}
