///|
fn main {
  let args = @env.args()
  let json = args.any(arg => arg == "--json")
  match @lib.analyze(@lib.sample_ics) {
    Ok(summary) =>
      if json {
        println(@lib.summary_to_json(summary))
      } else {
        println(@lib.summary_to_text(summary))
      }
    Err(err) => println("MoonCal error: \{@lib.error_to_text(err)}")
  }
}
