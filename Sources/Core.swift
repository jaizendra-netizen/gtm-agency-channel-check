import Foundation

/// One channel's spend, qualified meetings and what a qualified meeting is worth to you.
struct Channel {
    let name: String
    let spend: Double
    let meetings: Int
    let valuePerMeeting: Double
}

struct ChannelResult {
    let name: String
    let spend: Double
    let costPerMeeting: Double?   // nil when the channel produced no qualified meeting
    let valueReturned: Double
    let returnPerDollar: Double?  // nil when nothing was spent
    let verdict: String           // "keep", "shrink" or "no meetings"
}

struct ParseError: Error, CustomStringConvertible {
    let description: String
}

/// The six red flags from the guide, each with the question that tests it.
let redFlags: [(key: String, label: String, ask: String)] = [
    ("names", "Results without names", "Which named client is behind each number, and what does it measure: meetings, qualified pipeline or closed-won revenue?"),
    ("definition", "Meeting counts with no definition", "What counted as a meeting, who was it with, and how many turned into pipeline?"),
    ("ownership", "Everything happens inside their accounts", "Do the lists, tables and domains belong to you, so you do not start from zero when you leave?"),
    ("template", "One template for every client", "Can I see two campaigns for two different clients side by side?"),
    ("deliverability", "No view on deliverability", "How are inboxes warmed and lists verified?"),
    ("seniority", "A senior person on the sales call and nobody senior after it", "Who will run my account day to day, and can I meet them before signing?"),
]

/// The three questions to ask on every sales call.
let salesCallQuestions = [
    "Who does the work?",
    "Who owns what gets built?",
    "What do the tools cost on top?",
]

/// Split one CSV line, honouring double quotes.
func splitCSV(_ line: String) -> [String] {
    var out: [String] = []
    var cur = ""
    var inQuotes = false
    for ch in line {
        if ch == "\"" { inQuotes.toggle() }
        else if ch == "," && !inQuotes { out.append(cur); cur = "" }
        else { cur.append(ch) }
    }
    out.append(cur)
    return out.map { $0.trimmingCharacters(in: .whitespaces) }
}

/// Parse "channel,spend,qualified_meetings,value_per_meeting".
func parseChannels(_ text: String) throws -> [Channel] {
    var rows: [Channel] = []
    let lines = text.components(separatedBy: .newlines)
    for (i, line) in lines.enumerated() {
        if line.trimmingCharacters(in: .whitespaces).isEmpty { continue }
        let f = splitCSV(line)
        if i == 0 && f[0].lowercased() == "channel" { continue }
        guard f.count == 4 else { throw ParseError(description: "row \(i + 1): expected channel,spend,qualified_meetings,value_per_meeting") }
        guard let spend = Double(f[1]), spend >= 0 else { throw ParseError(description: "row \(i + 1): spend must be a number of at least 0") }
        guard let meetings = Int(f[2]), meetings >= 0 else { throw ParseError(description: "row \(i + 1): qualified_meetings must be a whole number of at least 0") }
        guard let value = Double(f[3]), value >= 0 else { throw ParseError(description: "row \(i + 1): value_per_meeting must be a number of at least 0") }
        rows.append(Channel(name: f[0], spend: spend, meetings: meetings, valuePerMeeting: value))
    }
    return rows
}

/// Cost per qualified meeting and a keep-or-shrink verdict: a channel whose spend returns less value than it costs should shrink.
func evaluate(_ c: Channel) -> ChannelResult {
    let returned = Double(c.meetings) * c.valuePerMeeting
    let cost: Double? = c.meetings > 0 ? c.spend / Double(c.meetings) : nil
    let perDollar: Double? = c.spend > 0 ? returned / c.spend : nil
    let verdict: String
    if c.meetings == 0 { verdict = "no meetings" }
    else if returned < c.spend { verdict = "shrink" }
    else { verdict = "keep" }
    return ChannelResult(name: c.name, spend: c.spend, costPerMeeting: cost, valueReturned: returned, returnPerDollar: perDollar, verdict: verdict)
}

/// Channels ordered by cost per qualified meeting, cheapest first; channels with no meetings go last.
func rank(_ channels: [Channel]) -> [ChannelResult] {
    let results = channels.map(evaluate)
    return results.sorted {
        switch ($0.costPerMeeting, $1.costPerMeeting) {
        case let (a?, b?): return a < b
        case (nil, _?): return false
        case (_?, nil): return true
        default: return false
        }
    }
}

/// Parse "flag,answer" rows, answer yes or no. Unknown flags and answers are errors.
func parseFlags(_ text: String) throws -> [String] {
    var hit: [String] = []
    let known = Set(redFlags.map { $0.key })
    for (i, line) in text.components(separatedBy: .newlines).enumerated() {
        if line.trimmingCharacters(in: .whitespaces).isEmpty { continue }
        let f = splitCSV(line)
        if i == 0 && f[0].lowercased() == "flag" { continue }
        guard f.count == 2 else { throw ParseError(description: "row \(i + 1): expected flag,answer") }
        let key = f[0].lowercased()
        guard known.contains(key) else { throw ParseError(description: "row \(i + 1): unknown flag \(f[0])") }
        switch f[1].lowercased() {
        case "yes": hit.append(key)
        case "no": break
        default: throw ParseError(description: "row \(i + 1): answer must be yes or no")
        }
    }
    return hit
}

/// The real number behind a quote: fee plus tools on top plus your own team's time.
func realMonthlyCost(fee: Double, tools: Double, teamHours: Double, hourlyRate: Double) -> Double {
    fee + tools + teamHours * hourlyRate
}

/// Left-pad or right-pad a string to a width (plain padding, no format specifiers, so output is the same on every platform).
func pad(_ s: String, _ width: Int, right: Bool = false) -> String {
    if s.count >= width { return s }
    let gap = String(repeating: " ", count: width - s.count)
    return right ? gap + s : s + gap
}
