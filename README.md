# gtm-agency-channel-check

A small Swift command-line tool for the buyer-side checks in
[Best GTM Agency in 2026](https://www.onegtmlab.dev/blog/best-gtm-agency). It names no agency. It covers three things the
guide tells you to do before and after hiring a GTM agency: work out what a qualified meeting costs by channel, run the six
red-flag questions, and add up the real monthly cost of a quote. Swift 5.9 or later with Foundation, no packages.

## 1. What a qualified meeting costs, by channel

The guide says an agency that cannot tell you what a qualified meeting costs by channel cannot move budget to the channel that
works: if $100 of spend produces a lead worth $50 to you, that channel should shrink.

```bash
make channel-check
./channel-check channels examples/channels.csv
```

The CSV is `channel,spend,qualified_meetings,value_per_meeting`. For each channel the tool prints spend, the value the
meetings returned, the cost per qualified meeting and the return per dollar, then a verdict: `keep`, `shrink` (the channel
returned less than it cost) or `no meetings`. Channels are ordered by cost per meeting, with channels that produced no
meeting last. The value per meeting is your own number.

## 2. Six red flags

The guide lists six red flags when hiring a GTM agency: results without names, meeting counts with no definition, everything
happening inside the agency's accounts, one template for every client, no view on deliverability, and a senior person on the
sales call with nobody senior after it.

```
flag,answer
names,yes
definition,no
ownership,yes
```

```bash
./channel-check flags examples/flags.csv     # exit 1 if any flag is set
```

Flag keys are `names`, `definition`, `ownership`, `template`, `deliverability` and `seniority`. Answer `yes` when you saw
it. Every flag you set prints the question that tests it.

## 3. The real monthly cost

The number on the invoice is only part of the cost: the rest is tools and your own team's time.

```bash
./channel-check cost --fee 5000 --tools 800 --hours 10 --rate 60
./channel-check questions
```

`questions` prints the three questions to ask on every sales call: who does the work, who owns what gets built, and what the
tools cost on top.

## Test

```bash
make test
```

All names and figures in `examples/` and in this README are made up. MIT licensed.
