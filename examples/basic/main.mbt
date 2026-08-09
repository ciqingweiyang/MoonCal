///|
fn main {
  match @mooncal.parse(@mooncal.sample_ics) {
    Ok(calendar) => {
      let from = @mooncal.DateTime(2026, 8, 1)
      let until = @mooncal.DateTime(2026, 8, 31, hour=23, minute=59, second=59)
      match @mooncal.occurrences_between(calendar, from, until, limit=32) {
        Ok(items) => {
          println("expanded occurrences: \{items.length()}")
          println(@mooncal.occurrences_to_json(items))
        }
        Err(err) => println("expand error: \{@mooncal.error_to_text(err)}")
      }
    }
    Err(err) => println("parse error: \{@mooncal.error_to_text(err)}")
  }
}
