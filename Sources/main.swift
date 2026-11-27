import Foundation

func usage() -> Never {
    FileHandle.standardError.write(Data("""
    usage:
      channel-check channels channels.csv
      channel-check flags answers.csv
      channel-check cost --fee N [--tools N] [--hours N --rate N]
      channel-check questions

    """.utf8))
    exit(2)
}

func fail(_ msg: String) -> Never {
    FileHandle.standardError.write(Data("error: \(msg)\n".utf8))
    exit(2)
}

func money(_ v: Double) -> String { String(format: "$%.0f", v) }

func readFile(_ path: String) -> String {
    guard let s = try? String(contentsOfFile: path, encoding: .utf8) else { fail("cannot read \(path)") }
    return s
}

let args = Array(CommandLine.arguments.dropFirst())
guard let cmd = args.first else { usage() }

switch cmd {
case "channels":
    guard args.count >= 2 else { usage() }
    do {
        let ranked = rank(try parseChannels(readFile(args[1])))
        func row(_ c: [String]) -> String {
            pad(c[0], 22) + " " + pad(c[1], 9, right: true) + " " + pad(c[2], 9, right: true) + " " + pad(c[3], 13, right: true) + " " + pad(c[4], 8, right: true) + "  " + c[5]
        }
        print(row(["channel", "spend", "value", "cost/meeting", "return", "verdict"]))
        for r in ranked {
            let cpm = r.costPerMeeting.map(money) ?? "-"
            let rpd = r.returnPerDollar.map { String(format: "%.2fx", $0) } ?? "-"
            print(row([r.name, money(r.spend), money(r.valueReturned), cpm, rpd, r.verdict]))
        }
        print("a channel that returns less value than it costs should shrink")
    } catch { fail("\(error)") }
case "flags":
    guard args.count >= 2 else { usage() }
    do {
        let hit = try parseFlags(readFile(args[1]))
        for f in redFlags where hit.contains(f.key) {
            print("RED FLAG \(f.label): ask: \(f.ask)")
        }
        if hit.isEmpty { print("no red flags") }
        exit(hit.isEmpty ? 0 : 1)
    } catch { fail("\(error)") }
case "cost":
    var o: [String: Double] = [:]
    var i = 1
    while i < args.count {
        guard args[i].hasPrefix("--"), i + 1 < args.count, let v = Double(args[i + 1]), v >= 0 else { fail("options need a number of at least 0") }
        o[String(args[i].dropFirst(2))] = v
        i += 2
    }
    guard let fee = o["fee"] else { usage() }
    let total = realMonthlyCost(fee: fee, tools: o["tools"] ?? 0, teamHours: o["hours"] ?? 0, hourlyRate: o["rate"] ?? 0)
    print("real monthly cost: \(money(total))")
    if o["tools"] == nil { print("note: --tools not given; ask what the tools cost on top") }
case "questions":
    for (i, q) in salesCallQuestions.enumerated() { print("\(i + 1). \(q)") }
default:
    usage()
}
