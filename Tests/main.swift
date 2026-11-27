import Foundation

var count = 0
func check(_ cond: Bool, _ msg: String) {
    count += 1
    if !cond { FileHandle.standardError.write(Data("FAIL: \(msg)\n".utf8)); exit(1) }
}
func throwsParse(_ f: () throws -> Any) -> Bool { do { _ = try f(); return false } catch { return true } }

// splitCSV
check(splitCSV("a,b,c") == ["a", "b", "c"], "plain split")
check(splitCSV("\"a,b\",c") == ["a,b", "c"], "quoted comma")

check(pad("ab", 4) == "ab  " && pad("ab", 4, right: true) == "  ab" && pad("abcdef", 3) == "abcdef", "pad")
check(evaluate(Channel(name: "q", spend: 70, meetings: 1, valuePerMeeting: 80)).spend == 70, "spend carried")

// evaluate
let good = evaluate(Channel(name: "x", spend: 1000, meetings: 4, valuePerMeeting: 500))
check(good.costPerMeeting == 250, "cost per meeting")
check(good.valueReturned == 2000, "value returned")
check(good.returnPerDollar == 2, "return per dollar")
check(good.verdict == "keep", "keep")
// the guide's own example: 100 of spend producing 50 of value should shrink
let weak = evaluate(Channel(name: "y", spend: 100, meetings: 1, valuePerMeeting: 50))
check(weak.verdict == "shrink", "spend 100 returning 50 shrinks")
let none = evaluate(Channel(name: "z", spend: 300, meetings: 0, valuePerMeeting: 500))
check(none.costPerMeeting == nil && none.verdict == "no meetings", "no meetings")
let free = evaluate(Channel(name: "w", spend: 0, meetings: 2, valuePerMeeting: 500))
check(free.returnPerDollar == nil && free.costPerMeeting == 0 && free.verdict == "keep", "zero spend")
let even = evaluate(Channel(name: "v", spend: 100, meetings: 1, valuePerMeeting: 100))
check(even.verdict == "keep", "break-even keeps")

// parseChannels and rank
let csv = "channel,spend,qualified_meetings,value_per_meeting\nChannel A (made-up),2000,5,1000\nChannel B (made-up),1500,0,1000\nChannel C (made-up),800,1,500\n"
let chans = try! parseChannels(csv)
check(chans.count == 3, "three channels")
let ranked = rank(chans)
check(ranked[0].name == "Channel A (made-up)", "cheapest meeting first")
check(ranked[1].name == "Channel C (made-up)", "second")
check(ranked[2].name == "Channel B (made-up)", "no meetings last")
check(ranked[1].verdict == "shrink", "C returns 500 on 800")
check(throwsParse { try parseChannels("a,1,2") }, "short row")
check(throwsParse { try parseChannels("a,x,2,3") }, "bad spend")
check(throwsParse { try parseChannels("a,1,2.5,3") }, "fractional meetings")
check(throwsParse { try parseChannels("a,-1,2,3") }, "negative spend")
check((try! parseChannels("channel,spend,qualified_meetings,value_per_meeting\n")).isEmpty, "header only")

// flags
check(redFlags.count == 6, "six red flags")
check(salesCallQuestions.count == 3, "three sales-call questions")
let hit = try! parseFlags("flag,answer\nnames,yes\ntemplate,no\nownership,YES\n")
check(hit == ["names", "ownership"], "flags parsed")
check(try! parseFlags("names,no").isEmpty, "none hit")
check(throwsParse { try parseFlags("bogus,yes") }, "unknown flag")
check(throwsParse { try parseFlags("names,maybe") }, "bad answer")
check(throwsParse { try parseFlags("names") }, "short flag row")

// cost
check(realMonthlyCost(fee: 5000, tools: 0, teamHours: 0, hourlyRate: 0) == 5000, "fee only")
check(realMonthlyCost(fee: 5000, tools: 800, teamHours: 10, hourlyRate: 60) == 6400, "fee tools and team time")

print("ok: \(count) checks passed")
